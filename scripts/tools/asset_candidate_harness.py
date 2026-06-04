#!/usr/bin/env python3
"""Prepare generated asset candidates for Bro-exile review."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import shutil
from pathlib import Path
from typing import Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
ASSET_REF_RE = re.compile(r'res://assets/[^"\s]+')


def parse_hex_color(value: str) -> tuple[int, int, int]:
    raw = value.strip().lstrip("#")
    if len(raw) != 6:
        raise ValueError(f"Expected hex color like #ff00ff, got {value!r}")
    return int(raw[0:2], 16), int(raw[2:4], 16), int(raw[4:6], 16)


def clamp_channel(value: float) -> int:
    return max(0, min(255, int(round(value))))


def is_magenta_key(key: tuple[int, int, int]) -> bool:
    return key[0] > 220 and key[1] < 40 and key[2] > 220


def is_magenta_spill(red: int, green: int, blue: int, key: tuple[int, int, int]) -> bool:
    if not is_magenta_key(key):
        return False
    if red < 80 or blue < 80:
        return False
    if abs(red - blue) > 72:
        return False
    return green < min(red, blue) * 0.58


def remove_key_spill(
    red: int,
    green: int,
    blue: int,
    key: tuple[int, int, int],
    coverage: float,
) -> tuple[int, int, int]:
    coverage = max(0.08, min(1.0, coverage))
    return (
        clamp_channel((red - key[0] * (1.0 - coverage)) / coverage),
        clamp_channel((green - key[1] * (1.0 - coverage)) / coverage),
        clamp_channel((blue - key[2] * (1.0 - coverage)) / coverage),
    )


def neutralize_magenta_spill(red: int, green: int, blue: int) -> tuple[int, int, int]:
    luma = clamp_channel((red * 0.299) + (green * 0.587) + (blue * 0.114))
    return (
        clamp_channel(luma * 0.82),
        clamp_channel(luma * 0.84),
        clamp_channel(luma * 0.80),
    )


def neutralize_chroma_spill_image(image: Image.Image, key: tuple[int, int, int]) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 8 and is_magenta_spill(red, green, blue, key):
                red, green, blue = neutralize_magenta_spill(red, green, blue)
                pixels[x, y] = (red, green, blue, alpha)
    return rgba


def asset_refs_in_code(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    return ASSET_REF_RE.findall(text)


def command_scan(args: argparse.Namespace) -> int:
    script_path = ROOT / args.script
    refs = asset_refs_in_code(script_path)
    counts: dict[str, int] = {}
    for ref in refs:
        counts[ref] = counts.get(ref, 0) + 1

    report = {
        "script": str(script_path.relative_to(ROOT)),
        "total_refs": len(refs),
        "unique_refs": len(counts),
        "repeated_refs": [
            {"path": path, "count": count}
            for path, count in sorted(counts.items(), key=lambda item: (-item[1], item[0]))
            if count > 1
        ],
        "refs": [
            {"path": path, "count": count}
            for path, count in sorted(counts.items())
        ],
    }

    if args.out:
        out = Path(args.out)
        if not out.is_absolute():
            out = ROOT / out
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    else:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


def remove_chroma_key(
    image: Image.Image,
    key: tuple[int, int, int],
    transparent_threshold: int,
    opaque_threshold: int,
) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size

    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            distance = max(abs(red - key[0]), abs(green - key[1]), abs(blue - key[2]))
            if distance <= transparent_threshold:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if distance < opaque_threshold:
                ratio = (distance - transparent_threshold) / max(1, opaque_threshold - transparent_threshold)
                output_alpha = int(round(alpha * ratio * ratio * (3.0 - 2.0 * ratio)))
                if output_alpha <= 8:
                    pixels[x, y] = (0, 0, 0, 0)
                else:
                    coverage = output_alpha / max(1, alpha)
                    red, green, blue = remove_key_spill(red, green, blue, key, coverage)
                    pixels[x, y] = (red, green, blue, output_alpha)
                continue
            if is_magenta_spill(red, green, blue, key):
                red, green, blue = neutralize_magenta_spill(red, green, blue)
                pixels[x, y] = (red, green, blue, alpha)
    return rgba


def count_chroma_spill_pixels(image: Image.Image, key: tuple[int, int, int] | None, alpha_threshold: int = 8) -> int:
    if key is None:
        return 0
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    count = 0
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > alpha_threshold and is_magenta_spill(red, green, blue, key):
                count += 1
    return count


def alpha_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int] | None:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > threshold else 0).getbbox()
    if bbox is None:
        return None
    left, top, right, bottom = bbox
    return left, top, right, bottom


def count_opaque_pixels(image: Image.Image, threshold: int = 8) -> int:
    alpha = image.convert("RGBA").getchannel("A")
    get_values = getattr(alpha, "get_flattened_data", alpha.getdata)
    return sum(1 for value in get_values() if value > threshold)


def pack_to_cell(
    image: Image.Image,
    bbox: tuple[int, int, int, int],
    cell_size: int,
    target_occupied_size: int,
) -> tuple[Image.Image, dict[str, Any]]:
    cropped = image.crop(bbox)
    crop_width, crop_height = cropped.size
    largest_axis = max(crop_width, crop_height)
    scale = min(1.0, target_occupied_size / max(1, largest_axis))
    packed_size = (
        max(1, int(round(crop_width * scale))),
        max(1, int(round(crop_height * scale))),
    )
    resized = cropped.resize(packed_size, Image.Resampling.LANCZOS)
    cell = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
    offset = (
        int(round((cell_size - packed_size[0]) * 0.5)),
        int(round((cell_size - packed_size[1]) * 0.5)),
    )
    cell.alpha_composite(resized, offset)
    metadata = {
        "source_bbox": list(bbox),
        "cropped_size": [crop_width, crop_height],
        "cell_size": [cell_size, cell_size],
        "target_occupied_size": target_occupied_size,
        "scale": scale,
        "packed_size": list(packed_size),
        "cell_offset": list(offset),
    }
    return cell, metadata


def relative_or_absolute(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def command_normalize_single_image(args: argparse.Namespace) -> int:
    input_path = Path(args.input)
    if not input_path.is_absolute():
        input_path = ROOT / input_path
    out_dir = Path(args.out_dir)
    if not out_dir.is_absolute():
        out_dir = ROOT / out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    original_path = out_dir / "original_chromakey.png"
    alpha_path = out_dir / "alpha.png"
    normalized_path = out_dir / "normalized_256.png"
    preview_path = out_dir / "preview_64.png"
    metadata_path = out_dir / "metadata.json"

    shutil.copy2(input_path, original_path)

    source = Image.open(input_path).convert("RGBA")
    chroma_key = parse_hex_color(args.chroma_key) if args.chroma_key else None
    if chroma_key:
        alpha = remove_chroma_key(
            source,
            chroma_key,
            args.transparent_threshold,
            args.opaque_threshold,
        )
        alpha = neutralize_chroma_spill_image(alpha, chroma_key)
    else:
        alpha = source
    alpha.save(alpha_path)

    bbox = alpha_bbox(alpha)
    hard_gate_failures: list[str] = []
    if bbox is None:
        hard_gate_failures.append("empty_alpha_bbox")
        normalized = Image.new("RGBA", (args.cell_size, args.cell_size), (0, 0, 0, 0))
        packing = {
            "source_bbox": None,
            "cell_size": [args.cell_size, args.cell_size],
        }
    else:
        normalized, packing = pack_to_cell(alpha, bbox, args.cell_size, args.target_occupied_size)
        if chroma_key:
            normalized = neutralize_chroma_spill_image(normalized, chroma_key)

    normalized.save(normalized_path)
    preview = normalized.resize((args.preview_size, args.preview_size), Image.Resampling.LANCZOS)
    preview.save(preview_path)

    normalized_bbox = alpha_bbox(normalized)
    opaque_pixels = count_opaque_pixels(normalized)
    corner_alpha = [
        normalized.getpixel((0, 0))[3],
        normalized.getpixel((args.cell_size - 1, 0))[3],
        normalized.getpixel((0, args.cell_size - 1))[3],
        normalized.getpixel((args.cell_size - 1, args.cell_size - 1))[3],
    ]
    chroma_spill_pixels = count_chroma_spill_pixels(normalized, chroma_key)

    if normalized_bbox is None:
        hard_gate_failures.append("normalized_empty_alpha_bbox")
    if any(value > 0 for value in corner_alpha):
        hard_gate_failures.append("non_transparent_corners")
    if opaque_pixels < args.min_opaque_pixels:
        hard_gate_failures.append("too_few_opaque_pixels")
    if chroma_spill_pixels > args.max_chroma_spill_pixels:
        hard_gate_failures.append("too_many_chroma_spill_pixels")

    prompt_text = ""
    if args.prompt_file:
        prompt_path = Path(args.prompt_file)
        if not prompt_path.is_absolute():
            prompt_path = ROOT / prompt_path
        prompt_text = prompt_path.read_text(encoding="utf-8")

    metadata = {
        "asset_id": args.asset_id,
        "candidate_id": args.candidate_id,
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "provider": args.provider,
        "model": args.model,
        "action": "normalize_single_image_candidate",
        "prompt_pack": args.prompt_pack,
        "prompt_file": args.prompt_file,
        "prompt": prompt_text,
        "revised_prompt": args.revised_prompt,
        "source_refs": args.source_ref,
        "files": {
            "original_chromakey": relative_or_absolute(original_path),
            "alpha": relative_or_absolute(alpha_path),
            "normalized_256": relative_or_absolute(normalized_path),
            "preview_64": relative_or_absolute(preview_path),
        },
        "normalization": packing,
        "verification": {
            "hard_gate_passed": not hard_gate_failures,
            "hard_gate_failures": hard_gate_failures,
            "source_size": list(source.size),
            "alpha_bbox": list(bbox) if bbox is not None else None,
            "normalized_bbox": list(normalized_bbox) if normalized_bbox is not None else None,
            "opaque_pixels": opaque_pixels,
            "corner_alpha": corner_alpha,
            "chroma_spill_pixels": chroma_spill_pixels,
        },
    }
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(json.dumps({
        "metadata": relative_or_absolute(metadata_path),
        "hard_gate_passed": metadata["verification"]["hard_gate_passed"],
        "preview": relative_or_absolute(preview_path),
    }, ensure_ascii=False))
    return 0 if metadata["verification"]["hard_gate_passed"] else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    scan = subparsers.add_parser("scan", help="Scan main.gd asset refs.")
    scan.add_argument("--script", default="scripts/main.gd")
    scan.add_argument("--out")
    scan.set_defaults(func=command_scan)

    normalize = subparsers.add_parser("normalize-single-image", help="Normalize one generated single-image candidate.")
    normalize.add_argument("--asset-id", required=True)
    normalize.add_argument("--candidate-id", required=True)
    normalize.add_argument("--input", required=True)
    normalize.add_argument("--out-dir", required=True)
    normalize.add_argument("--prompt-file")
    normalize.add_argument("--prompt-pack", default="")
    normalize.add_argument("--source-ref", action="append", default=[])
    normalize.add_argument("--provider", default="built-in-imagegen")
    normalize.add_argument("--model", default="built-in")
    normalize.add_argument("--revised-prompt", default="")
    normalize.add_argument("--chroma-key", default="#ff00ff")
    normalize.add_argument("--transparent-threshold", type=int, default=28)
    normalize.add_argument("--opaque-threshold", type=int, default=112)
    normalize.add_argument("--cell-size", type=int, default=256)
    normalize.add_argument("--preview-size", type=int, default=64)
    normalize.add_argument("--target-occupied-size", type=int, default=224)
    normalize.add_argument("--min-opaque-pixels", type=int, default=2200)
    normalize.add_argument("--max-chroma-spill-pixels", type=int, default=120)
    normalize.set_defaults(func=command_normalize_single_image)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
