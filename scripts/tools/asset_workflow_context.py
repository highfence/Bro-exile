#!/usr/bin/env python3
"""Print Bro-exile asset workflow handoff context for agents."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
GODOT_BIN = "/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64"
ASSET_REF_RE = re.compile(r'res://assets/[^"\'\s)]+')


PRIMARY_DOCS = [
    "AGENTS.md",
    ".codex/skills/bro-exile-asset-workflow/SKILL.md",
    "docs/art/agent-asset-workflow.md",
    "docs/art/asset-generation-principles.md",
    "docs/art/player-asset-harness.md",
    "docs/art/prompt-packs/README.md",
    "docs/art/prompt-packs/enemy-single-image.md",
    "docs/plans/2026-06-04-feat-automated-asset-quality-harness-plan.md",
    "docs/reports/assets/2026-06-04-asset-automation-dry-run-report.md",
    "docs/reports/assets/2026-06-05-enemy-motion-profile-comparison-report.md",
]

HARNESS_PATHS = [
    "scripts/tools/asset_candidate_harness.py",
    "scripts/tools/asset_workflow_context.py",
    "scripts/tools/player_asset_harness.gd",
    "scripts/tools/zombie_asset_harness.gd",
    "scenes/tools/player_asset_harness.tscn",
    "scenes/tools/zombie_asset_harness.tscn",
    "scenes/animation/player_idle_rig.tscn",
    "scenes/animation/zombie_rig.tscn",
]

ANCHOR_ASSETS = [
    "assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts",
    "assets/sprites/characters/miner_zombie_v1/zombie_idle.png",
    "assets/sprites/characters/p1_monsters_runtime_v1",
    "assets/sprites/characters/p1_monsters_runtime_v2",
]

COMMANDS = {
    "scan_main_asset_refs": "python3 scripts/tools/asset_candidate_harness.py scan --script scripts/main.gd",
    "headless_load": (
        f"{GODOT_BIN} --headless --log-file /private/tmp/bro-exile-headless.log "
        "--path /Users/highfence/Documents/Bro-exile --quit"
    ),
    "player_harness": (
        f"{GODOT_BIN} --log-file /private/tmp/bro-exile-player-harness.log "
        "--path /Users/highfence/Documents/Bro-exile "
        "--scene res://scenes/tools/player_asset_harness.tscn --quit-after 360 -- "
        "--asset-output=/private/tmp/bro-exile-asset-harness --frame-count=8"
    ),
    "zombie_harness": (
        f"{GODOT_BIN} --log-file /private/tmp/bro-exile-zombie-harness.log "
        "--path /Users/highfence/Documents/Bro-exile "
        "--scene res://scenes/tools/zombie_asset_harness.tscn --quit-after 360 -- "
        "--asset-output=/private/tmp/bro-exile-zombie-harness "
        "--source-frame=res://assets/sprites/characters/miner_zombie_v1/zombie_idle.png "
        "--motion-profile=shamble --frame-count=8"
    ),
    "stage1_capture": (
        f"{GODOT_BIN} --log-file /private/tmp/bro-exile-stage1.log "
        "--path /Users/highfence/Documents/Bro-exile -- --capture-stage1"
    ),
    "monster_roster_capture": (
        f"{GODOT_BIN} --log-file /private/tmp/bro-exile-roster.log "
        "--path /Users/highfence/Documents/Bro-exile -- --capture-monster-roster"
    ),
}


def rel_status(path: str) -> dict[str, Any]:
    target = ROOT / path
    return {
        "path": path,
        "exists": target.exists(),
        "kind": "dir" if target.is_dir() else "file" if target.is_file() else "missing",
    }


def scan_asset_refs(script_path: str) -> dict[str, Any]:
    script = ROOT / script_path
    if not script.exists():
        return {
            "script": script_path,
            "exists": False,
            "total_refs": 0,
            "unique_refs": 0,
            "missing_refs": [],
            "refs": [],
        }

    text = script.read_text(encoding="utf-8")
    refs = ASSET_REF_RE.findall(text)
    counts: dict[str, int] = {}
    for ref in refs:
        counts[ref] = counts.get(ref, 0) + 1

    missing = []
    for ref in sorted(counts):
        relative = ref.removeprefix("res://")
        if not (ROOT / relative).exists():
            missing.append(ref)

    return {
        "script": script_path,
        "exists": True,
        "total_refs": len(refs),
        "unique_refs": len(counts),
        "missing_refs": missing,
        "refs": [
            {"path": path, "count": count}
            for path, count in sorted(counts.items())
        ],
    }


def build_context() -> dict[str, Any]:
    return {
        "project": "Bro-exile",
        "repo_root": str(ROOT),
        "godot_bin": GODOT_BIN,
        "style_direction": "Cute but slightly grotesque mine-survival action toy; reference Brotato structure only, never copy its shapes.",
        "primary_docs": [rel_status(path) for path in PRIMARY_DOCS],
        "harnesses": [rel_status(path) for path in HARNESS_PATHS],
        "anchor_assets": [rel_status(path) for path in ANCHOR_ASSETS],
        "motion_profiles": ["shamble", "sprint", "brace", "heavy", "skitter", "throw"],
        "commands": COMMANDS,
        "main_asset_refs": scan_asset_refs("scripts/main.gd"),
        "handoff_rules": [
            "Run git status before editing and do not touch unrelated user changes.",
            "Keep generated assets as candidates until the user approves promotion.",
            "Store prompt, revised prompt, source refs, metadata, 64px preview, harness output, and capture path.",
            "Use --log-file /private/tmp/... for Godot commands.",
            "Do not trust headless exit code alone for harness output; verify expected files exist.",
        ],
    }


def print_markdown(context: dict[str, Any]) -> None:
    print("# Bro-exile Asset Workflow Context")
    print()
    print(f"- Repo: `{context['repo_root']}`")
    print(f"- Godot: `{context['godot_bin']}`")
    print(f"- Style: {context['style_direction']}")
    print()

    print("## Start Here")
    for item in context["primary_docs"]:
        marker = "ok" if item["exists"] else "missing"
        print(f"- `{item['path']}`: {marker}")
    print()

    print("## Harnesses")
    for item in context["harnesses"]:
        marker = "ok" if item["exists"] else "missing"
        print(f"- `{item['path']}`: {marker}")
    print()

    print("## Anchor Assets")
    for item in context["anchor_assets"]:
        marker = "ok" if item["exists"] else "missing"
        print(f"- `{item['path']}`: {marker}")
    print()

    refs = context["main_asset_refs"]
    print("## Main Scene Asset Refs")
    print(f"- total refs: {refs['total_refs']}")
    print(f"- unique refs: {refs['unique_refs']}")
    if refs["missing_refs"]:
        print("- missing refs:")
        for ref in refs["missing_refs"]:
            print(f"  - `{ref}`")
    else:
        print("- missing refs: none")
    print()

    print("## Commands")
    for name, command in context["commands"].items():
        print(f"- {name}:")
        print(f"  `{command}`")
    print()

    print("## Handoff Rules")
    for rule in context["handoff_rules"]:
        print(f"- {rule}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Print Bro-exile asset workflow context.")
    parser.add_argument("--format", choices=["markdown", "json"], default="json")
    args = parser.parse_args()

    context = build_context()
    if args.format == "markdown":
        print_markdown(context)
    else:
        print(json.dumps(context, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
