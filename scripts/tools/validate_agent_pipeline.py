#!/usr/bin/env python3
"""Validate the resumable Bro-exile public-demo agent pipeline.

The canonical state lives in slice todo frontmatter.  The latest structured
``pipeline-state`` marker in each todo's append-only Work Log is evidence of
the handoff that produced that state.  Queue/current-state documents are
projections and may never override or drift from the canonical records.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
from agent_pipeline_state import ValidationError, validate_pipeline


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Repository or fixture root (defaults to the repository root).",
    )
    args = parser.parse_args()
    try:
        snapshot = validate_pipeline(args.root.resolve())
    except (OSError, ValidationError) as exc:
        print(f"PIPELINE INVALID: {exc}", file=sys.stderr)
        return 1

    active = snapshot.active
    artifacts = ",".join(active.state["artifacts"]) or "none"
    print("PIPELINE VALID")
    print(f"active_slice={active.issue_id}")
    print(f"github_issue={active.github_issue}")
    print(f"owner_lane={active.state['owner_lane']}")
    print(f"last_handoff={active.last_handoff}")
    print(f"artifacts={artifacts}")
    print(f"validator_verdict={active.state['validator_verdict']}")
    print(f"user_gate={active.state['user_gate']}")
    print(f"next_allowed_transition={snapshot.next_transition}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
