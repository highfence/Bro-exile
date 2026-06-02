#!/usr/bin/env python3
"""Generate small transparent PNG part icons for the P2 shop prototype."""

from __future__ import annotations

import json
import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites" / "items" / "p2_parts"
SIZE = 256
SCALE = 4


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_color.lstrip("#")
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha


class Canvas:
    def __init__(self, size: int = SIZE, scale: int = SCALE) -> None:
        self.size = size
        self.scale = scale
        self.width = size * scale
        self.height = size * scale
        self.pixels = bytearray(self.width * self.height * 4)

    def _sx(self, value: float) -> int:
        return int(round(value * self.scale))

    def _blend(self, x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if x < 0 or y < 0 or x >= self.width or y >= self.height:
            return
        r, g, b, a = color
        if a <= 0:
            return
        index = (y * self.width + x) * 4
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

    def circle(self, cx: float, cy: float, radius: float, color: tuple[int, int, int, int]) -> None:
        cx_s, cy_s, r_s = self._sx(cx), self._sx(cy), self._sx(radius)
        rr = r_s * r_s
        for y in range(cy_s - r_s, cy_s + r_s + 1):
            dy = y - cy_s
            for x in range(cx_s - r_s, cx_s + r_s + 1):
                dx = x - cx_s
                if dx * dx + dy * dy <= rr:
                    self._blend(x, y, color)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, color: tuple[int, int, int, int]) -> None:
        cx_s, cy_s, rx_s, ry_s = self._sx(cx), self._sx(cy), self._sx(rx), self._sx(ry)
        for y in range(cy_s - ry_s, cy_s + ry_s + 1):
            dy = (y - cy_s) / max(1, ry_s)
            for x in range(cx_s - rx_s, cx_s + rx_s + 1):
                dx = (x - cx_s) / max(1, rx_s)
                if dx * dx + dy * dy <= 1.0:
                    self._blend(x, y, color)

    def rect(self, x: float, y: float, w: float, h: float, color: tuple[int, int, int, int]) -> None:
        x0, y0, x1, y1 = self._sx(x), self._sx(y), self._sx(x + w), self._sx(y + h)
        for py in range(y0, y1):
            for px in range(x0, x1):
                self._blend(px, py, color)

    def rounded_rect(self, x: float, y: float, w: float, h: float, radius: float, color: tuple[int, int, int, int]) -> None:
        self.rect(x + radius, y, w - radius * 2, h, color)
        self.rect(x, y + radius, w, h - radius * 2, color)
        self.circle(x + radius, y + radius, radius, color)
        self.circle(x + w - radius, y + radius, radius, color)
        self.circle(x + radius, y + h - radius, radius, color)
        self.circle(x + w - radius, y + h - radius, radius, color)

    def polygon(self, points: list[tuple[float, float]], color: tuple[int, int, int, int]) -> None:
        pts = [(self._sx(x), self._sx(y)) for x, y in points]
        min_x = max(0, min(x for x, _ in pts))
        max_x = min(self.width - 1, max(x for x, _ in pts))
        min_y = max(0, min(y for _, y in pts))
        max_y = min(self.height - 1, max(y for _, y in pts))
        for y in range(min_y, max_y + 1):
            for x in range(min_x, max_x + 1):
                if self._inside_polygon(x, y, pts):
                    self._blend(x, y, color)

    def line(self, a: tuple[float, float], b: tuple[float, float], width: float, color: tuple[int, int, int, int]) -> None:
        ax, ay = self._sx(a[0]), self._sx(a[1])
        bx, by = self._sx(b[0]), self._sx(b[1])
        half = max(1, self._sx(width) / 2.0)
        min_x = max(0, int(min(ax, bx) - half - 1))
        max_x = min(self.width - 1, int(max(ax, bx) + half + 1))
        min_y = max(0, int(min(ay, by) - half - 1))
        max_y = min(self.height - 1, int(max(ay, by) + half + 1))
        dx, dy = bx - ax, by - ay
        length_sq = max(1, dx * dx + dy * dy)
        for y in range(min_y, max_y + 1):
            for x in range(min_x, max_x + 1):
                t = max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / length_sq))
                px = ax + dx * t
                py = ay + dy * t
                if (x - px) ** 2 + (y - py) ** 2 <= half * half:
                    self._blend(x, y, color)

    def copy_from(self, other: "Canvas", x: int, y: int) -> None:
        for py in range(other.height):
            for px in range(other.width):
                index = (py * other.width + px) * 4
                color = tuple(other.pixels[index:index + 4])
                self._blend(x * self.scale + px, y * self.scale + py, color)  # type: ignore[arg-type]

    def downsample_rgba(self) -> bytes:
        out = bytearray(self.size * self.size * 4)
        area = self.scale * self.scale
        for y in range(self.size):
            for x in range(self.size):
                totals = [0, 0, 0, 0]
                for yy in range(self.scale):
                    for xx in range(self.scale):
                        index = (((y * self.scale + yy) * self.width) + (x * self.scale + xx)) * 4
                        for i in range(4):
                            totals[i] += self.pixels[index + i]
                out_index = (y * self.size + x) * 4
                for i in range(4):
                    out[out_index + i] = int(totals[i] / area)
        return bytes(out)

    @staticmethod
    def _inside_polygon(x: int, y: int, points: list[tuple[int, int]]) -> bool:
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


