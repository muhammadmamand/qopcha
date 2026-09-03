"""Build App Store / launcher icon: brand green bg + white logo."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "qopcha_logo.png"
OUT = ROOT / "assets" / "images" / "qopcha_app_icon.png"
OUT_FG = ROOT / "assets" / "images" / "qopcha_app_icon_fg.png"
BRAND = (17, 108, 113, 255)  # #116C71


def white_logo(src: Image.Image) -> Image.Image:
    pixels = list(src.getdata())
    white = []
    for _r, _g, _b, a in pixels:
        if a < 8:
            white.append((0, 0, 0, 0))
        else:
            white.append((255, 255, 255, a))
    fg = Image.new("RGBA", src.size)
    fg.putdata(white)
    return fg


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    w, h = src.size
    fg = white_logo(src)
    fg.save(OUT_FG, format="PNG", optimize=True)

    out = Image.new("RGBA", (w, h), BRAND)
    out = Image.alpha_composite(out, fg)
    # Flatten to opaque RGB PNG (App Store prefers no alpha)
    flat = Image.new("RGB", (w, h), BRAND[:3])
    flat.paste(out, mask=out.split()[-1])
    flat.save(OUT, format="PNG", optimize=True)
    print(f"Wrote {OUT} ({w}x{h})")
    print(f"Wrote {OUT_FG} ({w}x{h})")


if __name__ == "__main__":
    main()
