#!/usr/bin/env python3
'''
Verify that a minidump carries no wallet secrets before it is uploaded to Sentry.

Three independent layers:

  Structural  The dump must contain no process memory and no register state.
              crashpad normally writes every thread's stack, the memory
              referenced by the crashing context, and whatever any module
              registers as a custom stream; on a wallet those regions hold
              mnemonics, PINs, passwords and private keys. It also writes each
              thread's CPU context, and registers -- the general-purpose ones
              and the XMM area alike -- hold pointers into and fragments of
              whatever the thread last touched, so with the memory gone they
              are the last place a secret can land.
              tools/patches/crashpad-omit-process-memory.patch and
              tools/patches/crashpad-omit-register-contexts.patch strip both at
              the source, and this asserts the patches were actually in the
              build: empty thread stacks, zero-length contexts, an empty memory
              list, and no stream beyond the ones crashpad and sentry write
              themselves. Absence is what makes the dump safe -- the content
              scan below is only a backstop.

  Paths       Module paths run through the user's home directory and so name the
              local account. tools/patches/crashpad-redact-module-paths.patch
              replaces the user component with a placeholder; this asserts no
              real account name survives anywhere in the file.

  Content     Scan every byte (ASCII and UTF-16LE) for wallet material:
              extended keys, addresses, WIFs, descriptors, SLIP-77 blinding
              keys and BIP39 phrases. Keys and addresses are checksum-validated
              so a hit is a real key, not a coincidence in a mangled C++ symbol.

Findings are FAIL (secret material, memory that could hold it, or a leaked
account name) or WARN (weaker signals). Exit status is 1 if anything failed,
0 otherwise; --strict also fails on warnings.

Example usage:

    tools/check-minidump.py ~/.local/share/Blockstream/Green/sentry/completed
'''
import argparse
import hashlib
import os
import re
import struct
import sys

MINIDUMP_SIGNATURE = 0x504D444D  # 'MDMP'

STREAM_THREAD_LIST = 3
STREAM_MEMORY_LIST = 5
STREAM_EXCEPTION = 6
STREAM_MEMORY64_LIST = 9

# What crashpad-redact-module-paths.patch substitutes for the user component of
# a home directory path.
PATH_PLACEHOLDER = '<user>'

# Streams crashpad and sentry write themselves, from crashpad's
# MinidumpStreamType and compat/non_win/dbghelp.h. Anything else in a dump came
# from CrashpadInfo::AddUserDataMinidumpStream, which copies arbitrary process
# memory in and which the patch removes.
KNOWN_STREAMS = {
    0: 'Unused',
    3: 'ThreadList',
    4: 'ModuleList',
    5: 'MemoryList',
    6: 'Exception',
    7: 'SystemInfo',
    9: 'Memory64List',
    12: 'HandleData',
    14: 'UnloadedModuleList',
    15: 'MiscInfo',
    16: 'MemoryInfoList',
    24: 'ThreadNames',
    0x43500001: 'CrashpadInfo',
    0x53790001: 'SentryStackTraces',
}

B58_ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
BECH32_CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l'
# Bitcoin and Liquid, mainnet and test networks.
BECH32_HRPS = ('bc', 'tb', 'bcrt', 'ex', 'ert', 'lq', 'tlq', 'el')


class Report:
    def __init__(self, path):
        self.path = path
        self.failures = []
        self.warnings = []
        self.notes = []

    def fail(self, check, detail):
        if (check, detail) not in self.failures:
            self.failures.append((check, detail))

    def warn(self, check, detail):
        if (check, detail) not in self.warnings:
            self.warnings.append((check, detail))

    def note(self, detail):
        self.notes.append(detail)


# -- checksum helpers -------------------------------------------------------