def points_rotated(points: list[tuple[float, float]], cx: float, cy: float, degrees: float) -> list[tuple[float, float]]:
    angle = math.radians(degrees)
    ca, sa = math.cos(angle), math.sin(angle)
    out = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        out.append((cx + dx * ca - dy * sa, cy + dx * sa + dy * ca))
    return out


def line_rotated(c: Canvas, a: tuple[float, float], b: tuple[float, float], cx: float, cy: float, degrees: float, width: float, color: tuple[int, int, int, int]) -> None:
    ra, rb = points_rotated([a, b], cx, cy, degrees)
    c.line(ra, rb, width, color)


def backplate(c: Canvas, glow: str = "#e6b85c") -> None:
    c.ellipse(130, 178, 78, 28, rgba("#000000", 42))
    c.circle(128, 124, 92, rgba("#111412"))
    c.circle(128, 124, 82, rgba("#252821"))
    c.circle(103, 92, 27, rgba(glow, 56))
    c.circle(86, 74, 10, rgba("#f5efe3", 116))


def drill_tip(c: Canvas, accent: str = "#93c96d", angle: float = -18.0, carbide: bool = False) -> None:
    cx, cy = 128, 128
    outer = [(54, 148), (162, 70), (214, 128), (162, 186)]
    inner = [(72, 145), (158, 86), (195, 128), (158, 170)]
    c.polygon(points_rotated(outer, cx, cy, angle), rgba("#111412"))
    c.polygon(points_rotated(inner, cx, cy, angle), rgba("#d8ceb9" if not carbide else "#6cc3c0"))
    for offset in [105, 130, 155]:
        line_rotated(c, (offset, 88), (offset + 30, 168), cx, cy, angle, 7, rgba("#111412"))
        line_rotated(c, (offset + 2, 96), (offset + 23, 160), cx, cy, angle, 3, rgba("#7d877a"))
    c.polygon(points_rotated([(52, 150), (78, 131), (83, 156), (65, 175)], cx, cy, angle), rgba("#6b3e22"))
    c.polygon(points_rotated([(183, 107), (213, 128), (183, 149), (195, 128)], cx, cy, angle), rgba(accent))
    if carbide:
        line_rotated(c, (108, 108), (151, 148), cx, cy, angle, 4, rgba("#f5efe3", 170))
        c.circle(181, 90, 10, rgba("#6cc3c0"))


def icon_piercing_bit() -> Canvas:
    c = Canvas()
    backplate(c, "#93c96d")
    drill_tip(c, "#93c96d")
    c.circle(70, 72, 8, rgba("#6cc3c0"))
    c.circle(86, 59, 5, rgba("#f5efe3"))
    return c


def icon_carbide_tip() -> Canvas:
    c = Canvas()
    backplate(c, "#6cc3c0")
    drill_tip(c, "#6cc3c0", -28.0, True)
    c.line((70, 181), (96, 164), 5, rgba("#111412"))
    c.line((74, 181), (98, 166), 2, rgba("#6cc3c0"))
    return c


def icon_rapid_trigger() -> Canvas:
    c = Canvas()
    backplate(c, "#f0643b")
    c.circle(90, 126, 39, rgba("#111412"))
    c.circle(90, 126, 29, rgba("#5b3924"))
    c.circle(90, 126, 14, rgba("#e6b85c"))
    c.rounded_rect(94, 102, 86, 54, 15, rgba("#111412"))
    c.rounded_rect(104, 111, 66, 34, 10, rgba("#a7652e"))
    c.line((151, 146), (142, 176), 13, rgba("#111412"))
    c.line((151, 146), (144, 172), 7, rgba("#2f332a"))
    c.polygon([(171, 61), (151, 108), (179, 103), (164, 156), (207, 88), (177, 95)], rgba("#111412"))
    c.polygon([(172, 72), (158, 102), (183, 98), (172, 132), (198, 91), (174, 96)], rgba("#f5d45c"))
    c.circle(122, 114, 7, rgba("#f5efe3", 150))
    return c


