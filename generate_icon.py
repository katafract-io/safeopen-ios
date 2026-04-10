#!/usr/bin/env python3
"""SafeOpen app icon generator — 1024x1024 PNG
Design: Three QR finder patterns (top-left, top-right, bottom-left) arranged in classic
QR positions on a deep navy background, with data dot fill in the bottom-right quadrant.
Accent: #00D4FF cyan. Glow overlay via screen blend.
"""

from PIL import Image, ImageDraw, ImageFilter, ImageChops
import sys, math

SIZE   = 1024
CX = CY = SIZE // 2

# Palette
BG         = (6,  9, 22)          # deep navy
BG_CENTER  = (12, 18, 48)         # slightly lighter center for gradient
CYAN       = (0, 212, 255)        # #00D4FF accent
CYAN_DIM   = (0, 100, 140)        # dimmer cyan for data dots


def radial_gradient(draw: ImageDraw.ImageDraw):
    """Paint a subtle radial gradient from BG_CENTER to BG."""
    for r in range(CX, 0, -3):
        t = (r / CX) ** 1.8
        c = tuple(int(a * t + b * (1 - t)) for a, b in zip(BG, BG_CENTER))
        draw.ellipse([CX - r, CY - r, CX + r, CY + r], fill=c)


def draw_finder(draw: ImageDraw.ImageDraw, x: int, y: int, cell: int):
    """Draw a 7×7 QR finder pattern (outer filled, 1-cell white gap, 3×3 inner filled)."""
    # outer
    draw.rectangle([x, y, x + 7*cell - 1, y + 7*cell - 1], fill=CYAN)
    # gap
    draw.rectangle([x + cell, y + cell, x + 6*cell - 1, y + 6*cell - 1], fill=BG)
    # inner
    draw.rectangle([x + 2*cell, y + 2*cell, x + 5*cell - 1, y + 5*cell - 1], fill=CYAN)


def draw_data_dots(draw: ImageDraw.ImageDraw, origin_x: int, origin_y: int,
                   cell: int, grid_cells: int):
    """Fill a grid_cells×grid_cells area with a pseudo-random dot pattern."""
    # Pattern: skip every other cell to mimic QR data
    DOT = max(cell - 8, 4)
    OFFSET = (cell - DOT) // 2
    pattern = [
        (0,0),(2,0),(4,0),(6,0),
        (1,1),(3,1),(5,1),
        (0,2),(2,2),(4,2),(5,2),
        (1,3),(3,3),(6,3),
        (0,4),(4,4),(6,4),
        (2,5),(3,5),(5,5),
        (1,6),(4,6),(6,6),
    ]
    for (col, row) in pattern:
        if col >= grid_cells or row >= grid_cells:
            continue
        x = origin_x + col * cell + OFFSET
        y = origin_y + row * cell + OFFSET
        draw.rectangle([x, y, x + DOT - 1, y + DOT - 1], fill=CYAN)


def draw_timing_strip(draw: ImageDraw.ImageDraw,
                      start_x: int, start_y: int,
                      length_cells: int, cell: int, vertical: bool):
    """Draw a timing pattern strip (alternating dots)."""
    DOT = max(cell - 10, 4)
    OFF = (cell - DOT) // 2
    for i in range(length_cells):
        if i % 2 == 0:
            if vertical:
                x = start_x + OFF
                y = start_y + i * cell + OFF
            else:
                x = start_x + i * cell + OFF
                y = start_y + OFF
            draw.rectangle([x, y, x + DOT - 1, y + DOT - 1], fill=CYAN)


def make_icon(out_path: str):
    img = Image.new("RGB", (SIZE, SIZE), BG)
    draw = ImageDraw.Draw(img)

    # Background
    radial_gradient(draw)

    # Layout: place 3 finders in standard QR positions
    # Each finder: 7 cells. Total QR grid: 21 cells (minimal QR) but we use 21-cell layout.
    # We'll use a 21-cell grid scaled to fill ~80% of the icon.
    GRID_CELLS = 21
    GRID_PX    = int(SIZE * 0.80)      # 819px
    CELL       = GRID_PX // GRID_CELLS  # 39px per cell
    GRID_PX    = CELL * GRID_CELLS     # recalculate exact (819px)
    MARGIN     = (SIZE - GRID_PX) // 2  # ~103px

    GX, GY = MARGIN, MARGIN            # grid origin

    # Three finders (col, row in grid units)
    draw_finder(draw, GX + 0 * CELL, GY + 0 * CELL, CELL)           # top-left
    draw_finder(draw, GX + 14 * CELL, GY + 0 * CELL, CELL)          # top-right
    draw_finder(draw, GX + 0 * CELL, GY + 14 * CELL, CELL)          # bottom-left

    # Timing strips (columns 6 and row 6, between finders)
    # Horizontal timing (row 6, from col 8 to col 12)
    draw_timing_strip(draw,
                      GX + 8 * CELL, GY + 6 * CELL,
                      6, CELL, vertical=False)
    # Vertical timing (col 6, from row 8 to row 12)
    draw_timing_strip(draw,
                      GX + 6 * CELL, GY + 8 * CELL,
                      6, CELL, vertical=True)

    # Data dots (bottom-right quadrant): rows 0–13, cols 8–20 + rows 8–20, cols 0–13
    # Right side data
    draw_data_dots(draw, GX + 9 * CELL, GY + 0 * CELL, CELL, 11)
    # Bottom data
    draw_data_dots(draw, GX + 0 * CELL, GY + 9 * CELL, CELL, 9)
    # Bottom-right large data block
    draw_data_dots(draw, GX + 9 * CELL, GY + 9 * CELL, CELL, 12)

    # Alignment pattern (bottom-right area, col 16, row 16 — standard QR v1+)
    AX = GX + 16 * CELL - 2 * CELL
    AY = GY + 16 * CELL - 2 * CELL
    AP_CELL = CELL
    # 5×5 alignment: outer filled, gap, center dot
    draw.rectangle([AX, AY, AX + 5*AP_CELL - 1, AY + 5*AP_CELL - 1], fill=CYAN)
    draw.rectangle([AX+AP_CELL, AY+AP_CELL, AX+4*AP_CELL-1, AY+4*AP_CELL-1], fill=BG)
    draw.rectangle([AX+2*AP_CELL, AY+2*AP_CELL, AX+3*AP_CELL-1, AY+3*AP_CELL-1], fill=CYAN)

    # ── Glow pass ──────────────────────────────────────────────────────────
    # Blur a copy to create a soft glow halo around bright elements
    glow = img.filter(ImageFilter.GaussianBlur(radius=22))
    # Screen blend: lightens where glow is bright
    result = ImageChops.screen(img, Image.blend(Image.new("RGB", (SIZE, SIZE), (0,0,0)), glow, 0.55))

    result.save(out_path, "PNG")
    print(f"Icon saved → {out_path}")


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png"
    make_icon(out)
