# Task profiling

Parse `Task::setStatus` timing lines from green-qt runs (Qt logging category `profile`).

## Capture a pin-login run (Qt)

Task timing lines use the **`profile`** logging category (`qCInfo`).

**Important:** do **not** pass `--ui` on the command line unless you redirect stderr yourself.
The datadir log file (`logs/dev.txt`) is written by the **watchdog** process, which spawns the UI child and captures its stderr. Running with `--ui` directly skips the watchdog — logs go to the terminal only and **`dev.txt` is not updated**.

### Option A — parse `logs/dev.txt` (normal app launch)

**macOS:**

```bash
# from build/: use ./Blockstream.app/...  (no ./build/ prefix)
./Blockstream.app/Contents/MacOS/Blockstream --debug
```

Then pin-login in the UI. Parse the log file (path is printed at startup as `Log file:`):

```bash
python3 tools/task-profiling/parse_task_timings.py \
  "$HOME/Library/Application Support/Blockstream/Green/logs/dev.txt" \
  --pin-only --summary
```

Quick check that profiling lines were captured:

```bash
grep '\[profile\].*status change' \
  "$HOME/Library/Application Support/Blockstream/Green/logs/dev.txt" | tail
```

### Option B — capture stderr to a file (`tee`)

Use this from Qt Creator or when you want a dedicated capture file. Optional filter:

```bash
QT_LOGGING_RULES="*=false;profile.info=true" \
  ./build/Blockstream.app/Contents/MacOS/Blockstream --ui --debug --tempdatadir \
  2>&1 | tee /tmp/green-pin-login.log
```

**Linux** (plain `blockstream` binary in `build/`):

```bash
QT_LOGGING_RULES="*=false;profile.info=true" \
  ./build/blockstream --ui --debug --tempdatadir \
  2>&1 | tee /tmp/green-pin-login.log
```

1. Use **pin login** (not Face ID — Face ID skips pin-server requests).
2. Perform one login with a benchmark wallet.
3. Stop logging after balances appear on Home.
4. Build must include the **tasks-profiling** branch (`qCInfo(profile)` in `Task::setStatus`).

## Inspect logs manually

Task lines appear as `[profile]` category with `status change` in the message:

```bash
grep 'status change' /tmp/green-pin-login.log
# or filter by category in the custom log handler output:
grep '\[profile\]' /tmp/green-pin-login.log
```

## Parse the log

```bash
python3 tools/task-profiling/parse_task_timings.py /tmp/green-pin-login.log
python3 tools/task-profiling/parse_task_timings.py /tmp/green-pin-login.log --pin-only --summary
```

- **Timeline**: every transition per `context=0x…` pointer (session / context / controller).
- **Active-phase totals**: time spent in `Active` per task (best proxy for “work” time).
- **Pin benchmark** (`--summary`): summed transition time from first `Connect` or `Login mode=pin` → `Active` through the last `Load Balance` leaving `Active`.

## Hot-path task labels

| Task | Extra `description()` fields |
|------|------------------------------|
| `Connect` | `timeout_ms` |
| `Login` | `mode=pin` / `mnemonic` / … (no secrets) |
| `Get Credentials` | `phase=post_login_credentials` |
| `Load Accounts` | `refresh=` |
| `Sync Accounts` | `phase=account_sync` |
| `Load Account` | `pointer=` |
| `Load Balance` | `subaccount=` |
| `Load Assets` | `refresh=` |
