#!/usr/bin/env python3
"""Deterministic balance probe for Bro-exile's common-currency drops."""

from __future__ import annotations

import ast
import json
import math
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
CONTENT_PATH = ROOT / "scripts/game/demo_content.gd"
ECONOMY_PATH = ROOT / "scripts/game/economy_rules.gd"

# Three representative full-run enemy mixes, combined to avoid starter-specific noise.
ENEMY_COUNTS = {
    "zombie": 25,
    "fast_zombie": 23,
    "spider": 27,
    "thrower": 13,
    "shield_zombie": 11,
    "toxic_spider": 17,
    "bomb_miner": 5,
}
ORE_FAMILY = {"zombie", "spider", "shield_zombie"}
CATALYST_FAMILY = {"fast_zombie", "thrower", "toxic_spider", "bomb_miner"}
COMMON_CURRENCIES = ("ore", "catalyst")
RUN_COUNT = 3
EARLY_ZOMBIE_COUNT = 2
AVERAGE_REROLL_COST = 5.0


def _extract_gdscript_dictionary(source: str, constant_name: str) -> dict[str, Any]:
    marker = re.search(rf"const\s+{re.escape(constant_name)}\s*:=\s*\{{", source)
    if marker is None:
        raise ValueError(f"missing constant: {constant_name}")
    start = source.find("{", marker.start())
    depth = 0
    in_string = False
    escaped = False
    end = -1
    for index in range(start, len(source)):
        char = source[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end = index + 1
                break
    if end < 0:
        raise ValueError(f"unterminated constant: {constant_name}")
    literal = source[start:end]
    literal = re.sub(r"\btrue\b", "True", literal)
    literal = re.sub(r"\bfalse\b", "False", literal)
    literal = re.sub(r"\bnull\b", "None", literal)
    value = ast.literal_eval(literal)
    if not isinstance(value, dict):
        raise ValueError(f"constant is not a dictionary: {constant_name}")
    return value


def _profile_distribution(profile: dict[str, Any]) -> tuple[dict[str, float], dict[str, int]]:
    if "drop_weights" in profile:
        raw_weights = profile.get("drop_weights", {})
        raw_amounts = profile.get("currency_amounts", {})
        weights = {
            "ore": float(raw_weights.get("ore", 0.0)),
            "catalyst": float(raw_weights.get("catalyst", 0.0)),
            "none": float(raw_weights.get("none", 0.0)),
        }
        amounts = {
            "ore": int(raw_amounts.get("ore", 0)),
            "catalyst": int(raw_amounts.get("catalyst", 0)),
        }
        return weights, amounts

    primary = str(profile.get("primary_currency_id", ""))
    chance = float(profile.get("chance", 0.0))
    amount = int(profile.get("amount", 0))
    weights = {"ore": 0.0, "catalyst": 0.0, "none": max(0.0, 1.0 - chance)}
    amounts = {"ore": 0, "catalyst": 0}
    if primary in COMMON_CURRENCIES:
        weights[primary] = chance
        amounts[primary] = amount
    return weights, amounts


def _common_contract_valid(profiles: dict[str, Any]) -> bool:
    for enemy_type in ENEMY_COUNTS:
        profile = profiles.get(enemy_type, {})
        if not bool(profile.get("drops_enabled", False)):
            return False
        primary = str(profile.get("primary_currency_id", ""))
        if primary not in COMMON_CURRENCIES:
            return False
        if "drop_weights" not in profile or "currency_amounts" not in profile:
            return False
        weights, amounts = _profile_distribution(profile)
        if not math.isclose(sum(weights.values()), 1.0, abs_tol=1e-6):
            return False
        if weights["none"] <= 0.0 or max(weights[currency] for currency in COMMON_CURRENCIES) >= 1.0:
            return False
        if weights[primary] <= weights["catalyst" if primary == "ore" else "ore"]:
            return False
        if any(amounts[currency] <= 0 for currency in COMMON_CURRENCIES):
            return False

    forge_profile = profiles.get("elite_zombie", {})
    mid_boss_profile = profiles.get("mid_boss", {})
    return (
        forge_profile.get("primary_currency_id") == "forge_core"
        and int(forge_profile.get("amount", 0)) == 1
        and float(forge_profile.get("chance", 0.0)) == 1.0
        and mid_boss_profile.get("primary_currency_id") == "forge_core"
        and int(mid_boss_profile.get("amount", 0)) == 2
        and float(mid_boss_profile.get("chance", 0.0)) == 1.0
    )


def _round_clear_ore(source: str) -> int:
    rewards = _extract_gdscript_dictionary(source, "ROUND_CLEAR_ORE_REWARDS")
    return sum(int(value) for value in rewards.values())


def _weighted_family_chances(
    profiles: dict[str, Any], family: set[str]
) -> tuple[float, float]:
    total_count = sum(ENEMY_COUNTS[enemy_type] for enemy_type in family)
    ore = 0.0
    catalyst = 0.0
    for enemy_type in family:
        weights, _ = _profile_distribution(profiles[enemy_type])
        count = ENEMY_COUNTS[enemy_type]
        ore += weights["ore"] * count
        catalyst += weights["catalyst"] * count
    return ore / total_count, catalyst / total_count


def main() -> None:
    content_source = CONTENT_PATH.read_text(encoding="utf-8")
    economy_source = ECONOMY_PATH.read_text(encoding="utf-8")
    profiles = _extract_gdscript_dictionary(content_source, "ENEMY_CURRENCY_PROFILES")
    fixed_ore = float(_round_clear_ore(economy_source) * RUN_COUNT)

    expected = {"ore": fixed_ore, "catalyst": 0.0}
    no_drop_events = 0.0
    total_enemies = float(sum(ENEMY_COUNTS.values()))
    for enemy_type, count in ENEMY_COUNTS.items():
        weights, amounts = _profile_distribution(profiles[enemy_type])
        for currency in COMMON_CURRENCIES:
            expected[currency] += count * weights[currency] * amounts[currency]
        no_drop_events += count * weights["none"]

    common_total = expected["ore"] + expected["catalyst"]
    ore_share = expected["ore"] / common_total if common_total else 0.0
    catalyst_share = expected["catalyst"] / common_total if common_total else 0.0
    ore_family_ore, ore_family_catalyst = _weighted_family_chances(profiles, ORE_FAMILY)
    catalyst_family_ore, catalyst_family_catalyst = _weighted_family_chances(
        profiles, CATALYST_FAMILY
    )
    early_weights, early_amounts = _profile_distribution(profiles["zombie"])
    first_shop_budget = (
        float(_round_clear_ore(economy_source))
        + EARLY_ZOMBIE_COUNT * early_weights["ore"] * early_amounts["ore"]
    )
    fixed_ore_share = fixed_ore / expected["ore"] if expected["ore"] else 1.0

    metrics = {
        "distribution_error": abs(ore_share - 0.75) + abs(catalyst_share - 0.25),
        "ore_share": ore_share,
        "ore_share_upper": ore_share,
        "catalyst_share": catalyst_share,
        "catalyst_share_upper": catalyst_share,
        "ore_family_bias_gap": ore_family_ore - ore_family_catalyst,
        "catalyst_family_bias_gap": catalyst_family_catalyst - catalyst_family_ore,
        "first_shop_budget": first_shop_budget,
        "first_shop_budget_upper": first_shop_budget,
        "fixed_ore_share": fixed_ore_share,
        "currency_contract_valid": 1 if _common_contract_valid(profiles) else 0,
        "expected_ore": expected["ore"] / RUN_COUNT,
        "expected_catalyst": expected["catalyst"] / RUN_COUNT,
        "no_drop_share": no_drop_events / total_enemies,
        "ore_family_ore_chance": ore_family_ore,
        "ore_family_catalyst_chance": ore_family_catalyst,
        "catalyst_family_ore_chance": catalyst_family_ore,
        "catalyst_family_catalyst_chance": catalyst_family_catalyst,
        "expected_rerolls": expected["catalyst"] / RUN_COUNT / AVERAGE_REROLL_COST,
    }
    print(json.dumps({key: round(value, 6) for key, value in metrics.items()}, sort_keys=True))


if __name__ == "__main__":
    main()
