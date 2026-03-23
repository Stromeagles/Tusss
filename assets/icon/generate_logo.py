"""
AsisTus Wide Logo Generator v2 — Premium Quality
Renders at 2x then downscales for smooth anti-aliasing.
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

# Final output dimensions
FW, FH = 1200, 630
# Render at 2x for supersampling AA
SCALE = 2
W, H = FW * SCALE, FH * SCALE

# Colors
BG = (13, 17, 23, 255)
CYAN = (0, 212, 255)
CYAN_BRIGHT = (0, 240, 255)
CYAN_DIM = (0, 184, 212)
CYAN_DEEP = (0, 136, 163)
TEXT_PRIMARY = (240, 246, 252)
TEXT_SECONDARY = (123, 139, 163)
PURPLE = (168, 85, 247)
SHIELD_DARK = (21, 29, 43)
SHIELD_MID = (30, 42, 58)
SHIELD_BORDER = (0, 229, 255)
WHITE_SOFT = (220, 235, 248)


def radial_glow(size, center, radius, color, intensity=0.3, power=1.5):
    """High quality radial glow."""
    layer = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for i in range(radius, 0, -2):
        alpha = int(intensity * 255 * (1 - (i / radius) ** power))
        if alpha < 1:
            continue
        cx, cy = center
        draw.ellipse([cx - i, cy - i, cx + i, cy + i],
                     fill=(color[0], color[1], color[2], min(alpha, 255)))
    return layer


def shield_path(cx, cy, w, h):
    """Generate classic heraldic shield — matches app_icon.png style.
    Wide rounded top, straight sides, gentle curve to soft bottom point."""
    pts = []
    n = 60  # smoothness

    top_y = cy - h * 0.72
    bot_y = cy + h * 0.85   # bottom point (not too sharp)
    corner_r = w * 0.22
    curve_start = cy + h * 0.15  # where sides start curving inward

    # === TOP-LEFT CORNER ARC ===
    for i in range(n + 1):
        a = math.pi + (math.pi / 2) * (i / n)
        x = cx - w + corner_r + math.cos(a) * corner_r
        y = top_y + corner_r + math.sin(a) * corner_r
        pts.append((x, y))

    # === TOP EDGE (flat) ===
    pts.append((cx + w - corner_r, top_y))

    # === TOP-RIGHT CORNER ARC ===
    for i in range(n + 1):
        a = -math.pi / 2 + (math.pi / 2) * (i / n)
        x = cx + w - corner_r + math.cos(a) * corner_r
        y = top_y + corner_r + math.sin(a) * corner_r
        pts.append((x, y))

    # === RIGHT SIDE: straight down to curve_start ===
    for i in range(n):
        t = i / n
        y = top_y + corner_r + t * (curve_start - top_y - corner_r)
        pts.append((cx + w, y))

    # === RIGHT SIDE: gentle S-curve to bottom point ===
    for i in range(n + 1):
        t = i / n
        # Cubic bezier approximation for gentle taper
        # Control: stays wide longer, then sweeps to center
        x = cx + w * (1 - t ** 1.8)  # stays wide, then narrows
        y = curve_start + t * (bot_y - curve_start)
        pts.append((x, y))

    # === BOTTOM POINT ===
    pts.append((cx, bot_y))

    # === LEFT SIDE: curve from bottom back up (mirror) ===
    for i in range(n + 1):
        t = i / n  # 0=bottom, 1=curve_start
        x = cx - w * (1 - (1 - t) ** 1.8)
        y = bot_y - t * (bot_y - curve_start)
        pts.append((x, y))

    # === LEFT SIDE: straight up ===
    for i in range(n):
        t = i / n
        y = curve_start - t * (curve_start - top_y - corner_r)
        pts.append((cx - w, y))

    return pts


def draw_shield_full(canvas, cx, cy, scale):
    """Draw premium shield with multiple layers."""
    s = scale
    w_outer = 115 * s
    h_outer = 130 * s

    # Outer border shield
    outer_pts = shield_path(cx, cy, w_outer, h_outer)
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # Border gradient effect — draw multiple layers
    d.polygon(outer_pts, fill=(*SHIELD_BORDER, 200))

    # Inner body (slightly smaller)
    w_inner = 106 * s
    h_inner = 121 * s
    inner_pts = shield_path(cx, cy, w_inner, h_inner)
    d.polygon(inner_pts, fill=(*SHIELD_DARK, 245))

    # Subtle highlight at top of shield
    w_high = 100 * s
    h_high = 115 * s
    high_pts = shield_path(cx, cy, w_high, h_high)

    # Create a gradient overlay for the top section
    grad_layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad_layer)
    gd.polygon(high_pts, fill=(*SHIELD_MID, 60))
    # Mask to only show top half
    top_mask_y = cy + 10 * s
    gd.rectangle([0, int(top_mask_y), canvas.size[0], canvas.size[1]], fill=(0, 0, 0, 0))
    layer.alpha_composite(grad_layer)

    # Inner subtle border line
    d2 = ImageDraw.Draw(layer)
    # Draw inner border as thin line
    for i in range(len(inner_pts) - 1):
        d2.line([inner_pts[i], inner_pts[i + 1]], fill=(*CYAN, 25), width=max(1, int(s)))
    d2.line([inner_pts[-1], inner_pts[0]], fill=(*CYAN, 25), width=max(1, int(s)))

    canvas.alpha_composite(layer)


def draw_book_premium(canvas, cx, cy, s):
    """Draw premium glowing book with refined details."""
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    pw = 48 * s  # page width
    ph_top = 38 * s
    ph_bot = 32 * s

    # Left page (slightly darker)
    left = [
        (cx - 5 * s, cy - ph_top),
        (cx - pw, cy - ph_top + 12 * s),
        (cx - pw, cy + ph_bot),
        (cx - 5 * s, cy + ph_bot - 3 * s),
    ]
    d.polygon(left, fill=(*CYAN, 190))

    # Right page (brighter)
    right = [
        (cx + 5 * s, cy - ph_top),
        (cx + pw, cy - ph_top + 12 * s),
        (cx + pw, cy + ph_bot),
        (cx + 5 * s, cy + ph_bot - 3 * s),
    ]
    d.polygon(right, fill=(*CYAN_BRIGHT, 210))

    # Spine highlight
    d.line([(cx, cy - ph_top - 3 * s), (cx, cy + ph_bot)],
           fill=(*WHITE_SOFT, 200), width=max(2, int(2.5 * s)))

    # Page text lines — left
    for offset in [-18, -5, 8]:
        y = cy + offset * s
        d.line([(cx - 16 * s, y - 1 * s), (cx - 40 * s, y + 2 * s)],
               fill=(13, 17, 23, 65), width=max(1, int(1.5 * s)))

    # Page text lines — right
    for offset in [-18, -5, 8]:
        y = cy + offset * s
        d.line([(cx + 16 * s, y - 1 * s), (cx + 40 * s, y + 2 * s)],
               fill=(13, 17, 23, 65), width=max(1, int(1.5 * s)))

    # Book cover edges (thicker, more visible)
    cover_offset = 3 * s
    d.line([(cx - pw - cover_offset, cy - ph_top + 10 * s),
            (cx - pw - cover_offset, cy + ph_bot + 2 * s)],
           fill=(*CYAN_DIM, 140), width=max(2, int(2.5 * s)))
    d.line([(cx + pw + cover_offset, cy - ph_top + 10 * s),
            (cx + pw + cover_offset, cy + ph_bot + 2 * s)],
           fill=(*CYAN_DIM, 140), width=max(2, int(2.5 * s)))

    # Bottom curve of pages
    for i in range(int(-pw), int(pw), 2):
        x = cx + i
        curve = 4 * s * math.sin(math.pi * (i + pw) / (2 * pw))
        d.point((x, cy + ph_bot + curve), fill=(*CYAN_DIM, 90))

    canvas.alpha_composite(layer)


def draw_rays(canvas, cx, cy, s):
    """Draw refined light rays."""
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    rays = [
        (0, -1, 90, 0.4),      # up
        (-0.7, -0.7, 80, 0.35),  # up-left
        (0.7, -0.7, 80, 0.35),   # up-right
        (-1, -0.1, 85, 0.25),   # left
        (1, -0.1, 85, 0.25),    # right
        (-0.5, 0.6, 60, 0.15),  # down-left
        (0.5, 0.6, 60, 0.15),   # down-right
    ]

    for dx, dy, length, opacity in rays:
        end_x = cx + dx * length * s
        end_y = cy + dy * length * s
        d.line([(cx, cy), (end_x, end_y)],
               fill=(*CYAN, int(255 * opacity * 0.35)),
               width=max(1, int(2 * s)))

    layer = layer.filter(ImageFilter.GaussianBlur(radius=8 * s))
    canvas.alpha_composite(layer)


def gradient_line_h(draw, x1, y1, x2, y2, color1, color2, alpha_max=150):
    """Draw horizontal gradient line."""
    w = x2 - x1
    for i in range(w):
        frac = i / w
        r = int(color1[0] + (color2[0] - color1[0]) * frac)
        g = int(color1[1] + (color2[1] - color1[1]) * frac)
        b = int(color1[2] + (color2[2] - color1[2]) * frac)
        # Fade edges
        edge = min(frac, 1 - frac) * 3
        alpha = int(alpha_max * min(edge, 1.0))
        draw.line([(x1 + i, y1), (x1 + i, y2)], fill=(r, g, b, alpha))


def gradient_line_v(draw, x, y1, y2, color1, color2, alpha_max=100):
    """Draw vertical gradient line."""
    h = y2 - y1
    for i in range(h):
        frac = i / h
        r = int(color1[0] + (color2[0] - color1[0]) * frac)
        g = int(color1[1] + (color2[1] - color1[1]) * frac)
        b = int(color1[2] + (color2[2] - color1[2]) * frac)
        edge = min(frac, 1 - frac) * 3.5
        alpha = int(alpha_max * min(edge, 1.0))
        draw.line([(x, y1 + i), (x + 1, y1 + i)], fill=(r, g, b, alpha))


def load_font(bold=True, size=92):
    """Load best available font."""
    names_bold = ['Inter-Bold', 'Inter_18pt-Bold', 'Inter_24pt-Bold',
                  'segoeui', 'Segoe UI Bold', 'arialbd', 'calibrib']
    names_reg = ['Inter-Regular', 'Inter_18pt-Regular', 'Inter_24pt-Regular',
                 'segoeuil', 'segoeui', 'arial', 'calibri']
    names = names_bold if bold else names_reg
    for name in names:
        for ext in ['.ttf', '.otf', 'b.ttf']:
            path = f"C:/Windows/Fonts/{name}{ext}" if ext != '.ttf' else f"C:/Windows/Fonts/{name}.ttf"
            if os.path.exists(path):
                try:
                    return ImageFont.truetype(path, size)
                except:
                    pass
    # Try common paths
    for name in names:
        try:
            return ImageFont.truetype(f"C:/Windows/Fonts/{name}.ttf", size)
        except:
            pass
    return ImageFont.load_default()


def main():
    s = SCALE

    # Create both transparent and dark versions
    for bg_mode in ['transparent', 'dark']:
        if bg_mode == 'transparent':
            img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        else:
            img = Image.new('RGBA', (W, H), BG)

        cx_icon = 235 * s
        cy = H // 2

        # 1. Large ambient glow
        glow1 = radial_glow((W, H), (cx_icon, cy), int(280 * s), CYAN, 0.07, 1.8)
        img.alpha_composite(glow1)

        # 2. Shield proximity glow
        glow2 = radial_glow((W, H), (cx_icon, cy), int(165 * s), CYAN, 0.3, 1.6)
        img.alpha_composite(glow2)

        # 3. Shield
        draw_shield_full(img, cx_icon, cy, s)

        # 4. Light rays
        draw_rays(img, cx_icon, cy - 8 * s, s)

        # 5. Book core glow (bright center)
        book_glow = radial_glow((W, H), (cx_icon, cy - 8 * s), int(70 * s), CYAN_BRIGHT, 0.55, 1.3)
        img.alpha_composite(book_glow)

        # 6. Book
        draw_book_premium(img, cx_icon, cy - 8 * s, s)

        # 7. Book center bright spot
        center_glow = radial_glow((W, H), (cx_icon, cy - 12 * s), int(25 * s), (255, 255, 255), 0.12, 2.0)
        img.alpha_composite(center_glow)

        # 8. Separator line
        sep_x = 425 * s
        draw = ImageDraw.Draw(img)
        gradient_line_v(draw, sep_x, int(190 * s), int(440 * s), CYAN, PURPLE, 90)

        # 9. Dot pattern (tech feel)
        dot_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(dot_layer)
        spacing = int(42 * s)
        for x in range(int(460 * s), int(1160 * s), spacing):
            for y in range(int(170 * s), int(460 * s), spacing):
                dd.ellipse([x - s, y - s, x + s, y + s], fill=(*CYAN, 12))
        img.alpha_composite(dot_layer)

        # 10. Corner accents
        ca = ImageDraw.Draw(img)
        # Top right
        lw = max(1, int(1.2 * s))
        ca.line([(int(1150 * s), int(178 * s)), (int(1150 * s), int(218 * s))],
                fill=(*CYAN, 28), width=lw)
        ca.line([(int(1110 * s), int(178 * s)), (int(1150 * s), int(178 * s))],
                fill=(*CYAN, 28), width=lw)
        # Bottom left text area
        ca.line([(int(478 * s), int(448 * s)), (int(478 * s), int(418 * s))],
                fill=(*PURPLE, 25), width=lw)
        ca.line([(int(478 * s), int(448 * s)), (int(518 * s), int(448 * s))],
                fill=(*PURPLE, 25), width=lw)

        # ========= TEXT =========
        text_x = int(478 * s)

        # Title fonts
        title_font = load_font(bold=True, size=int(92 * s))
        sub_font = load_font(bold=False, size=int(24 * s))
        badge_font = load_font(bold=False, size=int(13 * s))

        # Measure "Asis"
        draw = ImageDraw.Draw(img)
        asis_bb = draw.textbbox((text_x, 0), "Asis", font=title_font)
        asis_w = asis_bb[2] - asis_bb[0]
        full_bb = draw.textbbox((text_x, 0), "AsisTus", font=title_font)
        text_h = full_bb[3] - full_bb[1]

        # Vertical center the text block (title + underline + subtitle + badge)
        block_h = text_h + 15 * s + 28 * s + 45 * s + 32 * s
        text_y = int(cy - block_h * 0.42)

        # "Asis" in white
        draw.text((text_x, text_y), "Asis", font=title_font, fill=(*TEXT_PRIMARY, 255))

        # "Tus" in cyan with glow behind
        tus_x = text_x + asis_w - int(3 * s)
        glow_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow_layer)
        gd.text((tus_x, text_y), "Tus", font=title_font, fill=(*CYAN, 70))
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=6 * s))
        img.alpha_composite(glow_layer)
        draw = ImageDraw.Draw(img)
        draw.text((tus_x, text_y), "Tus", font=title_font, fill=(*CYAN, 255))

        # Gradient underline
        full_bb2 = draw.textbbox((text_x, text_y), "AsisTus", font=title_font)
        ul_y = full_bb2[3] + int(12 * s)
        line_w = min(full_bb2[2] - full_bb2[0] + int(20 * s), int(380 * s))
        gradient_line_h(draw, text_x, ul_y, text_x + line_w, ul_y + int(3 * s),
                       CYAN, PURPLE, 160)

        # Subtitle
        sub_y = ul_y + int(22 * s)
        draw.text((text_x + int(3 * s), sub_y), "TUS HAZIRLIK ASISTANI",
                  font=sub_font, fill=(*TEXT_SECONDARY, 230))

        # AI badge
        badge_y = sub_y + int(42 * s)
        bw = int(180 * s)
        bh = int(32 * s)
        br = int(16 * s)

        badge_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        bd = ImageDraw.Draw(badge_layer)
        bd.rounded_rectangle(
            [text_x, badge_y, text_x + bw, badge_y + bh],
            radius=br, outline=(*CYAN, 80), width=max(1, int(1.2 * s))
        )

        badge_text = "AI POWERED"
        btbb = bd.textbbox((0, 0), badge_text, font=badge_font)
        btw = btbb[2] - btbb[0]
        bth = btbb[3] - btbb[1]
        btx = text_x + (bw - btw) // 2 + int(8 * s)
        bty = badge_y + (bh - bth) // 2 - int(2 * s)
        bd.text((btx, bty), badge_text, font=badge_font, fill=(*CYAN, 190))

        # Sparkle
        sp_x = text_x + int(20 * s)
        sp_y = badge_y + bh // 2
        sp_r = int(5 * s)
        for angle in [0, 90, 180, 270]:
            rad = math.radians(angle)
            dx = math.cos(rad) * sp_r
            dy = math.sin(rad) * sp_r
            bd.line([(sp_x, sp_y), (sp_x + dx, sp_y + dy)],
                    fill=(*CYAN, 150), width=max(1, int(s)))
        # Diagonal sparkle
        sp_r2 = int(3.5 * s)
        for angle in [45, 135, 225, 315]:
            rad = math.radians(angle)
            dx = math.cos(rad) * sp_r2
            dy = math.sin(rad) * sp_r2
            bd.line([(sp_x, sp_y), (sp_x + dx, sp_y + dy)],
                    fill=(*CYAN, 100), width=max(1, int(s * 0.8)))

        img.alpha_composite(badge_layer)

        # ========= DOWNSCALE (supersampling AA) =========
        final = img.resize((FW, FH), Image.LANCZOS)

        out_dir = os.path.dirname(os.path.abspath(__file__))
        if bg_mode == 'transparent':
            final.save(os.path.join(out_dir, 'logo_wide.png'), 'PNG')
            print(f"Saved: logo_wide.png (transparent, {FW}x{FH})")
        else:
            final.save(os.path.join(out_dir, 'logo_wide_dark.png'), 'PNG')
            print(f"Saved: logo_wide_dark.png (dark bg, {FW}x{FH})")

    # ========= NAVBAR VERSION =========
    NW_F, NH_F = 400, 80
    ns = 2  # navbar scale
    nw, nh = NW_F * ns, NH_F * ns

    navbar = Image.new('RGBA', (nw, nh), (0, 0, 0, 0))

    # Mini glow
    mini_glow = radial_glow((nw, nh), (42 * ns, 40 * ns), 38 * ns, CYAN, 0.18, 1.6)
    navbar.alpha_composite(mini_glow)

    # Crop and resize icon from the dark version (before downscale)
    # Re-open the dark final
    dark_final = Image.open(os.path.join(out_dir, 'logo_wide_dark.png'))
    icon_crop = dark_final.crop((100, 160, 370, 470))
    icon_small = icon_crop.resize((65 * ns, 65 * ns), Image.LANCZOS)
    # Center vertically
    iy = (nh - 65 * ns) // 2
    navbar.paste(icon_small, (6 * ns, iy), icon_small)

    nd = ImageDraw.Draw(navbar)
    nav_bold = load_font(bold=True, size=30 * ns)
    nav_reg = load_font(bold=False, size=11 * ns)

    ntx = 78 * ns
    nty = 15 * ns
    nd.text((ntx, nty), "Asis", font=nav_bold, fill=TEXT_PRIMARY)
    ab = nd.textbbox((ntx, nty), "Asis", font=nav_bold)
    nd.text((ab[2] - 1 * ns, nty), "Tus", font=nav_bold, fill=CYAN)

    nd.text((ntx + 2 * ns, nty + 38 * ns), "TUS Hazirlik Asistani",
            font=nav_reg, fill=TEXT_SECONDARY)

    navbar_final = navbar.resize((NW_F, NH_F), Image.LANCZOS)
    navbar_final.save(os.path.join(out_dir, 'logo_navbar.png'), 'PNG')
    print(f"Saved: logo_navbar.png ({NW_F}x{NH_F})")


if __name__ == '__main__':
    main()