def icon_shatter_charge() -> Canvas:
    c = Canvas()
    backplate(c, "#d87745")
    for pts in [
        [(59, 72), (83, 89), (50, 96)],
        [(189, 61), (177, 96), (215, 85)],
        [(203, 174), (174, 166), (190, 204)],
        [(69, 186), (93, 159), (101, 199)],
    ]:
        c.polygon(pts, rgba("#111412"))
        cx = sum(x for x, _ in pts) / 3
        cy = sum(y for _, y in pts) / 3
        smaller = [(cx + (x - cx) * 0.7, cy + (y - cy) * 0.7) for x, y in pts]
        c.polygon(smaller, rgba("#f5d45c"))
    c.circle(128, 130, 54, rgba("#111412"))
    c.circle(128, 130, 43, rgba("#d87745"))
    c.circle(108, 112, 12, rgba("#f5efe3", 138))
    c.line((158, 92), (181, 64), 10, rgba("#111412"))
    c.line((158, 92), (179, 67), 5, rgba("#7d5030"))
    c.circle(186, 60, 9, rgba("#f0643b"))
    c.circle(190, 56, 4, rgba("#f5d45c"))
    return c


def icon_long_barrel() -> Canvas:
    c = Canvas()
    backplate(c, "#d8ceb9")
    cx, cy, angle = 128, 128, -22.0
    line_rotated(c, (54, 132), (204, 132), cx, cy, angle, 34, rgba("#111412"))
    line_rotated(c, (58, 132), (199, 132), cx, cy, angle, 22, rgba("#7d877a"))
    line_rotated(c, (64, 124), (190, 124), cx, cy, angle, 4, rgba("#f5efe3", 120))
    for x in [91, 139]:
        c.polygon(points_rotated([(x, 109), (x + 17, 109), (x + 17, 155), (x, 155)], cx, cy, angle), rgba("#111412"))
        c.polygon(points_rotated([(x + 4, 115), (x + 13, 115), (x + 13, 149), (x + 4, 149)], cx, cy, angle), rgba("#e6b85c"))
    c.circle(199, 76, 8, rgba("#6cc3c0"))
    return c


def icon_spring_boots() -> Canvas:
    c = Canvas()
    backplate(c, "#a7652e")
    c.polygon([(70, 123), (122, 107), (166, 127), (180, 151), (136, 162), (80, 154)], rgba("#111412"))
    c.polygon([(83, 126), (123, 116), (157, 131), (166, 146), (134, 153), (88, 148)], rgba("#7d5030"))
    c.polygon([(122, 114), (159, 130), (148, 143), (115, 129)], rgba("#a7652e"))
    c.line((93, 157), (91, 196), 8, rgba("#111412"))
    c.line((143, 160), (142, 199), 8, rgba("#111412"))
    for x in [93, 143]:
        y0 = 162
        points = [(x, y0), (x + 16, y0 + 8), (x - 9, y0 + 17), (x + 14, y0 + 27), (x - 5, y0 + 36)]
        for a, b in zip(points, points[1:]):
            c.line(a, b, 5, rgba("#d8ceb9"))
            c.line(a, b, 2, rgba("#111412", 80))
    c.circle(112, 128, 8, rgba("#f5efe3", 120))
    return c


def icon_rations() -> Canvas:
    c = Canvas()
    backplate(c, "#e6b85c")
    c.rounded_rect(72, 75, 112, 116, 24, rgba("#111412"))
    c.rounded_rect(84, 86, 88, 94, 18, rgba("#7d5030"))
    c.rounded_rect(92, 98, 72, 55, 13, rgba("#a7652e"))
    c.rect(118, 105, 20, 42, rgba("#f5efe3"))
    c.rect(107, 116, 42, 20, rgba("#f5efe3"))
    c.line((92, 161), (162, 161), 5, rgba("#5b3924"))
    c.circle(100, 101, 7, rgba("#f5efe3", 108))
    return c


ICONS = {
    "part_rapid_trigger.png": icon_rapid_trigger,
    "part_piercing_bit.png": icon_piercing_bit,
    "part_shatter_charge.png": icon_shatter_charge,
    "part_long_barrel.png": icon_long_barrel,
    "part_spring_boots.png": icon_spring_boots,
    "part_carbide_tip.png": icon_carbide_tip,
    "part_rations.png": icon_rations,
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    generated: dict[str, str] = {}
    preview = Canvas(size=SIZE * len(ICONS), scale=1)
    for index, (filename, factory) in enumerate(ICONS.items()):
        icon = factory()
        data = icon.downsample_rgba()
        write_png(OUT_DIR / filename, SIZE, SIZE, data)
        generated[filename.removesuffix(".png")] = filename
        small = Canvas(size=SIZE, scale=1)
        small.pixels = bytearray(data)
        preview.copy_from(small, index * SIZE, 0)
    write_png(OUT_DIR / "p2_part_icons_preview.png", SIZE * len(ICONS), SIZE, preview.downsample_rgba())
    metadata = {
        "purpose": "P2 shop part icons for the drill-tip weapon loop.",
        "size": [SIZE, SIZE],
        "style_notes": [
            "transparent PNG",
            "thick dark outline",
            "yellow hard-hat, brown leather, steel, and teal ore accents",
            "readable at 48-64px",
        ],
        "files": generated,
    }
    (OUT_DIR / "metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
