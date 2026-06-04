#!/usr/bin/env python3
"""Generate transparent PNG starter weapon icons for M1-D8."""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites" / "items" / "p8_weapons"
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
        for i, (xi, yi) in enumerate(points):
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


def rotated(points: list[tuple[float, float]], cx: float, cy: float, degrees: float) -> list[tuple[float, float]]:
    angle = math.radians(degrees)
    ca, sa = math.cos(angle), math.sin(angle)
    out = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        out.append((cx + dx * ca - dy * sa, cy + dx * sa + dy * ca))
    return out


def line_rotated(c: Canvas, a: tuple[float, float], b: tuple[float, float], cx: float, cy: float, degrees: float, width: float, color: tuple[int, int, int, int]) -> None:
    ra, rb = rotated([a, b], cx, cy, degrees)
    c.line(ra, rb, width, color)


def backplate(c: Canvas, glow: str) -> None:
    c.ellipse(128, 188, 76, 22, rgba("#000000", 40))
    c.circle(128, 124, 92, rgba("#111412"))
    c.circle(128, 124, 82, rgba("#252821"))
    c.circle(92, 84, 16, rgba(glow, 68))
    c.circle(83, 75, 6, rgba("#f5efe3", 120))


def icon_pickaxe() -> Canvas:
    c = Canvas()
    backplate(c, "#f2cf66")
    cx, cy, angle = 128, 128, -34
    line_rotated(c, (118, 66), (118, 198), cx, cy, angle, 20, rgba("#111412"))
    line_rotated(c, (118, 74), (118, 190), cx, cy, angle, 12, rgba("#7a4b2a"))
    head = [(50, 96), (111, 70), (200, 82), (210, 103), (120, 99), (72, 124)]
    edge = [(58, 99), (112, 80), (190, 90), (196, 99), (119, 93), (76, 115)]
    c.polygon(rotated(head, cx, cy, angle), rgba("#111412"))
    c.polygon(rotated(edge, cx, cy, angle), rgba("#d8ceb9"))
    line_rotated(c, (83, 108), (178, 93), cx, cy, angle, 4, rgba("#f5efe3", 150))
    c.circle(160, 72, 9, rgba("#f2cf66", 150))
    return c


def icon_nailgun() -> Canvas:
    c = Canvas()
    backplate(c, "#d8f3ff")
    body = [(65, 96), (167, 82), (199, 106), (189, 135), (88, 140), (61, 123)]
    c.polygon(body, rgba("#111412"))
    c.polygon([(76, 101), (160, 91), (187, 109), (179, 128), (91, 131), (72, 120)], rgba("#6e7d83"))
    c.rect(96, 132, 24, 54, rgba("#111412"))
    c.rect(102, 135, 15, 43, rgba("#7a4b2a"))
    c.rect(173, 97, 50, 15, rgba("#111412"))
    c.rect(177, 100, 42, 8, rgba("#d8f3ff"))
    for x in (83, 103, 123):
        c.line((x, 113), (x + 22, 110), 3, rgba("#d8f3ff", 140))
    c.line((216, 104), (238, 98), 4, rgba("#f5efe3", 170))
    c.circle(66, 94, 8, rgba("#f2cf66", 130))
    return c


def icon_lantern() -> Canvas:
    c = Canvas()
    backplate(c, "#e6b85c")
    c.line((91, 73), (128, 50), 8, rgba("#111412"))
    c.line((128, 50), (165, 73), 8, rgba("#111412"))
    c.line((96, 75), (160, 75), 8, rgba("#d8ceb9"))
    c.rect(90, 100, 76, 70, rgba("#111412"))
    c.rect(99, 107, 58, 54, rgba("#7a4b2a"))
    c.circle(128, 133, 31, rgba("#e6b85c", 210))
    c.circle(128, 133, 18, rgba("#f5efe3", 170))
    c.rect(102, 91, 52, 16, rgba("#111412"))
    c.rect(108, 94, 40, 8, rgba("#d8ceb9"))
    c.rect(103, 166, 50, 12, rgba("#111412"))
    c.line((87, 112), (68, 96), 7, rgba("#111412"))
    c.line((169, 112), (188, 96), 7, rgba("#111412"))
    for radius, alpha in ((62, 46), (82, 26)):
        c.circle(128, 133, radius, rgba("#e6b85c", alpha))
    return c


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    icons = {
        "weapon_pickaxe.png": icon_pickaxe(),
        "weapon_nailgun.png": icon_nailgun(),
        "weapon_lantern.png": icon_lantern(),
    }
    for name, canvas in icons.items():
        write_png(OUT_DIR / name, SIZE, SIZE, canvas.downsample_rgba())
    print(f"Generated {len(icons)} icons in {OUT_DIR}")


if __name__ == "__main__":
    main()
