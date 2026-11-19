"""程序生成占位用像素王都地图。

用法:  python tools/gen_town.py
输出:  assets/tiles/town.png  (640x360 原始尺寸, Godot 里用 Nearest 过滤放大 2 倍)

建筑位置与 data/locations.json 的 rect 对应（大致落在 rect 内）。
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

W, H = 640, 360
ROOT = Path(__file__).resolve().parent.parent
rng = random.Random(7)

img = Image.new("RGB", (W, H), "#5d8a3c")
d = ImageDraw.Draw(img)

OUT = "#1c1424"


def rect(x0, y0, x1, y1, col):
    d.rectangle([x0, y0, x1, y1], fill=col)


def outline_rect(x0, y0, x1, y1, col, ol=OUT):
    d.rectangle([x0, y0, x1, y1], fill=col, outline=ol)


def poly(pts, col, ol=OUT):
    d.polygon(pts, fill=col, outline=ol)


# ---- 草地纹理
for _ in range(2600):
    x, y = rng.randrange(W), rng.randrange(H)
    img.putpixel((x, y), rng.choice([(0x6a, 0x97, 0x46), (0x52, 0x7c, 0x34), (0x74, 0xa0, 0x4c)]))

# ---- 城墙（顶部）
rect(0, 0, W, 22, "#7a7a8c")
for x in range(0, W, 16):
    rect(x, 0, x + 8, 5, "#5a5a6c")
rect(0, 22, W, 24, "#4a4a5a")
for x in range(4, W, 32):
    rect(x, 10, x + 2, 14, "#3a3a48")

# ---- 道路（石板）
ROAD = "#b8a888"
ROAD_D = "#9c8c70"


def road(x0, y0, x1, y1):
    rect(x0, y0, x1, y1, ROAD)
    for _ in range(((x1 - x0) * (y1 - y0)) // 40):
        x, y = rng.randint(x0, x1), rng.randint(y0, y1)
        img.putpixel((x, y), (0x9c, 0x8c, 0x70))


road(300, 128, 340, 360)        # 南北主路
road(0, 200, 640, 228)          # 东西主路
road(180, 150, 300, 166)        # 训练场支路
road(340, 150, 460, 166)        # 图书馆支路
road(130, 228, 146, 252)        # 酒馆支路
road(512, 228, 528, 256)        # 小巷支路

# ---- 中央广场 + 喷泉
d.ellipse([262, 176, 378, 252], fill=ROAD, outline=ROAD_D)
d.ellipse([296, 196, 344, 232], fill="#8a8a9a", outline=OUT)
d.ellipse([302, 201, 338, 227], fill="#4f8fd0")
d.ellipse([312, 208, 328, 220], fill="#9fd0f0")
rect(318, 196, 322, 214, "#d0d0dc")
d.point([(320, 194), (319, 195), (321, 195)], fill="#bfe6ff")

# ---- 大神殿（上中） rect 244,40,152,92
tx, ty = 244, 40
rect(tx + 6, ty + 86, tx + 146, ty + 92, "#d8d4c8")          # 台阶
rect(tx + 12, ty + 80, tx + 140, ty + 86, "#e8e4d8")
outline_rect(tx + 16, ty + 38, tx + 136, ty + 80, "#f0ece0")
for i in range(7):
    cx = tx + 24 + i * 17
    rect(cx, ty + 42, cx + 5, ty + 80, "#ffffff")
    rect(cx + 5, ty + 42, cx + 6, ty + 80, "#c8c4b8")
poly([(tx + 8, ty + 40), (tx + 76, ty + 8), (tx + 144, ty + 40)], "#e0b040")
poly([(tx + 24, ty + 36), (tx + 76, ty + 14), (tx + 128, ty + 36)], "#f0d070", ol="#c09020")
rect(tx + 74, ty - 6, tx + 78, ty + 10, "#e0b040")
rect(tx + 70, ty - 2, tx + 82, ty + 1, "#e0b040")
outline_rect(tx + 66, ty + 56, tx + 86, ty + 80, "#6a4a2a")
rect(tx + 75, ty + 56, tx + 77, ty + 80, "#4a3018")

# ---- 骑士训练场（左上） rect 28,118,170,92
gx, gy = 28, 118
outline_rect(gx + 4, gy + 14, gx + 166, gy + 88, "#d8c08a")
for _ in range(500):
    x, y = rng.randint(gx + 6, gx + 164), rng.randint(gy + 16, gy + 86)
    img.putpixel((x, y), (0xc8, 0xb0, 0x7a))
for x in range(gx + 4, gx + 168, 8):                      # 栅栏
    rect(x, gy + 8, x + 2, gy + 16, "#7a5030")
    rect(x, gy + 86, x + 2, gy + 94, "#7a5030")
rect(gx + 4, gy + 10, gx + 166, gy + 11, "#9a6a40")
rect(gx + 4, gy + 88, gx + 166, gy + 89, "#9a6a40")
for i, (px, py) in enumerate([(30, 40), (60, 52), (90, 38), (120, 56)]):   # 木桩
    x, y = gx + px, gy + py
    outline_rect(x, y, x + 6, y + 18, "#a0703c")
    rect(x - 4, y + 5, x + 10, y + 7, "#a0703c")
outline_rect(gx + 136, gy + 26, gx + 160, gy + 46, "#8a8a9a")  # 武器架
for i in range(4):
    rect(gx + 139 + i * 5, gy + 22, gx + 140 + i * 5, gy + 44, "#d0d0e0")
rect(gx + 14, gy - 10, gx + 15, gy + 14, "#5a3a20")           # 旗
poly([(gx + 16, gy - 10), (gx + 34, gy - 5), (gx + 16, gy)], "#b02828")

# ---- 王立图书馆（右上） rect 452,104,160,96
lx, ly = 452, 104
outline_rect(lx + 10, ly + 40, lx + 120, ly + 92, "#c8b8a0")
poly([(lx + 4, ly + 42), (lx + 65, ly + 18), (lx + 126, ly + 42)], "#3a62b0")
for i in range(4):
    wx = lx + 20 + i * 25
    outline_rect(wx, ly + 52, wx + 12, ly + 70, "#f0d880")
    rect(wx + 6, ly + 52, wx + 6, ly + 70, OUT)
outline_rect(lx + 56, ly + 72, lx + 74, ly + 92, "#5a3a20")
outline_rect(lx + 122, ly + 14, lx + 154, ly + 92, "#b8a890")  # 塔
poly([(lx + 118, ly + 16), (lx + 138, ly - 14), (lx + 158, ly + 16)], "#2a52a0")
outline_rect(lx + 132, ly + 30, lx + 144, ly + 46, "#f0d880")
outline_rect(lx + 132, ly + 60, lx + 144, ly + 76, "#f0d880")

# ---- 金麦酒馆（左下） rect 64,246,150,90
bx, by = 64, 252
outline_rect(bx + 10, by + 34, bx + 140, by + 82, "#a87850")
for y in range(by + 40, by + 82, 6):
    rect(bx + 11, y, bx + 139, y, "#8a5c38")
poly([(bx + 2, by + 36), (bx + 30, by + 8), (bx + 120, by + 8), (bx + 148, by + 36)], "#8a3a28")
for x in range(bx + 10, bx + 140, 10):
    rect(x, by + 14, x, by + 34, "#6a2a1a")
outline_rect(bx + 22, by + 46, bx + 42, by + 62, "#ffd070")
outline_rect(bx + 108, by + 46, bx + 128, by + 62, "#ffd070")
outline_rect(bx + 64, by + 54, bx + 86, by + 82, "#5a3a20")
outline_rect(bx + 54, by + 36, bx + 96, by + 46, "#e0b040")    # 招牌
rect(bx + 62, by + 39, bx + 88, by + 42, "#8a5c18")
outline_rect(bx + 120, by + 0, bx + 130, by + 14, "#7a6a6a")   # 烟囱

# ---- 下城小巷（右下） rect 432,250,178,92
sx, sy = 432, 252
rect(sx, sy + 10, sx + 178, sy + 90, "#3a3444")
rows = [(sx + 4, sy + 22, 40, 50), (sx + 48, sy + 14, 36, 58), (sx + 90, sy + 26, 38, 46), (sx + 134, sy + 18, 40, 54)]
for (x, y, w, h) in rows:
    outline_rect(x, y, x + w, y + h, rng.choice(["#6a5a5a", "#5a5a6a", "#6a6050"]))
    poly([(x - 3, y + 2), (x + w // 2, y - 12), (x + w + 3, y + 2)], rng.choice(["#4a3a3a", "#3a3a4a"]))
    for _ in range(2):
        wx = x + rng.randint(4, w - 12)
        wy = y + rng.randint(6, h - 22)
        outline_rect(wx, wy, wx + 7, wy + 8, rng.choice(["#2a2430", "#c0a050"]))
    outline_rect(x + w // 2 - 4, y + h - 14, x + w // 2 + 4, y + h, "#2a1a14")
for x in range(sx + 2, sx + 176, 22):   # 晾衣绳
    d.line([(x, sy + 16), (x + 20, sy + 20)], fill="#d0c0a0")
outline_rect(sx + 82, sy + 76, sx + 92, sy + 86, "#6a4a2a")   # 木桶

# ---- 树
for (x, y) in [(220, 60), (210, 100), (420, 60), (430, 92), (600, 220), (20, 230), (240, 300), (390, 310),
               (12, 330), (620, 120), (220, 250), (410, 250), (580, 40), (40, 60), (100, 60)]:
    rect(x + 3, y + 10, x + 5, y + 16, "#5a3a20")
    d.ellipse([x - 4, y - 4, x + 12, y + 12], fill="#2f6a2a", outline=OUT)
    d.ellipse([x - 1, y - 2, x + 6, y + 5], fill="#4a8a3a")

out = ROOT / "assets" / "tiles" / "town.png"
out.parent.mkdir(parents=True, exist_ok=True)
img.save(out)
img.resize((W * 2, H * 2), Image.NEAREST).save(ROOT / "docs" / "地图预览.png")
print("saved", out)
