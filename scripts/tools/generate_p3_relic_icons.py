#!/usr/bin/env python3
"""Generate simple pixel relic PNGs for the P3 relic contract prototype."""

from __future__ import annotations

import json
import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites" / "items" / "p3_relics"
GRID = 64
SCALE = 4
SIZE = GRID * SCALE


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_color.lstrip("#")
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha


class PixelCanvas:
    def __init__(self, grid: int = GRID) -> None:
        self.grid = grid
        self.pixels = bytearray(grid * grid * 4)

    def blend_pixel(self, x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if x < 0 or y < 0 or x >= self.grid or y >= self.grid:
            return
        r, g, b, a = color
        if a <= 0:
            return
        index = (y * self.grid + x) * 4
        dr, dg, db, da = self.pixels[index:index + 4]
        src_a = a / 255.0
        dst_a = da / 255.0
        out_a = src_a + dst_a * (1.0 - src_a)
        if out_a <= 0.0:
            return
        self.pixels[index] = int((r * src_a + dr * dst_a * (1.0 - src_a)) / out_a)
        self.pixels[index + 1] = int((g * src_a + dg * dst_a * (1.0 - src_a)) / out_a)
        self.pixels[index + 2] = int((b * src_a + db * dst_a * (1.0 - src_a)) / out_a)
        self.pixels[index + 3] = int(out_a * 255)

    def rect(self, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int]) -> None:
        for py in range(y, y + h):
            for px in range(x, x + w):
                self.blend_pixel(px, py, color)

    def circle(self, cx: int, cy: int, radius: int, color: tuple[int, int, int, int]) -> None:
        rr = radius * radius
        for y in range(cy - radius, cy + radius + 1):
            for x in range(cx - radius, cx + radius + 1):
                dx = x - cx
                dy = y - cy
                if dx * dx + dy * dy <= rr:
                    self.blend_pixel(x, y, color)

    def ellipse(self, cx: int, cy: int, rx: int, ry: int, color: tuple[int, int, int, int]) -> None:
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                dx = (x - cx) / max(1, rx)
                dy = (y - cy) / max(1, ry)
                if dx * dx + dy * dy <= 1.0:
                    self.blend_pixel(x, y, color)

    def line(self, a: tuple[int, int], b: tuple[int, int], width: int, color: tuple[int, int, int, int]) -> None:
        ax, ay = a
        bx, by = b
        dx = bx - ax
        dy = by - ay
        steps = max(abs(dx), abs(dy), 1)
        half = max(0, width // 2)
        for i in range(steps + 1):
            t = i / steps
            x = round(ax + dx * t)
            y = round(ay + dy * t)
            self.rect(x - half, y - half, width, width, color)

    def polygon(self, points: list[tuple[int, int]], color: tuple[int, int, int, int]) -> None:
        min_x = max(0, min(x for x, _ in points))
        max_x = min(self.grid - 1, max(x for x, _ in points))
        min_y = max(0, min(y for _, y in points))
        max_y = min(self.grid - 1, max(y for _, y in points))
        for y in range(min_y, max_y + 1):
            for x in range(min_x, max_x + 1):
                if inside_polygon(x, y, points):
                    self.blend_pixel(x, y, color)

    def paste(self, other: "PixelCanvas", x_offset: int, y_offset: int = 0) -> None:
        for y in range(other.grid):
            for x in range(other.grid):
                index = (y * other.grid + x) * 4
                color = tuple(other.pixels[index:index + 4])
                self.blend_pixel(x + x_offset, y + y_offset, color)  # type: ignore[arg-type]

    def scaled_rgba(self) -> bytes:
        out = bytearray(self.grid * SCALE * self.grid * SCALE * 4)
        out_width = self.grid * SCALE
        for y in range(self.grid):
            for x in range(self.grid):
                index = (y * self.grid + x) * 4
                color = self.pixels[index:index + 4]
                for sy in range(SCALE):
                    for sx in range(SCALE):
                        out_index = (((y * SCALE + sy) * out_width) + (x * SCALE + sx)) * 4
                        out[out_index:out_index + 4] = color
        return bytes(out)


def inside_polygon(x: int, y: int, points: list[tuple[int, int]]) -> bool:
    inside = False
    j = len(points) - 1
    for i in range(len(points)):
        xi, yi = points[i]
        xj, yj = points[j]
        if (yi > y) != (yj > y):
            x_at_y = (xj - xi) * (y - yi) / max(1, yj - yi) + xi
            if x < x_at_y:
                inside = not inside
        j = i
    return inside


def write_png(path: Path, width: int, height: int, rgba_bytes: bytes) -> None:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    rows = bytearray()
    stride = width * 4
    for y in range(height):
        rows.append(0)
        rows.extend(rgba_bytes[y * stride:(y + 1) * stride])
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(rows), 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


def back_relic(c: PixelCanvas, glow: str = "#e6b85c") -> None:
    c.ellipse(32, 52, 19, 5, rgba("#000000", 70))
    c.circle(32, 32, 24, rgba("#111412"))
    c.circle(32, 32, 21, rgba("#252821"))
    c.circle(24, 20, 5, rgba("#f5efe3", 90))
    c.circle(45, 22, 4, rgba(glow, 95))


def icon_spider_egg_fossil() -> PixelCanvas:
    c = PixelCanvas()
    back_relic(c, "#93c96d")
    c.ellipse(32, 34, 17, 20, rgba("#111412"))
    c.ellipse(32, 34, 13, 16, rgba("#7d877a"))
    c.ellipse(32, 34, 9, 12, rgba("#d8ceb9"))
    c.line((24, 30), (17, 26), 2, rgba("#111412"))
    c.line((24, 36), (16, 39), 2, rgba("#111412"))
    c.line((40, 30), (47, 26), 2, rgba("#111412"))
    c.line((40, 36), (48, 39), 2, rgba("#111412"))
    c.line((29, 22), (35, 29), 2, rgba("#5b3924"))
    c.line((36, 35), (29, 45), 2, rgba("#5b3924"))
    c.circle(25, 25, 2, rgba("#93c96d"))
    c.circle(42, 42, 2, rgba("#93c96d"))
    return c


def icon_hungry_lantern() -> PixelCanvas:
    c = PixelCanvas()
    back_relic(c, "#f0643b")
    c.rect(24, 13, 16, 5, rgba("#111412"))
    c.rect(28, 9, 8, 5, rgba("#7d5030"))
    c.rect(21, 18, 22, 31, rgba("#111412"))
    c.rect(24, 21, 16, 25, rgba("#6b3e22"))
    c.rect(27, 24, 10, 14, rgba("#e6b85c"))
    c.rect(29, 27, 6, 10, rgba("#f5d45c"))
    c.rect(25, 39, 4, 3, rgba("#111412"))
    c.rect(31, 39, 3, 3, rgba("#111412"))
    c.rect(36, 39, 4, 3, rgba("#111412"))
    c.line((18, 20), (12, 15), 2, rgba("#d87745"))
    c.line((45, 20), (51, 15), 2, rgba("#d87745"))
    return c


def icon_echoing_stone_heart() -> PixelCanvas:
    c = PixelCanvas()
    back_relic(c, "#6cc3c0")
    c.circle(25, 26, 9, rgba("#111412"))
    c.circle(39, 26, 9, rgba("#111412"))
    c.polygon([(16, 29), (32, 51), (48, 29), (42, 23), (32, 27), (22, 23)], rgba("#111412"))
    c.circle(25, 27, 6, rgba("#7d877a"))
    c.circle(39, 27, 6, rgba("#7d877a"))
    c.polygon([(21, 30), (32, 45), (43, 30), (38, 27), (32, 31), (26, 27)], rgba("#5c665c"))
    c.line((25, 21), (33, 31), 2, rgba("#2f332a"))
    c.line((33, 31), (29, 38), 2, rgba("#2f332a"))
    for offset in [0, 5, 10]:
        c.line((12 - offset, 25), (8 - offset, 32), 1, rgba("#6cc3c0", 140))
        c.line((52 + offset, 25), (56 + offset, 32), 1, rgba("#6cc3c0", 140))
    return c


def icon_red_vein_sample() -> PixelCanvas:
    c = PixelCanvas()
    back_relic(c, "#f0643b")
    c.polygon([(22, 14), (45, 22), (41, 50), (17, 43)], rgba("#111412"))
    c.polygon([(25, 18), (41, 23), (38, 45), (21, 40)], rgba("#5b3924"))
    c.line((24, 21), (38, 30), 3, rgba("#c53b35"))
    c.line((34, 28), (28, 42), 3, rgba("#f0643b"))
    c.line((28, 25), (25, 34), 2, rgba("#e6b85c"))
    c.polygon([(43, 19), (51, 27), (45, 31)], rgba("#111412"))
    c.polygon([(44, 21), (48, 27), (45, 28)], rgba("#6cc3c0"))
    c.rect(17, 44, 24, 4, rgba("#2f332a"))
    return c


def icon_black_shell_relic() -> PixelCanvas:
    c = PixelCanvas()
    back_relic(c, "#d8ceb9")
    c.polygon([(19, 41), (36, 13), (46, 19), (31, 49)], rgba("#111412"))
    c.polygon([(23, 40), (37, 18), (42, 21), (30, 45)], rgba("#2f332a"))
    c.rect(20, 42, 13, 8, rgba("#111412"))
    c.rect(22, 43, 9, 5, rgba("#7d5030"))
    c.line((31, 29), (39, 34), 2, rgba("#d8ceb9"))
    c.line((34, 23), (42, 28), 2, rgba("#d8ceb9"))
    c.circle(42, 21, 2, rgba("#f5efe3", 140))
    return c


def icon_twin_excavation_seal() -> PixelCanvas:
    c = PixelCanvas()
    back_relic(c, "#e6b85c")
    c.circle(32, 33, 18, rgba("#111412"))
    c.circle(32, 33, 14, rgba("#7d5030"))
    c.circle(32, 33, 9, rgba("#e6b85c"))
    c.line((21, 44), (43, 22), 3, rgba("#111412"))
    c.line((21, 44), (43, 22), 1, rgba("#d8ceb9"))
    c.line((43, 44), (21, 22), 3, rgba("#111412"))
    c.line((43, 44), (21, 22), 1, rgba("#d8ceb9"))
    c.polygon([(39, 18), (49, 17), (44, 24)], rgba("#111412"))
    c.polygon([(39, 46), (49, 47), (44, 40)], rgba("#111412"))
    c.rect(30, 30, 5, 5, rgba("#111412"))
    c.rect(31, 31, 3, 3, rgba("#6cc3c0"))
    return c


def icon_unstable_blast_crystal() -> PixelCanvas:
    c = PixelCanvas()
    back_relic(c, "#d87745")
    c.polygon([(32, 10), (47, 28), (39, 51), (22, 51), (15, 28)], rgba("#111412"))
    c.polygon([(32, 15), (42, 29), (36, 46), (25, 46), (20, 29)], rgba("#d87745"))
    c.polygon([(33, 18), (40, 30), (34, 42), (31, 29)], rgba("#f0643b"))
    c.line((29, 22), (34, 31), 2, rgba("#f5d45c"))
    c.line((34, 31), (29, 41), 2, rgba("#111412"))
    for x, y in [(14, 18), (50, 20), (49, 47), (17, 48)]:
        c.rect(x, y, 2, 2, rgba("#f5d45c"))
    c.line((47, 13), (53, 8), 2, rgba("#f0643b"))
    c.line((15, 16), (9, 10), 2, rgba("#f0643b"))
    return c


ICONS = {
    "relic_spider_egg_fossil": {
        "file": "relic_spider_egg_fossil.png",
        "name_ko": "거미 알 화석",
        "factory": icon_spider_egg_fossil,
    },
    "relic_hungry_lantern": {
        "file": "relic_hungry_lantern.png",
        "name_ko": "굶주린 등불",
        "factory": icon_hungry_lantern,
    },
    "relic_echoing_stone_heart": {
        "file": "relic_echoing_stone_heart.png",
        "name_ko": "메아리나는 돌심장",
        "factory": icon_echoing_stone_heart,
    },
    "relic_red_vein_sample": {
        "file": "relic_red_vein_sample.png",
        "name_ko": "붉은 광맥 표본",
        "factory": icon_red_vein_sample,
    },
    "relic_black_shell": {
        "file": "relic_black_shell.png",
        "name_ko": "검은 탄피 유물",
        "factory": icon_black_shell_relic,
    },
    "relic_twin_excavation_seal": {
        "file": "relic_twin_excavation_seal.png",
        "name_ko": "쌍둥이 굴착 인장",
        "factory": icon_twin_excavation_seal,
    },
    "relic_unstable_blast_crystal": {
        "file": "relic_unstable_blast_crystal.png",
        "name_ko": "불안정한 폭약 결정",
        "factory": icon_unstable_blast_crystal,
    },
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    files = {}
    preview = PixelCanvas(grid=GRID * len(ICONS))

    for index, (id, spec) in enumerate(ICONS.items()):
        icon = spec["factory"]()
        file = spec["file"]
        write_png(OUT_DIR / file, SIZE, SIZE, icon.scaled_rgba())
        preview.paste(icon, index * GRID)
        files[id] = {
            "name_ko": spec["name_ko"],
            "file": file,
            "path": "res://assets/sprites/items/p3_relics/%s" % file,
        }

    write_png(OUT_DIR / "p3_relic_icons_preview.png", SIZE * len(ICONS), SIZE, preview.scaled_rgba())
    metadata = {
        "purpose": "P3 relic contract prototype icons.",
        "size": [SIZE, SIZE],
        "source_grid": [GRID, GRID],
        "style_notes": [
            "original pixel relic icons",
            "dark mine fantasy, thick silhouette, readable at HUD size",
            "inspired by roguelike relic readability, not a direct copy of any game's assets",
        ],
        "files": files,
    }
    (OUT_DIR / "metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
