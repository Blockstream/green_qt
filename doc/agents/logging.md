# Logging

What to keep out of logs, and how support logs are redacted. Part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## Where logs go

- Qt messages go through `logMessageHandler` (`src/logging.cpp`). GDK and LWK write to the same output, and the app stores it in the file returned by `GetLogFilename()` (`src/core/util.cpp`).
- When a user shares logs with support, `RequestSupportController::submit()` (`src/requestsupportcontroller.cpp`) runs `RedactLog()` into a temporary file and uploads that file to Zendesk.
- The log on disk is **not** redacted. Users also attach it by hand, so write log statements as if the raw file will be read by someone else.

## Rules for new or changed log statements

1. **Never log secrets.** This covers mnemonics, BIP39 passphrases, PINs, PIN data (`encrypted_data`, `hmac`), private keys, credentials and blinding keys. `RedactLog()` is a safety net, not permission. The raw file on disk keeps everything.
2. **Prefer not to log wallet data.** That means xpubs, descriptors, addresses, txids, amounts, account names and memos. Log counts, ids, states, sizes and error strings instead.
3. **Avoid dumping whole objects** (`qDebug() << QJsonObject`, GDK call results) when they contain wallet data. For example, `CreateTransactionController::update()` dumps every UTXO with its txid, script and amount.
4. **If wallet data must be logged**, write it under a field name `RedactLog()` already recognizes (see the table below). If you add a new field or format, extend `RedactLog()` and add a matching line to `UtilTest::redactLog()` in `tests/unit/tst_util.cpp`.
5. **Paths are fine.** The user's home directory is replaced with `~`, including Windows' forward-slash and JSON-escaped forms.

## What `RedactLog()` covers

Redaction works line by line, and each value keeps a stable placeholder through the whole file, so it can still be followed across lines.

| Placeholder | Matches |
|---|---|
| `<XPUB_n>` | `xpub`/`tpub`/`ypub`/`zpub`/… keys, including inside descriptors |
| `<ADDR_n>` | bech32/blech32 addresses, and any value of an `address` field (base58, Liquid confidential) wherever it appears later |
| `<HEX_n>` | lowercase hex of 32 or more characters, plus any-length hex in `script`, `blinding_key`, `txhash`, `txid` and `*blinder` fields (lines get truncated) |
| `<SAT_n>` | `satoshi` amounts |
| `<BLOB_n>` | `blob`, `hmac` and `encrypted_data` values |
| `<FP_n>` | wallet fingerprints from `set_fingerprint` and `[xxxxxxxx/…]` key origins |
| `<NAME_n>` | `name` values, except on `create_session` lines |
| `~` | the home directory |

Both GDK formats (`\"field\": String(\"value\")` and `"field": String("value")`) and Qt JSON (`"field":"value"`) are recognized.

Kept on purpose, because they're public or needed for debugging:

- the network config on `create_session` lines
- block hashes, genesis hashes and the policy asset
- Bluetooth scan results, hardware model, camera names and the Countly id

## Checking a change

- Run `test_util` (`tests/unit/tst_util.cpp`).
- For a new format, run `RedactLog()` over a real log that contains it, then search the output for the original values.
