#!/usr/bin/env python3
"""
Parse green-qt task profiling logs (qCInfo profile category from Task::setStatus).

Example log line (Blockstream custom logger):
  [2026-05-20 11:09:08.181] INFO  [profile] Login network=mainnet mode=pin status change Ready -> Active duration_ms=12 context=0x7f8b2c00

Usage:
  QT_LOGGING_RULES="*=false;profile.info=true" ./Blockstream --ui --debug 2>&1 | tee login.log
  python3 tools/task-profiling/parse_task_timings.py login.log
  python3 tools/task-profiling/parse_task_timings.py login.log --pin-only --summary
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Iterable


ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]*m")

STATUS_TAIL_RE = re.compile(
    r'status change "?(?P<from_status>\w+)"? -> "?(?P<to_status>\w+)"? '
    r"duration_ms=(?P<duration_ms>\d+) context=0x(?P<context>[0-9a-fA-F]+)"
)
STATUS_MARKER = " status change "
TASK_PROFILING_TAG = "[task-profiling]"

# Blockstream logMessageHandler: [timestamp] LEVEL [category] message
LOG_LINE_PREFIX_RE = re.compile(
    r"^\[[^\]]+\]\s+(?:DEBUG|INFO|WARNING|WARN|CRITICAL)\s+\[[^\]]+\]\s+"
)


@dataclass
class StatusEvent:
    line_no: int
    task: str
    from_status: str
    to_status: str
    duration_ms: int
    context: str

    @property
    def task_base(self) -> str:
        """Task type without network=/mode=/… parameters."""
        parts = []
        for token in self.task.split():
            if "=" in token:
                break
            parts.append(token)
        return " ".join(parts) if parts else self.task


@dataclass
class ContextFlow:
    context: str
    events: list[StatusEvent] = field(default_factory=list)

    def has_pin_login(self) -> bool:
        return any("mode=pin" in e.task for e in self.events)

    def active_durations_ms(self) -> dict[str, int]:
        """Sum time spent in Active per task label (Active -> * transitions)."""
        totals: dict[str, int] = defaultdict(int)
        for event in self.events:
            if event.from_status == "Active":
                totals[event.task] += event.duration_ms
        return dict(totals)


def strip_ansi(text: str) -> str:
    return ANSI_ESCAPE_RE.sub("", text)


def normalize_task_label(raw: str) -> str:
    """Drop Blockstream/Qt log prefixes, task-profiling tag, and quotes."""
    task = strip_ansi(raw.strip())
    task = LOG_LINE_PREFIX_RE.sub("", task)
    if task.startswith(TASK_PROFILING_TAG):
        task = task[len(TASK_PROFILING_TAG) :].lstrip()
    # Legacy qt.core: style
    if ": " in task and not task.startswith('"'):
        task = task.rsplit(": ", 1)[-1].strip()
    if len(task) >= 2 and task[0] == '"' and task[-1] == '"':
        task = task[1:-1]
    return task


def parse_lines(lines: Iterable[str]) -> list[StatusEvent]:
    events: list[StatusEvent] = []
    for line_no, raw in enumerate(lines, start=1):
        line = strip_ansi(raw.strip())
        marker_at = line.find(STATUS_MARKER)
        if marker_at < 0:
            continue
        task = normalize_task_label(line[:marker_at])
        tail = line[marker_at + 1 :]
        match = STATUS_TAIL_RE.match(tail)
        if not match or not task:
            continue
        events.append(
            StatusEvent(
                line_no=line_no,
                task=task,
                from_status=match.group("from_status"),
                to_status=match.group("to_status"),
                duration_ms=int(match.group("duration_ms")),
                context=match.group("context"),
            )
        )
    return events


def group_by_context(events: list[StatusEvent]) -> list[ContextFlow]:
    by_ctx: dict[str, list[StatusEvent]] = defaultdict(list)
    for event in events:
        by_ctx[event.context].append(event)
    flows = [ContextFlow(context=ctx, events=evs) for ctx, evs in by_ctx.items()]
    for flow in flows:
        flow.events.sort(key=lambda e: e.line_no)
    flows.sort(key=lambda f: f.events[0].line_no if f.events else 0)
    return flows


def print_timeline(flow: ContextFlow) -> None:
    print(f"\n=== context 0x{flow.context} ({len(flow.events)} transitions) ===")
    for event in flow.events:
        print(
            f"  L{event.line_no:5d}  {event.duration_ms:6d} ms  "
            f"{event.from_status:8s} -> {event.to_status:8s}  {event.task}"
        )


def print_active_summary(flow: ContextFlow) -> None:
    totals = flow.active_durations_ms()
    if not totals:
        return
    print(f"\n--- Active-phase totals (context 0x{flow.context}) ---")
    for task, ms in sorted(totals.items(), key=lambda x: -x[1]):
        print(f"  {ms:7d} ms  {task}")


def pin_login_benchmark(
    flows: list[ContextFlow], pin_only: bool
) -> dict[str, int | str | None]:
    """
    Approximate pin-login → balances using task logs.

    Uses all contexts in the log: pin login and per-session balance loads may
    share the same Session* (one context) or appear as separate pointers.
    """
    events: list[StatusEvent] = []
    for flow in flows:
        if pin_only and not flow.has_pin_login():
            continue
        events.extend(flow.events)
    if not events:
        return {"start_line": None, "end_line": None, "window_ms": None, "login_active_ms": None}

    events.sort(key=lambda e: e.line_no)

    start = next(
        (
            e
            for e in events
            if e.to_status == "Active"
            and (
                e.task_base == "Connect"
                or (e.task_base == "Login" and "mode=pin" in e.task)
            )
        ),
        None,
    )
    end = next(
        (
            e
            for e in reversed(events)
            if e.from_status == "Active" and e.task_base == "Load Balance"
        ),
        None,
    )

    total_ms = None
    if start and end and start.line_no <= end.line_no:
        total_ms = sum(
            e.duration_ms for e in events if start.line_no < e.line_no <= end.line_no
        )

    login_finished = next(
        (
            e
            for e in events
            if e.task_base == "Login"
            and "mode=pin" in e.task
            and e.from_status == "Active"
            and e.to_status == "Finished"
        ),
        None,
    )

    return {
        "start_line": start.line_no if start else None,
        "end_line": end.line_no if end else None,
        "window_ms": total_ms,
        "login_active_ms": login_finished.duration_ms if login_finished else None,
        "load_balance_events": [
            (e.task, e.duration_ms)
            for e in events
            if e.from_status == "Active" and e.task_base == "Load Balance"
        ],
    }


def print_benchmark(flows: list[ContextFlow], pin_only: bool) -> None:
    print("\n========== Pin-login benchmark (approximate) ==========")
    print(
        "Measure: last PIN digit entered → balances on Home needs UI correlation;\n"
        "this script sums task transitions from first Connect/Login(pin) Active through\n"
        "the last Load Balance leaving Active (across all contexts in the log)."
    )
    bench = pin_login_benchmark(flows, pin_only)
    if bench["start_line"] is None:
        print("  (no Connect/Login(pin) start found)")
        return
    print(f"  log lines {bench['start_line']} .. {bench['end_line']}")
    print(f"  summed transition time in window: {bench['window_ms']} ms")
    if bench["login_active_ms"] is not None:
        print(f"  Login (pin) Active -> Finished: {bench['login_active_ms']} ms")
    loads = bench.get("load_balance_events") or []
    if loads:
        print(f"  Load Balance Active phases ({len(loads)}):")
        for task, ms in loads:
            print(f"    {ms:6d} ms  {task}")


def print_global_summary(events: list[StatusEvent]) -> None:
    by_base: dict[str, int] = defaultdict(int)
    count: dict[str, int] = defaultdict(int)
    for event in events:
        if event.from_status != "Active":
            continue
        base = event.task_base
        by_base[base] += event.duration_ms
        count[base] += 1

    print("\n========== Global Active-phase totals (all contexts) ==========")
    for base, ms in sorted(by_base.items(), key=lambda x: -x[1]):
        print(f"  {ms:7d} ms  ({count[base]:3d}x)  {base}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "logfile",
        nargs="?",
        help="Log file path (default: stdin)",
    )
    parser.add_argument(
        "--pin-only",
        action="store_true",
        help="Only print contexts that include Login mode=pin",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Print global Active-phase totals and pin benchmark",
    )
    parser.add_argument(
        "--no-timeline",
        action="store_true",
        help="Skip per-context timelines",
    )
    args = parser.parse_args()

    if args.logfile:
        with open(args.logfile, encoding="utf-8", errors="replace") as fh:
            events = parse_lines(fh)
    else:
        events = parse_lines(sys.stdin)

    if not events:
        print("No task status change lines found.", file=sys.stderr)
        return 1

    flows = group_by_context(events)
    print(f"Parsed {len(events)} transitions across {len(flows)} context(s).")

    if not args.no_timeline:
        for flow in flows:
            if args.pin_only and not flow.has_pin_login():
                continue
            print_timeline(flow)
            print_active_summary(flow)

    if args.summary:
        print_global_summary(events)
        print_benchmark(flows, pin_only=args.pin_only)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
