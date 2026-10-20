import re,sys,unicodedata
from PIL import Image,ImageDraw,ImageFont
src,dst=sys.argv[1],sys.argv[2]
mono=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',15)
bold=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf',15)
cjk=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',15)
CW,CH=9,19
def x256(n):
    base=[(0,0,0),(205,0,0),(0,205,0),(205,205,0),(0,0,238),(205,0,205),(0,205,205),(229,229,229),(127,127,127),(255,0,0),(0,255,0),(255,255,0),(92,92,255),(255,0,255),(0,255,255),(255,255,255)]
    if n<16: return base[n]
    if n<232:
        n-=16; lv=[0,95,135,175,215,255]; return (lv[n//36],lv[n//6%6],lv[n%6])
    g=8+(n-232)*10; return (g,g,g)
lines=open(src).read().split('\n')
W=max(1,max(sum(2 if unicodedata.east_asian_width(c) in 'WF' else 1 for c in re.sub(r'\x1b\[[0-9;?]*[A-Za-z]','',l)) for l in lines))
DEF_FG,DEF_BG=(216,214,224),(28,27,34)
img=Image.new('RGB',((W+2)*CW,(len(lines)+1)*CH),DEF_BG);d=ImageDraw.Draw(img)
for y,l in enumerate(lines):
    fgc,bgc,b,rev=DEF_FG,None,False,False;x=1
    for tok in re.split(r'(\x1b\[[0-9;?]*[A-Za-z])',l):
        if tok.startswith('\x1b['):
            if not tok.endswith('m'): continue
            p=[int(v) if v else 0 for v in tok[2:-1].split(';')];i=0
            while i<len(p):
                v=p[i]
                if v==0: fgc,bgc,b,rev=DEF_FG,None,False,False
                elif v==1: b=True
                elif v==7: rev=True
                elif v in (38,48) and p[i+1]==5:
                    c=x256(p[i+2]); i+=2
                    if v==38: fgc=c
                    else: bgc=c
                elif v==38: fgc=tuple(p[i+2:i+5]);i+=4
                elif v==48: bgc=tuple(p[i+2:i+5]);i+=4
                i+=1
            continue
        for c in tok:
            w=2 if unicodedata.east_asian_width(c) in 'WF' else 1
            f,bk=(fgc,bgc)
            if rev: f,bk=(bgc or DEF_BG),fgc
            X,Y=x*CW,y*CH+CH//2
            if bk: d.rectangle([X,y*CH+CH//2-CH//2+CH//2,X+w*CW-1,y*CH+CH+CH//2-1],fill=bk)
            G={'▀':lambda u,v:v<CH//2,'▐':lambda u,v:u>=CW//2,'▘':lambda u,v:v<CH//2 and u<CW//2,'▝':lambda u,v:v<CH//2 and u>=CW//2,
               '▖':lambda u,v:v>=CH//2 and u<CW//2,'▗':lambda u,v:v>=CH//2 and u>=CW//2,'▚':lambda u,v:(v<CH//2)==(u<CW//2)}
            for k,g in enumerate('▁▂▃▄▅▆▇',1): G[g]=lambda u,v,k=k:v>=CH-k*CH/8
            for k,g in enumerate('▏▎▍▌▋▊▉',1): G[g]=lambda u,v,k=k:u<k*CW/8
            if c in G:
                for v in range(CH):
                    for u in range(CW):
                        if G[c](u,v): img.putpixel((X+u,Y+v),f)
            elif c=='█':
                d.rectangle([X,Y,X+CW-1,Y+CH-1],fill=f)
            elif c!=' ':
                d.text((X,Y),c,font=cjk if w==2 else (bold if b else mono),fill=f)
            x+=w
img.save(dst)
