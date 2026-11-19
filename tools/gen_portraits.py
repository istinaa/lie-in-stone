"""程序生成占位用像素立绘。

用法:  python tools/gen_portraits.py
输出:  assets/portraits/<角色id>/<表情>.png   (48x48, 原始尺寸, Godot 里用 Nearest 过滤放大)
       docs/立绘预览.png                        (所有角色 x 所有表情, 放大 4 倍的总览图)

每个角色 = 共用的头部/五官模板 + 角色专属的发型、服装、配饰。
表情只改变眉毛、眼睛、嘴巴和少量特效(汗滴/腮红/泪滴), 所以 7 种表情能自动生成。
"""
from pathlib import Path

from PIL import Image

W = H = 48
EMOTIONS = ["neutral", "happy", "angry", "skeptical", "surprised", "sad", "nervous"]
OUTLINE = "#1c1424"
WHITE = "#f4f0e8"
TEAR = "#8ec8f0"
BLUSH = "#f09a9a"

ROOT = Path(__file__).resolve().parent.parent


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


class Canvas:
    def __init__(self):
        self.c = [[None] * W for _ in range(H)]
        self.l = [[None] * W for _ in range(H)]

    def set(self, x, y, col, lab=None):
        if 0 <= x < W and 0 <= y < H:
            self.c[y][x] = hx(col)
            self.l[y][x] = lab

    def lab(self, x, y):
        return self.l[y][x] if 0 <= x < W and 0 <= y < H else None

    def pts(self, pts, col, lab=None, mirror=False):
        for x, y in pts:
            self.set(x, y, col, lab)
            if mirror:
                self.set(W - 1 - x, y, col, lab)

    def rect(self, x0, y0, x1, y1, col, lab=None, mirror=False):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, col, lab)
                if mirror:
                    self.set(W - 1 - x, y, col, lab)

    def ell(self, cx, cy, rx, ry, col, lab=None, clip=None, shade=None, shade_from=None):
        """填充椭圆。shade_from: x 坐标(连续坐标), 大于它的部分用 shade 色(右侧背光)。"""
        for y in range(H):
            for x in range(W):
                dx = (x + 0.5 - cx) / rx
                dy = (y + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1 and (clip is None or clip(x, y)):
                    use = shade if (shade and shade_from is not None and x + 0.5 > shade_from) else col
                    self.set(x, y, use, lab)

    def outline(self, col=OUTLINE):
        add = []
        for y in range(H):
            for x in range(W):
                if self.c[y][x] is None:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < W and 0 <= ny < H and self.c[ny][nx] is not None:
                            add.append((x, y))
                            break
        for x, y in add:
            self.set(x, y, col, "outline")

    def image(self):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        img.putdata([self.c[y][x] or (0, 0, 0, 0) for y in range(H) for x in range(W)])
        return img


# ---------------------------------------------------------------- 共用部件

def body(cv, col, shade, top=37, hw=9.0, slope=1.5, lab="cloth"):
    """肩膀/上身: 梯形, 右侧 3 像素背光。"""
    for y in range(top, H):
        w = hw + (y - top) * slope
        for x in range(W):
            off = x + 0.5 - 24
            if abs(off) <= w:
                cv.set(x, y, shade if off > w - 3 else col, lab)


def head(cv, p, jaw=False):
    cv.rect(20, 31, 27, 37, p["skin_s"], "skin")                     # 脖子
    cv.ell(24, 22, 9.5, 11.5, p["skin"], "skin")
    if jaw:                                                          # 方下巴
        cv.rect(16, 26, 31, 32, p["skin"], "skin")
        cv.rect(18, 33, 29, 33, p["skin"], "skin")
    cv.pts([(13, 21), (13, 22), (13, 23), (13, 24)], p["skin"], "skin", mirror=True)   # 耳朵
    cv.pts([(14, 22), (14, 23)], p["skin_s"], "skin", mirror=True)


def shade_face(cv, p):
    """右侧背光 + 头发/帽子下方投影 + 鼻子。"""
    for y in range(H):
        for x in range(W):
            if cv.lab(x, y) != "skin":
                continue
            above = cv.lab(x, y - 1)
            if x >= 31 or above in ("hair", "hat"):
                cv.set(x, y, p["skin_s"], "skin")
    cv.pts([(24, 25), (24, 26)], p["skin_s"], "skin")


def hair_cap(cv, p, cx, cy, rx, ry, fringe, default_bottom):
    """头发: 椭圆内、且 y 不超过该列刘海下沿的像素。"""
    for y in range(H):
        for x in range(W):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1 and y <= fringe.get(x, default_bottom):
                cv.set(x, y, p["hair_s"] if x >= 29 else p["hair"], "hair")


BROWS = {
    "neutral":   [(18, 19), (19, 19), (20, 19), (21, 19)],
    "happy":     [(18, 19), (19, 18), (20, 18), (21, 19)],
    "angry":     [(18, 18), (19, 18), (20, 19), (21, 20)],
    "sad":       [(18, 20), (19, 19), (20, 19), (21, 18)],
    "surprised": [(18, 17), (19, 17), (20, 17), (21, 17)],
    "nervous":   [(18, 19), (19, 19), (20, 18), (21, 18)],
}

MOUTHS = {
    "neutral":   [(22, 29), (23, 29), (24, 29), (25, 29)],
    "happy":     [(21, 28), (22, 29), (23, 29), (24, 29), (25, 29), (26, 28)],
    "angry":     [(21, 30), (22, 29), (23, 29), (24, 29), (25, 29), (26, 30)],
    "skeptical": [(22, 29), (23, 29), (24, 29), (25, 28), (26, 28)],
    "surprised": [(23, 28), (24, 28), (23, 29), (24, 29), (23, 30), (24, 30)],
    "sad":       [(22, 30), (23, 29), (24, 29), (25, 30)],
    "nervous":   [(21, 29), (22, 30), (23, 29), (24, 30), (25, 29), (26, 30)],
}


def brows(cv, p, emo, thick=1):
    col = p["brow"]
    if emo == "skeptical":
        left = BROWS["neutral"]
        right = [(26, 18), (27, 17), (28, 17), (29, 17)]          # 单边挑眉
        pts = left + right
    else:
        pts = BROWS[emo] + [(W - 1 - x, y) for x, y in BROWS[emo]]
    for x, y in pts:
        cv.set(x, y, col, "brow")
        if thick > 1:
            cv.set(x, y - 1, col, "brow")


def eyes(cv, p, emo, style="normal"):
    E = p["eye"]
    hl = p.get("eye_hl", WHITE)
    if emo == "happy":                                             # 眯眼笑 ^ ^
        cv.pts([(18, 22), (19, 21), (20, 21), (21, 22)], p["line"], "eye", mirror=True)
        return
    if emo == "surprised":                                         # 瞪大
        cv.rect(18, 20, 21, 23, WHITE, "eye", mirror=True)
        cv.rect(19, 21, 20, 22, E, "eye", mirror=True)
        return
    if emo == "nervous":                                           # 眼神飘忽
        cv.rect(19, 21, 20, 22, WHITE, "eye", mirror=True)
        cv.pts([(19, 22), (27, 22)], E, "eye")
        cv.pts([(19, 21), (27, 21)], E, "eye")
        return
    if style == "big":
        cv.rect(18, 20, 20, 22, E, "eye")
        cv.rect(27, 20, 29, 22, E, "eye")
        cv.pts([(18, 22), (19, 22), (20, 22), (27, 22), (28, 22), (29, 22)], p["iris"], "eye")
        cv.pts([(18, 20), (27, 20)], hl, "eye")
    elif style == "narrow":
        cv.pts([(19, 22), (20, 22), (18, 21)], E, "eye")
        cv.pts([(27, 22), (28, 22), (29, 21)], E, "eye")
    else:
        cv.rect(19, 21, 20, 22, E, "eye", mirror=True)
        cv.pts([(19, 21), (27, 21)], hl, "eye")
    if emo == "skeptical":                                         # 右眼半眯
        cv.rect(26, 20, 29, 21, p["skin_s"], "skin")
        cv.pts([(26, 21), (27, 21), (28, 21), (29, 21)], p["line"], "eye")
    if emo == "angry":                                             # 怒目: 上眼睑压低
        cv.pts([(19, 21), (20, 21), (27, 21), (28, 21)], p["line"], "eye")


def mouth(cv, p, emo):
    cv.pts(MOUTHS[emo], p["line"], "mouth")
    if emo == "happy":
        cv.pts([(23, 30), (24, 30)], p["line"], "mouth")


def extras(cv, p, emo, blush_always=False):
    if emo == "happy" or blush_always:
        cv.pts([(17, 25), (18, 25)], BLUSH, "fx", mirror=True)
    if emo == "nervous":                                           # 汗滴
        cv.pts([(36, 14), (35, 15), (36, 15), (35, 16), (36, 16)], TEAR, "fx")
        cv.set(35, 15, WHITE, "fx")
    if emo == "sad":                                               # 泪滴
        cv.pts([(19, 24), (19, 25)], TEAR, "fx")


def face(cv, p, emo, eye_style="normal", brow_thick=1, blush_always=False):
    shade_face(cv, p)
    eyes(cv, p, emo, eye_style)
    brows(cv, p, emo, brow_thick)
    mouth(cv, p, emo)
    extras(cv, p, emo, blush_always)


# ---------------------------------------------------------------- 角色

def hero(emo):
    """假勇者: 普通的年轻人, 乱糟糟的头发, 不合身的仪式用金色肩甲。"""
    p = dict(skin="#f0c8a0", skin_s="#d0a07a", hair="#6b4a2f", hair_s="#4e3420",
             eye="#2a2030", line="#5a2a2a", brow="#3e2818")
    cv = Canvas()
    body(cv, "#3a5ba0", "#2a4278", top=36, hw=11, slope=1.6)     # 蓝披风
    body(cv, "#b49a6e", "#8e7650", top=38, hw=6, slope=0.9)      # 朴素布衣
    cv.ell(11, 41, 7, 4.5, "#d8b84a", "cloth", shade="#a8862e", shade_from=99)
    cv.ell(37, 41, 7, 4.5, "#a8862e", "cloth")
    cv.rect(10, 41, 13, 41, "#f0dc8a", "cloth")                  # 肩甲高光
    cv.pts([(23, 42), (24, 42), (23, 43), (24, 43), (22, 42), (25, 43)], "#e8c84a", "cloth")  # 太阳纹章
    head(cv, p)
    fringe = {15: 23, 16: 21, 17: 19, 18: 18, 19: 17, 20: 18, 21: 17, 22: 19, 23: 20,
              24: 18, 25: 17, 26: 18, 27: 17, 28: 18, 29: 17, 30: 19, 31: 21, 32: 23}
    hair_cap(cv, p, 24, 17, 11, 9, fringe, -1)
    cv.rect(14, 16, 15, 23, p["hair"], "hair")
    cv.rect(32, 16, 33, 23, p["hair_s"], "hair")
    cv.pts([(16, 8), (17, 7), (17, 8), (22, 6), (23, 5), (23, 6), (29, 7), (30, 7), (30, 8)], p["hair"], "hair")
    cv.pts([(19, 11), (20, 10), (21, 10), (22, 10)], "#8a6440", "hair")   # 高光
    face(cv, p, emo)
    return cv


def knight(emo):
    """骑士·莱恩哈特: 方下巴, 短发, 伤疤, 胡茬, 钢铁肩甲和红披风。"""
    p = dict(skin="#d9a477", skin_s="#b07e57", hair="#7a6a58", hair_s="#5a4c3e",
             eye="#1e1a24", line="#4a2420", brow="#3a3028")
    cv = Canvas()
    body(cv, "#8e2a2a", "#621a1a", top=36, hw=12, slope=1.6)     # 红披风
    body(cv, "#9aa3ad", "#6c7680", top=38, hw=7, slope=1.0)      # 胸甲
    cv.ell(12, 40, 7.5, 5, "#aab3bd", "cloth")
    cv.ell(36, 40, 7.5, 5, "#7c8690", "cloth")
    cv.rect(7, 42, 17, 42, "#6c7680", "cloth")                   # 肩甲分层线
    cv.rect(30, 42, 40, 42, "#5c6670", "cloth")
    cv.pts([(10, 39), (37, 39)], "#e0e6ec", "cloth")             # 铆钉
    cv.rect(19, 34, 28, 37, "#8a939d", "cloth")                  # 护颈
    cv.rect(19, 34, 28, 34, "#c0c8d0", "cloth")
    head(cv, p, jaw=True)
    hair_cap(cv, p, 24, 17, 10.5, 8, {}, 15)
    cv.rect(14, 15, 15, 20, p["hair"], "hair")
    cv.rect(32, 15, 33, 20, p["hair_s"], "hair")
    face(cv, p, emo, brow_thick=2)
    cv.pts([(17, 22), (17, 23), (18, 24), (18, 25), (19, 26)], "#c06a5a", "fx")   # 伤疤
    cv.pts([(19, 32), (21, 31), (23, 32), (25, 31), (27, 32), (28, 31), (20, 30), (27, 30)],
           p["skin_s"], "skin")                                                   # 胡茬
    return cv


def mia(emo):
    """学徒·米娅: 橙色双马尾, 齐刘海, 大眼睛, 蓝色见习尖帽, 白色法袍。"""
    p = dict(skin="#f6d3b5", skin_s="#dcb08f", hair="#e8853a", hair_s="#b9602a",
             eye="#2a2440", iris="#4a8acb", line="#7a3030", brow="#a8521e")
    cv = Canvas()
    body(cv, "#ece8f0", "#c3bccd", top=37, hw=8, slope=1.3)      # 白法袍
    for i in range(5):                                           # 蓝色 V 领
        cv.pts([(19 + i, 37 + i)], "#3d6fc4", "cloth", mirror=True)
    cv.rect(23, 42, 24, 43, "#e8c84a", "cloth")                  # 吊坠
    cv.ell(11, 31, 4, 9, p["hair"], "hair")                      # 双马尾(在头后)
    cv.ell(37, 31, 4, 9, p["hair_s"], "hair")
    head(cv, p)
    hair_cap(cv, p, 24, 17, 10.5, 9, {x: 18 for x in range(16, 32)}, -1)
    cv.rect(14, 16, 15, 26, p["hair"], "hair")
    cv.rect(32, 16, 33, 26, p["hair_s"], "hair")
    cv.pts([(12, 22), (13, 22), (34, 22), (35, 22)], "#3d6fc4", "hair")   # 发绳
    # 见习法师尖帽(帽尖向右歪)
    cv.ell(24, 11, 13, 2.6, "#3d6fc4", "hat", shade="#2c519a", shade_from=31)
    for y in range(0, 10):
        half = 1 + y * 0.75
        cx = 24 + (10 - y) * 0.45
        for x in range(W):
            if abs(x + 0.5 - cx) <= half:
                cv.set(x, y, "#2c519a" if x + 0.5 > cx + half - 2 else "#3d6fc4", "hat")
    cv.pts([(25, 5), (24, 6), (25, 6), (26, 6), (25, 7)], "#f0d860", "hat")   # 星星
    face(cv, p, emo, eye_style="big", blush_always=True)
    return cv


def oswald(emo):
    """学者·奥斯瓦德: 秃顶, 白色鬓发和长胡子, 圆眼镜, 墨绿学者袍。"""
    p = dict(skin="#e6bf9a", skin_s="#c49a76", hair="#e8e8ec", hair_s="#b8b8c4",
             eye="#2a2a34", line="#5a3a3a", brow="#d0d0dc")
    cv = Canvas()
    body(cv, "#3e5a48", "#2c4234", top=37, hw=9, slope=1.4)
    cv.rect(23, 37, 24, 47, "#c9a54a", "cloth")                  # 金色饰带
    cv.pts([(18, 38), (19, 39), (20, 40), (21, 41)], "#c9a54a", "cloth", mirror=True)
    head(cv, p)
    cv.ell(15, 19, 3, 5.5, p["hair"], "hair")                    # 鬓发
    cv.ell(33, 19, 3, 5.5, p["hair_s"], "hair")
    cv.pts([(20, 13), (21, 12), (22, 12)], "#f6dcbc", "skin")    # 秃顶反光
    cv.pts([(21, 15), (22, 15), (23, 15), (25, 16), (26, 16)], p["skin_s"], "skin")   # 抬头纹
    cv.ell(24, 31, 9, 7, p["hair"], "hair", clip=lambda x, y: y >= 27,
           shade=p["hair_s"], shade_from=30)                     # 长胡子
    cv.pts([(20, 27), (21, 27), (22, 27), (23, 27), (24, 27), (25, 27), (26, 27), (27, 27)],
           p["hair"], "hair")                                    # 八字胡
    face(cv, p, emo, brow_thick=2)
    frame = "#8a6a2a"                                            # 圆眼镜
    for x0 in (17, 26):
        x1 = x0 + 4
        cv.rect(x0 + 1, 20, x1 - 1, 20, frame, "fx")
        cv.rect(x0 + 1, 24, x1 - 1, 24, frame, "fx")
        cv.rect(x0, 21, x0, 23, frame, "fx")
        cv.rect(x1, 21, x1, 23, frame, "fx")
    cv.pts([(22, 22), (23, 21), (24, 21), (25, 22)], frame, "fx")
    return cv


def nova(emo):
    """窃贼·诺娃: 紫色兜帽, 青色斜刘海, 琥珀色眼睛, 围巾, 皮甲, 金耳环。"""
    p = dict(skin="#e8b894", skin_s="#c08e6c", hair="#2e8c88", hair_s="#1f6461",
             eye="#2a1a1a", eye_hl="#e0a030", line="#5a2a2a", brow="#1f4a48")
    hood, hood_s = "#3b2a4a", "#2a1d36"
    cv = Canvas()
    body(cv, "#5a4030", "#3e2c20", top=37, hw=9, slope=1.4)      # 皮甲
    cv.pts([(16, 42), (17, 43), (18, 44), (19, 45), (20, 46), (21, 47)], "#2e2018", "cloth")  # 斜挎带
    cv.ell(24, 20, 13, 14, hood, "hat", clip=lambda x, y: y <= 36, shade=hood_s, shade_from=31)
    head(cv, p)
    cv.ell(24, 37, 10, 3.5, "#3c4a50", "cloth", shade="#2a3438", shade_from=29)   # 围巾
    cv.ell(24, 15, 11.5, 7, hood, "hat", clip=lambda x, y: y <= 16, shade=hood_s, shade_from=31)
    fringe = {15: 24, 16: 22, 17: 20, 18: 19, 19: 19, 20: 19, 21: 18, 22: 18, 23: 18, 24: 18,
              25: 17, 26: 17, 27: 17, 28: 17, 29: 17, 30: 18, 31: 19, 32: 20}
    for x, bottom in fringe.items():
        for y in range(16, bottom + 1):
            cv.set(x, y, p["hair_s"] if x >= 29 else p["hair"], "hair")
    cv.pts([(17, 17), (18, 17), (19, 17)], "#4ab0aa", "hair")    # 刘海高光
    face(cv, p, emo)
    cv.pts([(33, 27), (33, 28)], "#e8c84a", "fx")                # 耳环
    return cv


def seraphim(emo):
    """大祭司·塞拉菲姆: 高耸的白金法冠, 银发, 细长眯眼, 白袍金色圣带。"""
    p = dict(skin="#efd2bd", skin_s="#cfa992", hair="#c8ccd8", hair_s="#9aa0b4",
             eye="#4a3a6a", line="#6a3a3a", brow="#8a90a4")
    gold, gold_s = "#d4a836", "#a07c22"
    cv = Canvas()
    body(cv, "#f2efe6", "#cfc8b4", top=37, hw=9, slope=1.5)
    cv.rect(18, 38, 20, 47, gold, "cloth")                       # 圣带
    cv.rect(27, 38, 29, 47, gold_s, "cloth")
    cv.pts([(23, 41), (24, 41), (23, 42), (24, 42)], "#b03040", "cloth")  # 红宝石
    cv.rect(19, 33, 28, 37, "#f2efe6", "cloth")                  # 高领
    cv.rect(26, 33, 28, 37, "#cfc8b4", "cloth")
    head(cv, p)
    cv.rect(14, 13, 15, 24, p["hair"], "hair")
    cv.rect(32, 13, 33, 24, p["hair_s"], "hair")
    cv.rect(15, 12, 32, 14, p["hair"], "hair")
    for y in range(0, 13):                                       # 法冠
        half = 2.5 + y * 0.62
        for x in range(W):
            off = x + 0.5 - 24
            if abs(off) <= half:
                cv.set(x, y, "#dcd6c4" if off > half - 2.5 else "#f6f2e8", "hat")
    cv.rect(23, 1, 24, 12, gold, "hat")                          # 中央金带
    cv.rect(16, 11, 31, 12, gold, "hat")                         # 底部金边
    cv.rect(28, 11, 31, 12, gold_s, "hat")
    cv.pts([(21, 6), (22, 6), (25, 6), (26, 6)], gold, "hat")    # 十字横杠
    face(cv, p, emo, eye_style="narrow")
    cv.pts([(19, 28), (28, 28)], p["skin_s"], "skin")            # 法令纹
    return cv


CHARACTERS = {
    "hero": hero,
    "knight_reinhardt": knight,
    "apprentice_mia": mia,
    "scholar_oswald": oswald,
    "thief_nova": nova,
    "priest_seraphim": seraphim,
}


def main():
    out_root = ROOT / "assets" / "portraits"
    scale, gap = 4, 8
    sheet = Image.new("RGBA", (gap + len(EMOTIONS) * (W * scale + gap),
                               gap + len(CHARACTERS) * (H * scale + gap)), hx("#6e6a78"))
    for row, (cid, draw) in enumerate(CHARACTERS.items()):
        d = out_root / cid
        d.mkdir(parents=True, exist_ok=True)
        for col, emo in enumerate(EMOTIONS):
            cv = draw(emo)
            cv.outline()
            img = cv.image()
            img.save(d / f"{emo}.png")
            big = img.resize((W * scale, H * scale), Image.NEAREST)
            sheet.alpha_composite(big, (gap + col * (W * scale + gap), gap + row * (H * scale + gap)))
    (ROOT / "docs").mkdir(exist_ok=True)
    sheet.save(ROOT / "docs" / "立绘预览.png")
    print(f"生成 {len(CHARACTERS)} 个角色 x {len(EMOTIONS)} 种表情 -> {out_root}")


if __name__ == "__main__":
    main()