def b58check_decode(text):
    '''Return the payload of a base58check string, or None if the checksum is bad.'''
    number = 0
    for char in text:
        index = B58_ALPHABET.find(char)
        if index < 0:
            return None
        number = number * 58 + index
    raw = number.to_bytes((number.bit_length() + 7) // 8, 'big')
    # Leading '1's are leading zero bytes.
    raw = b'\x00' * (len(text) - len(text.lstrip('1'))) + raw
    if len(raw) < 5:
        return None
    payload, checksum = raw[:-4], raw[-4:]
    if hashlib.sha256(hashlib.sha256(payload).digest()).digest()[:4] != checksum:
        return None
    return payload


def bech32_verify(text):
    '''True if text is a valid bech32 or bech32m string.'''
    if text != text.lower() and text != text.upper():
        return False
    text = text.lower()
    pos = text.rfind('1')
    if pos < 1 or pos + 7 > len(text):
        return False
    hrp, data = text[:pos], text[pos + 1:]
    if any(char not in BECH32_CHARSET for char in data):
        return False
    values = [ord(char) >> 5 for char in hrp] + [0] + [ord(char) & 31 for char in hrp]
    values += [BECH32_CHARSET.index(char) for char in data]
    checksum = 1
    for value in values:
        top = checksum >> 25
        checksum = (checksum & 0x1ffffff) << 5 ^ value
        for i, generator in enumerate((0x3b6a57b2, 0x26508e6d, 0x1ea119fa,
                                       0x3d4233dd, 0x2a1462b3)):
            checksum ^= generator if (top >> i) & 1 else 0
    return checksum in (1, 0x2bc830a3)  # bech32, bech32m


# -- minidump parsing -------------------------------------------------------

class Minidump:
    def __init__(self, data):
        self.data = data
        signature, _, count, directory_rva = struct.unpack_from('<IIII', data, 0)
        if signature != MINIDUMP_SIGNATURE:
            raise ValueError('not a minidump (bad signature)')
        self.streams = {}
        for i in range(count):
            kind, size, rva = struct.unpack_from('<III', data, directory_rva + 12 * i)
            self.streams.setdefault(kind, []).append((size, rva))

    def stream(self, kind):
        entries = self.streams.get(kind)
        return entries[0] if entries else None

    def string(self, rva):
        length, = struct.unpack_from('<I', self.data, rva)
        return self.data[rva + 4:rva + 4 + length].decode('utf-16-le', 'replace')

    def threads(self):
        '''Yield (thread_id, stack_size, context_size) for every thread.

        MINIDUMP_THREAD is 48 bytes: the stack's memory descriptor holds its
        size at +32, and the context's location descriptor at +40.
        '''
        entry = self.stream(STREAM_THREAD_LIST)
        if not entry:
            return
        _, rva = entry
        count, = struct.unpack_from('<I', self.data, rva)
        for i in range(count):
            base = rva + 4 + 48 * i
            thread_id, = struct.unpack_from('<I', self.data, base)
            stack_size, = struct.unpack_from('<I', self.data, base + 32)
            context_size, = struct.unpack_from('<I', self.data, base + 40)
            yield thread_id, stack_size, context_size

    def exception_context(self):
        '''Size of the crashing thread's context, or None without an exception stream.

        MINIDUMP_EXCEPTION_STREAM is ThreadId (4), alignment (4) and a
        MINIDUMP_EXCEPTION (152), so the context descriptor starts at +160.
        '''
        entry = self.stream(STREAM_EXCEPTION)
        if not entry:
            return None
        _, rva = entry
        size, = struct.unpack_from('<I', self.data, rva + 160)
        return size

    def memory_ranges(self):
        '''Yield (start, size) for every region in MemoryList/Memory64List.'''
        entry = self.stream(STREAM_MEMORY_LIST)
        if entry:
            _, rva = entry
            count, = struct.unpack_from('<I', self.data, rva)
            for i in range(count):
                start, size = struct.unpack_from('<QI', self.data, rva + 4 + 16 * i)
                yield start, size
        entry = self.stream(STREAM_MEMORY64_LIST)
        if entry:
            _, rva = entry
            count, = struct.unpack_from('<Q', self.data, rva)
            for i in range(count):
                start, size = struct.unpack_from('<QQ', self.data, rva + 16 + 16 * i)
                yield start, size


def check_structure(dump, report):
    '''The dump must carry no process memory and no register state.

    This is the real guarantee.
    '''
    threads = list(dump.threads())

    captured = [(tid, size) for tid, size, _ in threads if size]
    if captured:
        total = sum(size for _, size in captured)
        report.fail('thread stacks', '%d of %d threads carry stack memory (%d bytes) -- '
                    'crashpad-omit-process-memory.patch was not applied'
                    % (len(captured), len(threads), total))
    else:
        report.note('%d threads, no stack memory' % len(threads))

    contexts = [size for _, _, size in threads if size]
    exception_context = dump.exception_context()
    if exception_context:
        contexts.append(exception_context)
    if contexts:
        report.fail('register contexts', '%d register context(s) present (%d bytes) -- '
                    'crashpad-omit-register-contexts.patch was not applied'
                    % (len(contexts), sum(contexts)))
    else:
        report.note('no register contexts')

    ranges = list(dump.memory_ranges())
    if ranges:
        total = sum(size for _, size in ranges)
        report.fail('memory regions', '%d region(s) totalling %d bytes of process memory'
                    % (len(ranges), total))
    else:
        report.note('no memory regions')

    # A custom stream carries whatever the registering module handed to
    # crashpad, so an unrecognised type is unreviewed process memory.
    unknown = [kind for kind in dump.streams if kind not in KNOWN_STREAMS]
    if unknown:
        for kind in sorted(unknown):
            size = dump.streams[kind][0][0]
            report.fail('custom stream', 'stream type 0x%08x (%d bytes) is not one '
                        'crashpad or sentry writes -- a module registered it via '
                        'AddUserDataMinidumpStream' % (kind, size))
    else:
        report.note('%d streams, all known: %s'
                    % (len(dump.streams),
                       ', '.join(KNOWN_STREAMS[kind] for kind in sorted(dump.streams))))


def extract_text(data):
    '''Every printable run in the file, as ASCII and as UTF-16LE.'''
    chunks = [match.group().decode('latin1')
              for match in re.finditer(rb'[\x20-\x7e]{4,}', data)]
    chunks += [match.group().decode('utf-16-le')
               for match in re.finditer(rb'(?:[\x20-\x7e]\x00){4,}', data)]
    return '\n'.join(chunks)


def check_content(text, report):
    # Extended keys, WIFs and legacy addresses: decode and verify the checksum,
    # so mangled C++ symbols cannot masquerade as keys.
    for match in re.finditer(r'[1-9A-HJ-NP-Za-km-z]{26,120}', text):
        payload = b58check_decode(match.group())
        if payload is None:
            continue
        if len(payload) == 78:
            private = payload[45:46] == b'\x00'
            report.fail('extended key', '%s key %s'
                        % ('PRIVATE' if private else 'public', match.group()))
        elif len(payload) in (33, 34) and payload[0] in (0x80, 0xef):
            report.fail('private key', 'WIF %s...' % match.group()[:12])
        elif len(payload) == 21:
            report.fail('address', match.group())

    for match in re.finditer(r'\b[a-zA-Z0-9]{1,10}1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{6,90}\b', text):
        candidate = match.group()
        hrp = candidate[:candidate.rfind('1')].lower()
        if hrp in BECH32_HRPS and bech32_verify(candidate):
            report.fail('address', candidate)

    # Liquid confidential addresses use blech32, whose checksum differs; the
    # prefix plus length is unambiguous enough on its own.
    for match in re.finditer(r'\b(?:lq1|tlq1|el1)[ac-hj-np-z02-9]{70,110}\b', text):
        report.fail('confidential address', match.group())

    for match in re.finditer(r'slip77\(([0-9a-f]{64})\)', text):
        report.fail('blinding key', 'SLIP-77 master blinding key %s' % match.group(1))

    for match in re.finditer(r'\b(?:ct|elwpkh|elsh|wpkh|wsh|pkh|sh|tr)\((?=.*xpub|.*tpub|.*slip77)', text):
        report.fail('descriptor', 'output descriptor at offset %d' % match.start())

    for match in re.finditer(r'\[[0-9a-f]{8}/\d+\'', text):
        report.fail('key origin', 'descriptor key origin %s...' % match.group())

    # BIP39 phrases. No wordlist, so match the shape: a long run of short
    # lowercase words. Stripped dumps contain symbols and paths, not prose.
    for match in re.finditer(r'\b(?:[a-z]{3,8} ){11,23}[a-z]{3,8}\b', text):
        words = match.group().split()
        if len(words) in (12, 15, 18, 21, 24):
            report.fail('mnemonic', '%d-word phrase "%s ..."'
                        % (len(words), ' '.join(words[:3])))

    for keyword in ('mnemonic', 'passphrase', 'password', 'pin_data', 'private_key',
                    'xprv', 'seed_hex', 'api_key', 'auth_token'):
        if re.search(r'(?i)\b%s\b' % keyword, text):
            report.warn('keyword', 'the string %r appears in the dump' % keyword)

    hexes = {match.group() for match in re.finditer(r'\b[0-9a-f]{64}\b', text)}
    if hexes:
        report.warn('high-entropy', '%d 64-hex string(s), e.g. %s'
                    % (len(hexes), sorted(hexes)[0]))


def check_paths(text, report):
    '''Home directory paths must name the placeholder, never a real account.

    Scanning every string rather than just the module list means the unloaded
    module list, CodeView records and any stream not enumerated here are all
    covered without having to know where a path might turn up.
    '''
    redacted = 0
    users = {}
    for match in re.finditer(r'(?i)(?:/Users/|/home/|\\Users\\)([^/\\\s]+)', text):
        name = match.group(1)
        if name == PATH_PLACEHOLDER:
            redacted += 1
        elif name not in ('Shared', 'Public', 'Default', 'All Users'):
            users.setdefault(name, match.group(0))
    if users:
        report.fail('username', 'home directory paths name the local account (%s), '
                    'e.g. %s -- crashpad-redact-module-paths.patch was not applied'
                    % (', '.join(sorted(users)), users[sorted(users)[0]]))
    elif redacted:
        report.note('%d home directory path(s), all redacted to %s'
                    % (redacted, PATH_PLACEHOLDER))
    else:
        report.note('no home directory paths')


def check_file(path, report):
    with open(path, 'rb') as handle:
        data = handle.read()
    dump = Minidump(data)
    text = extract_text(data)
    check_structure(dump, report)
    check_paths(text, report)
    check_content(text, report)
    return report


def collect(paths):
    for path in paths:
        if os.path.isdir(path):
            for root, _, files in os.walk(path):
                for name in sorted(files):
                    if name.endswith('.dmp'):
                        yield os.path.join(root, name)
        else:
            yield path


def main():
    parser = argparse.ArgumentParser(description='Check minidumps for wallet secrets.')
    parser.add_argument('paths', nargs='+', help='.dmp files, or directories to walk')
    parser.add_argument('--strict', action='store_true', help='treat warnings as failures')
    parser.add_argument('--quiet', action='store_true', help='only report problems')
    args = parser.parse_args()

    files = list(collect(args.paths))
    if not files:
        print('no .dmp files found', file=sys.stderr)
        return 2

    failed = False
    for path in files:
        report = Report(path)
        try:
            check_file(path, report)
        except (ValueError, struct.error, IndexError) as error:
            print('%s\n  ERROR unreadable: %s' % (path, error))
            failed = True
            continue

        problems = report.failures or (report.warnings and args.strict)
        if args.quiet and not problems:
            continue
        print(path)
        for check, detail in report.failures:
            print('  FAIL [%s] %s' % (check, detail))
        for check, detail in report.warnings:
            print('  WARN [%s] %s' % (check, detail))
        if not args.quiet:
            for detail in report.notes:
                print('  ok   %s' % detail)
        if problems:
            failed = True

    print('\n%d dump(s) checked, %s' % (len(files), 'FAILED' if failed else 'clean'))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
