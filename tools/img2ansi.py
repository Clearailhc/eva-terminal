#!/usr/bin/env python3
"""Convert an image to truecolor ANSI avatars, chafa-style.

Each terminal cell is matched against a set of block glyphs (halves, quadrants,
eighths); the glyph whose 2-colour split best fits the cell's pixels wins.

  img2ansi.py IMAGE -o DIR [--crop L,T,R,B] [--gamma G]
      writes DIR/avatar-{50,44,40,32,26}.ans — square avatars the banners pick
      from by terminal width. Crop to a square around the face first.
  img2ansi.py IMAGE --size COLSxROWS [--half] > out.ans
      one logo to stdout (--half = plain ▀ half-blocks, lower detail)

--gamma < 1 lifts dark areas without blowing out highlights (0.78 suits dark anime frames).
"""
import argparse
import os
import sys
from PIL import Image, ImageEnhance

SIZES = (50, 44, 40, 32, 26)

CW, CH = 8, 16  # sub-pixels sampled per cell (terminal cells are ~1:2)


def masks():
    cells = [(x, y) for y in range(CH) for x in range(CW)]
    defs = {}
    for k, ch in zip(range(1, 8), "▁▂▃▄▅▆▇"):
        defs[ch] = lambda x, y, k=k: y >= CH - k * CH // 8   # lower k/8
    for k, ch in zip(range(1, 8), "▏▎▍▌▋▊▉"):
        defs[ch] = lambda x, y, k=k: x < k * CW // 8         # left k/8
    t = lambda y: y < CH // 2
    l = lambda x: x < CW // 2
    defs["▀"] = lambda x, y: t(y)
    defs["▐"] = lambda x, y: not l(x)
    defs["▘"] = lambda x, y: t(y) and l(x)
    defs["▝"] = lambda x, y: t(y) and not l(x)
    defs["▖"] = lambda x, y: not t(y) and l(x)
    defs["▗"] = lambda x, y: not t(y) and not l(x)
    defs["▚"] = lambda x, y: t(y) == l(x)
    return [(ch, [i for i, (x, y) in enumerate(cells) if fn(x, y)]) for ch, fn in defs.items()]


def fit(px, idx):
    """Return (sse, fg, bg) for splitting px into idx / rest."""
    inside = set(idx)
    a = [px[i] for i in idx]
    b = [p for i, p in enumerate(px) if i not in inside]
    err, cols = 0.0, []
    for grp in (a, b):
        n = len(grp)
        mean = [sum(p[c] for p in grp) / n for c in range(3)]
        err += sum((p[c] - mean[c]) ** 2 for p in grp for c in range(3))
        cols.append(tuple(round(v) for v in mean))
    return err, cols[0], cols[1]


def load(src, crop=None, gamma=1.0):
    img = Image.open(src).convert("RGB")
    if crop:
        img = img.crop(crop)
    if gamma != 1.0:
        img = img.point([round(255 * (i / 255) ** gamma) for i in range(256)] * 3)
    img = ImageEnhance.Color(img).enhance(1.15)
    return ImageEnhance.Contrast(img).enhance(1.08)


def render(img, cols, rows, half=False):
    if half:
        im = img.resize((cols, rows * 2), Image.LANCZOS).load()
    else:
        im = img.resize((cols * CW, rows * CH), Image.LANCZOS).load()
    M = masks()
    out = []
    for y in range(rows):
        line = []
        for x in range(cols):
            if half:
                ch, f, b = "▀", im[x, 2 * y], im[x, 2 * y + 1]
            else:
                px = [im[x * CW + i, y * CH + j] for j in range(CH) for i in range(CW)]
                (_, f, b), ch = min(((fit(px, idx), ch) for ch, idx in M), key=lambda r: r[0][0])
            line.append(f"\x1b[38;2;{f[0]};{f[1]};{f[2]};48;2;{b[0]};{b[1]};{b[2]}m{ch}")
        out.append("".join(line) + "\x1b[0m")
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image")
    ap.add_argument("-o", "--out", help="directory for avatar-{50,44,40,32,26}.ans")
    ap.add_argument("--size", help="COLSxROWS for a single logo on stdout")
    ap.add_argument("--crop", help="L,T,R,B pixel box to crop before converting")
    ap.add_argument("--gamma", type=float, default=1.0)
    ap.add_argument("--half", action="store_true")
    a = ap.parse_args()
    img = load(a.image, tuple(int(v) for v in a.crop.split(",")) if a.crop else None, a.gamma)
    if a.size:
        cols, rows = (int(v) for v in a.size.lower().split("x"))
        sys.stdout.write(render(img, cols, rows, a.half))
    elif a.out:
        os.makedirs(a.out, exist_ok=True)
        for w in SIZES:
            path = os.path.join(a.out, f"avatar-{w}.ans")
            with open(path, "w") as f:
                f.write(render(img, w, w // 2, a.half))
            print(path)
    else:
        ap.error("give -o DIR or --size COLSxROWS")


if __name__ == "__main__":
    main()
