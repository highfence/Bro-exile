---
module: Godot Port
date: 2026-05-22
problem_type: ui_bug
component: tooling
symptoms:
  - "Godot UI panels and progress bars rendered, but all Label and Button text was invisible"
  - "The start overlay layout looked wrong because text controls collapsed while the button background still rendered"
  - "SystemFont and FontFile attempts did not make text appear in captured Godot output"
root_cause: incomplete_setup
resolution_type: code_fix
severity: medium
tags: [godot, ui-text, font-rendering, pixel-ui, canvaslayer]
---

# Troubleshooting: Invisible Godot UI Text In Prototype Builds

## Problem

The Godot port of Orebound Arena launched successfully and rendered the arena, panels, buttons, and progress bars, but no UI text appeared. The user saw a visually broken interface: blank panels, blank HUD labels, and a start button with only the colored background visible.

## Environment

- Module: Godot Port
- Engine: Godot Engine v4.6.1.stable.custom_build.14d19694e
- Affected Component: GDScript-built `CanvasLayer` HUD and overlay UI
- Date: 2026-05-22
- Files involved:
  - `scripts/main.gd`
  - `scripts/pixel_ui.gd`

## Symptoms

- Godot ran without immediate runtime errors.
- `PanelContainer`, `Button`, and `ProgressBar` backgrounds rendered.
- `Label` text, `Button` text, and `draw_string()` text were invisible.
- Captured output showed the HUD frame, bars, overlay panel, and button background, but no readable text.
- The overlay layout looked compressed because text controls effectively contributed no visible content.

## What Didn't Work

**Relying on the default Godot theme font**
- **Why it failed:** In this custom Godot build, default UI text did not render even though other Control visuals did.

**Adding explicit theme colors and font sizes to Labels and Buttons**
- **Why it failed:** The issue was not color contrast or missing style overrides. Text was still absent in actual captured output.

**Using `SystemFont` with common macOS font family names**
- **Why it failed:** The rendered capture still showed no text. Name-based system font selection was not enough for this environment.

**Loading macOS font files with `FontFile.load_dynamic_font()`**
- **Why it failed:** Even after loading concrete font file paths such as `/System/Library/Fonts/HelveticaNeue.ttc`, text remained invisible in the captured frame.

## Solution

Add a small pixel text overlay that draws UI text as rectangles through `CanvasItem.draw_rect()` instead of relying on Godot's font renderer. The original Control UI can remain for interaction and panel/button backgrounds, while the pixel overlay provides guaranteed visible text.

**Code changes:**

```gdscript
# scripts/pixel_ui.gd
extends Control

var game: Node

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    if game != null:
        game.draw_pixel_ui(self)
```

```gdscript
# scripts/main.gd
pixel_ui = Control.new()
pixel_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
pixel_ui.set_script(load("res://scripts/pixel_ui.gd"))
pixel_ui.set("game", self)
hud_layer.add_child(pixel_ui)
```

```gdscript
# scripts/main.gd
func _px_text(canvas: CanvasItem, text: String, pos: Vector2, scale: int, color: Color) -> void:
    var cursor := pos
    var upper := text.to_upper()
    for i in range(upper.length()):
        var ch := upper.substr(i, 1)
        if ch == " ":
            cursor.x += scale * 4
            continue
        var pattern: Array = PIXEL_FONT.get(ch, PIXEL_FONT[" "])
        for row in range(pattern.size()):
            var bits := str(pattern[row])
            for col in range(bits.length()):
                if bits.substr(col, 1) == "1":
                    canvas.draw_rect(
                        Rect2(cursor + Vector2(col * scale, row * scale), Vector2(scale, scale)),
                        color,
                        true
                    )
        cursor.x += scale * 4
```

The pixel UI renders:

- HUD text: title, HP, XP, wave, ore, timer
- Weapon strip text
- Start overlay title/body/button label
- Level-up and shop choice text
- Game-over summary text

## Verification

The fix was verified by adding a temporary command-line capture path in `scripts/main.gd`:

```gdscript
if OS.get_cmdline_user_args().has("--capture-ui"):
    _capture_ui_and_quit.call_deferred()
```

Then running:

```bash
/Users/highfence/Dev/Sweep/engine/godot/bin/godot.macos.editor.arm64 \
  --path /Users/highfence/Documents/Bro-exile \
  -- --capture-ui
```

The resulting `/private/tmp/orebound-godot-ui.png` showed readable HUD and overlay text drawn by the pixel UI layer.

## Why This Works

The root problem was not the game state or UI layout alone. Godot's font-backed text rendering path was unavailable or ineffective in the local custom engine build, while primitive rendering such as panels, bars, rectangles, and drawn shapes worked normally.

The pixel UI bypasses the font subsystem entirely. It stores each glyph as a tiny bitmap pattern and draws filled rectangles directly. Because it uses the same primitive drawing path already proven to work for the game scene and UI backgrounds, text becomes visible even when font resources fail.

This is a prototype-safe workaround. It is not a final localization-ready UI system, but it is reliable for early gameplay iteration.

## Prevention

- Do not assume the default Godot theme font renders correctly in custom or source-built engines.
- When building UI programmatically, capture or screenshot the actual rendered output, not just headless load success.
- For prototypes, keep a fallback debug/pixel text renderer available when font rendering or imported font resources are suspect.
- For production, add a bundled project font asset under `res://` and verify it renders in exported builds.
- Keep automated visual smoke checks for first-screen UI: title text, primary button text, HUD labels, and at least one dynamic value.

## Related Issues

No related issues documented yet.
