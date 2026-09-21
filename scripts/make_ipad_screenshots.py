"""Letterbox iPhone screenshots onto 13-inch iPad App Store size (2064x2752)."""
from __future__ import annotations

import os
from pathlib import Path

from PIL import Image

W, H = 2064, 2752  # 13-inch iPad portrait
BG = (17, 108, 113)  # Qopcha teal

SRCS = [
    (
        r"C:\Users\DELL\.cursor\projects\c-xampp-htdocs-Shik-Posh\assets\c__Users_DELL_AppData_Roaming_Cursor_User_workspaceStorage_91a2a1704730b87981bd34823a61e9cd_images_IMG_20260903_161648_792-cc966cba-f3fd-40ad-a4dd-d216ea2a24fc.png",
        "01_splash",
    ),
    (
        r"C:\Users\DELL\.cursor\projects\c-xampp-htdocs-Shik-Posh\assets\c__Users_DELL_AppData_Roaming_Cursor_User_workspaceStorage_91a2a1704730b87981bd34823a61e9cd_images_IMG_20260903_161618_615-13b4329c-16e6-4be1-98c9-687fdeedba5c.png",
        "02_settings",
    ),
    (
        r"C:\Users\DELL\.cursor\projects\c-xampp-htdocs-Shik-Posh\assets\c__Users_DELL_AppData_Roaming_Cursor_User_workspaceStorage_91a2a1704730b87981bd34823a61e9cd_images_IMG_20260903_153043_209-48dd32b2-7438-4a74-9e3d-db9b7317ceb9.jpg",
        "03_home",
    ),
    (
        r"C:\Users\DELL\.cursor\projects\c-xampp-htdocs-Shik-Posh\assets\c__Users_DELL_AppData_Roaming_Cursor_User_workspaceStorage_91a2a1704730b87981bd34823a61e9cd_images_IMG_20260903_153055_848-6dabafbf-4296-4d25-8ec0-bec4ef5e2896.jpg",
        "04_cart",
    ),
]

OUT_DIR = Path(r"c:\xampp\htdocs\Shik Posh\app_store_screenshots\ipad_13")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for src, name in SRCS:
        if not os.path.isfile(src):
            print("missing:", src)
            continue
        im = Image.open(src).convert("RGB")
        scale = min(W / im.width, H / im.height)
        nw, nh = max(1, int(im.width * scale)), max(1, int(im.height * scale))
        resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
        canvas = Image.new("RGB", (W, H), BG)
        canvas.paste(resized, ((W - nw) // 2, (H - nh) // 2))
        out = OUT_DIR / f"{name}_ipad13.png"
        canvas.save(out, "PNG", optimize=True)
        print(f"{out.name}: {canvas.size[0]}x{canvas.size[1]}")
    print("done ->", OUT_DIR)


if __name__ == "__main__":
    main()
