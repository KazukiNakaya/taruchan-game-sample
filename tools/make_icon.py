"""icon/icon.png から Windows 用の icon/icon.ico(16〜256px)を作る。

使い方: .venv/Scripts/python tools/make_icon.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]

image = Image.open(ROOT / "icon" / "icon.png").convert("RGBA")
# 余白を詰めて、アイコンで小さく見えないようにする
box = image.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
if box:
    left, top, right, bottom = box
    side = max(right - left, bottom - top) + 40
    cx, cy = (left + right) // 2, (top + bottom) // 2
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(image.crop(box), (side // 2 - (right - left) // 2, side // 2 - (bottom - top) // 2))
    image = canvas
image.save(ROOT / "icon" / "icon.ico", sizes=SIZES)
print("作成しました: icon/icon.ico")
