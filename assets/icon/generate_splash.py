"""
Generate splash images for web at multiple resolutions.
Uses the wide logo and creates 1x/2x/3x/4x versions for light and dark.
"""
from PIL import Image
import os

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    splash_dir = os.path.join(script_dir, '..', '..', 'web', 'splash', 'img')

    # Load source logos
    logo_transparent = Image.open(os.path.join(script_dir, 'logo_wide.png'))
    logo_dark = Image.open(os.path.join(script_dir, 'logo_wide_dark.png'))

    # Base size for 1x (will fit nicely in loading screen)
    # Original is 1200x630, 1x target ~300x158
    base_w = 320
    base_h = int(base_w * 630 / 1200)  # maintain aspect ratio = 168

    scales = [1, 2, 3, 4]

    for scale in scales:
        w = base_w * scale
        h = base_h * scale

        # Dark version (for dark color scheme — transparent bg works on dark)
        dark = logo_transparent.resize((w, h), Image.LANCZOS)
        dark_path = os.path.join(splash_dir, f'dark-{scale}x.png')
        dark.save(dark_path, 'PNG')
        print(f"Saved: dark-{scale}x.png ({w}x{h})")

        # Light version (use dark bg version so it's visible on any background)
        light = logo_dark.resize((w, h), Image.LANCZOS)
        light_path = os.path.join(splash_dir, f'light-{scale}x.png')
        light.save(light_path, 'PNG')
        print(f"Saved: light-{scale}x.png ({w}x{h})")

if __name__ == '__main__':
    main()
