"""
Generator for Dreamweaver Antagonist Sprites
Creates:
1. icons/mob/huds/antag_hud.dmi -> updates with "dreamweaver" state
2. icons/mob/actions/actions_dreamweaver.dmi -> 6 states:
   - mind_touch
   - dread_wave
   - astral_walk
   - mind_web
   - nightmare_cascade
   - bg_dreamweaver
3. icons/obj/antags/dreamweaver.dmi -> "psionic_node" state
4. icons/mob/effects/dreamweaver_aura.dmi -> "dreamweaver_aura" (4 animated frames)
5. icons/effects/dream_web.dmi -> "web" state
"""

import os
import sys
import math
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.abspath("."))
from tools.dmi import Dmi, State

# Color Palettes
C_BLACK = (0, 0, 0, 255)
C_SHADOW_OUTLINE = (18, 12, 32, 255)
C_DARK_PURPLE = (48, 18, 76, 255)
C_MID_PURPLE = (94, 38, 142, 255)
C_VIOLET = (147, 51, 234, 255)
C_BRIGHT_LILAC = (192, 132, 252, 255)
C_PALE_LAVENDER = (233, 213, 255, 255)

C_DARK_CYAN = (12, 74, 110, 255)
C_MID_CYAN = (14, 165, 233, 255)
C_BRIGHT_CYAN = (56, 189, 248, 255)
C_PALE_CYAN = (186, 230, 253, 255)

C_DARK_MAGENTA = (131, 24, 67, 255)
C_MAGENTA = (219, 39, 119, 255)
C_BRIGHT_MAGENTA = (244, 114, 182, 255)

C_STAR_WHITE = (248, 250, 252, 255)
C_TRANSPARENT = (0, 0, 0, 0)


def create_antag_hud_state():
    """10x10 icon placed at x: 22..31, y: 0..9 on a 32x32 transparent canvas."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    # Base offset
    ox, oy = 22, 0
    
    # Dreamweaver HUD Symbol: A stylized dream eye woven inside a psychic diamond web
    # Pixel pattern relative to (ox, oy):
    pixels = {
        # Outer dark outline / boundary
        (ox+4, oy+0): C_SHADOW_OUTLINE, (ox+5, oy+0): C_SHADOW_OUTLINE,
        (ox+2, oy+1): C_SHADOW_OUTLINE, (ox+3, oy+1): C_MID_PURPLE, (ox+6, oy+1): C_MID_PURPLE, (ox+7, oy+1): C_SHADOW_OUTLINE,
        (ox+1, oy+2): C_SHADOW_OUTLINE, (ox+2, oy+2): C_VIOLET, (ox+7, oy+2): C_VIOLET, (ox+8, oy+2): C_SHADOW_OUTLINE,
        (ox+0, oy+3): C_SHADOW_OUTLINE, (ox+1, oy+3): C_MID_PURPLE, (ox+8, oy+3): C_MID_PURPLE, (ox+9, oy+3): C_SHADOW_OUTLINE,
        (ox+0, oy+4): C_SHADOW_OUTLINE, (ox+1, oy+4): C_VIOLET, (ox+8, oy+4): C_VIOLET, (ox+9, oy+4): C_SHADOW_OUTLINE,
        (ox+0, oy+5): C_SHADOW_OUTLINE, (ox+1, oy+5): C_VIOLET, (ox+8, oy+5): C_VIOLET, (ox+9, oy+5): C_SHADOW_OUTLINE,
        (ox+0, oy+6): C_SHADOW_OUTLINE, (ox+1, oy+6): C_MID_PURPLE, (ox+8, oy+6): C_MID_PURPLE, (ox+9, oy+6): C_SHADOW_OUTLINE,
        (ox+1, oy+7): C_SHADOW_OUTLINE, (ox+2, oy+7): C_VIOLET, (ox+7, oy+7): C_VIOLET, (ox+8, oy+7): C_SHADOW_OUTLINE,
        (ox+2, oy+8): C_SHADOW_OUTLINE, (ox+3, oy+8): C_MID_PURPLE, (ox+6, oy+8): C_MID_PURPLE, (ox+7, oy+8): C_SHADOW_OUTLINE,
        (ox+4, oy+9): C_SHADOW_OUTLINE, (ox+5, oy+9): C_SHADOW_OUTLINE,
        
        # Inner Eye Shell
        (ox+3, oy+2): C_DARK_PURPLE, (ox+4, oy+2): C_VIOLET, (ox+5, oy+2): C_VIOLET, (ox+6, oy+2): C_DARK_PURPLE,
        (ox+2, oy+3): C_DARK_PURPLE, (ox+3, oy+3): C_BRIGHT_LILAC, (ox+4, oy+3): C_BRIGHT_LILAC, (ox+5, oy+3): C_BRIGHT_LILAC, (ox+6, oy+3): C_BRIGHT_LILAC, (ox+7, oy+3): C_DARK_PURPLE,
        (ox+2, oy+4): C_VIOLET, (ox+3, oy+4): C_BRIGHT_CYAN, (ox+4, oy+4): C_PALE_CYAN, (ox+5, oy+4): C_PALE_CYAN, (ox+6, oy+4): C_BRIGHT_CYAN, (ox+7, oy+4): C_VIOLET,
        (ox+2, oy+5): C_VIOLET, (ox+3, oy+5): C_BRIGHT_CYAN, (ox+4, oy+5): C_STAR_WHITE, (ox+5, oy+5): C_STAR_WHITE, (ox+6, oy+5): C_BRIGHT_CYAN, (ox+7, oy+5): C_VIOLET,
        (ox+2, oy+6): C_DARK_PURPLE, (ox+3, oy+6): C_BRIGHT_LILAC, (ox+4, oy+6): C_BRIGHT_LILAC, (ox+5, oy+6): C_BRIGHT_LILAC, (ox+6, oy+6): C_BRIGHT_LILAC, (ox+7, oy+6): C_DARK_PURPLE,
        (ox+3, oy+7): C_DARK_PURPLE, (ox+4, oy+7): C_VIOLET, (ox+5, oy+7): C_VIOLET, (ox+6, oy+7): C_DARK_PURPLE,
        
        # Center pupil spark
        (ox+4, oy+4): C_STAR_WHITE, (ox+5, oy+4): C_STAR_WHITE,
        (ox+4, oy+5): C_BRIGHT_CYAN, (ox+5, oy+5): C_STAR_WHITE,
    }
    
    for (px, py), col in pixels.items():
        im.putpixel((px, py), col)
        
    return im


def create_bg_dreamweaver():
    """32x32 action button background with cosmic dream theme."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    # Outer bezel / border
    # Dark border
    draw.rectangle([0, 0, 31, 31], fill=(12, 8, 24, 255))
    # Inset frame
    draw.rectangle([1, 1, 30, 30], fill=(28, 16, 52, 255))
    # Metallic dream border highlight (top & left)
    draw.line([(1, 1), (30, 1)], fill=(90, 50, 145, 255))
    draw.line([(1, 1), (1, 30)], fill=(90, 50, 145, 255))
    # Dark shadow (bottom & right)
    draw.line([(1, 30), (30, 30)], fill=(15, 10, 28, 255))
    draw.line([(30, 1), (30, 30)], fill=(15, 10, 28, 255))
    
    # Inner background field (2, 2) to (29, 29)
    for y in range(2, 30):
        for x in range(2, 30):
            # Distance from center (15.5, 15.5)
            dx = (x - 15.5) / 14.0
            dy = (y - 15.5) / 14.0
            dist = math.sqrt(dx*dx + dy*dy)
            
            # Swirling nebula angle
            angle = math.atan2(dy, dx)
            swirl = math.sin(angle * 3.0 + dist * 4.0) * 0.5 + 0.5
            
            # Radial falloff
            t = max(0.0, min(1.0, dist))
            
            # Base dark cosmic blue/violet
            r = int((24 + 35 * swirl) * (1.0 - t * 0.5))
            g = int((14 + 20 * swirl) * (1.0 - t * 0.5))
            b = int((50 + 60 * swirl) * (1.0 - t * 0.3))
            
            im.putpixel((x, y), (r, g, b, 255))
            
    # Constellation sparkles / dream dust
    sparkles = [
        (6, 7), (24, 8), (9, 22), (25, 23), (12, 11), (20, 18), (15, 8), (17, 24)
    ]
    for sx, sy in sparkles:
        im.putpixel((sx, sy), (180, 215, 255, 180))
        
    return im


def create_mind_touch():
    """Mind Touch: Shadowy claw reaching down touching an ethereal glowing psychic mind."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    # 1. Humanoid silhouette / mind target (bottom half, x: 10..22, y: 15..28)
    head_center = (16, 21)
    # Head circle
    draw.ellipse([11, 15, 21, 26], fill=C_DARK_PURPLE, outline=C_SHADOW_OUTLINE)
    # Neck / shoulders
    draw.polygon([(11, 25), (7, 29), (25, 29), (21, 25)], fill=C_DARK_PURPLE, outline=C_SHADOW_OUTLINE)
    
    # Inner glowing psyche / brain aura
    draw.ellipse([13, 17, 19, 23], fill=C_VIOLET)
    draw.ellipse([14, 18, 18, 22], fill=C_BRIGHT_LILAC)
    draw.point((16, 20), fill=C_PALE_LAVENDER)
    
    # 2. Dreamweaver Claws reaching from top-left (y: 3..17)
    # Palm / arm
    claw_lines = [
        [(8, 3), (11, 7), (13, 11)],     # wrist/hand
        [(13, 11), (15, 15), (16, 17)],  # main index finger touching top of head
        [(11, 9), (13, 13), (14, 16)],   # thumb
        [(14, 10), (17, 13), (18, 16)],  # middle finger
    ]
    
    for line in claw_lines:
        # Dark outline
        for i in range(len(line)-1):
            x1, y1 = line[i]
            x2, y2 = line[i+1]
            draw.line([(x1-1, y1), (x2-1, y2)], fill=C_SHADOW_OUTLINE, width=2)
            draw.line([(x1+1, y1), (x2+1, y2)], fill=C_SHADOW_OUTLINE, width=2)
            
    for line in claw_lines:
        for i in range(len(line)-1):
            draw.line([line[i], line[i+1]], fill=C_DARK_PURPLE, width=2)
            
    # Fingertips glowing with psychic dream-energy
    tips = [(16, 17), (14, 16), (18, 16)]
    for tx, ty in tips:
        im.putpixel((tx, ty), C_STAR_WHITE)
        for ox, oy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            im.putpixel((tx+ox, ty+oy), C_BRIGHT_CYAN)
            
    # Distortion ripple rings at point of contact (16, 17)
    draw.arc([12, 13, 20, 21], start=180, end=360, fill=C_BRIGHT_CYAN)
    draw.arc([10, 11, 22, 23], start=190, end=350, fill=C_BRIGHT_MAGENTA)
    draw.arc([7, 8, 25, 26], start=200, end=340, fill=(147, 51, 234, 180))
    
    return im


def create_dread_wave():
    """Dread Wave: Open nightmare eye radiating concentric dread shockwave arcs."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    cx, cy = 16, 16
    
    # Outer shockwave arc 3 (radius 13)
    draw.arc([cx-13, cy-13, cx+13, cy+13], 15, 75, fill=C_BRIGHT_CYAN, width=1)
    draw.arc([cx-13, cy-13, cx+13, cy+13], 105, 165, fill=C_BRIGHT_CYAN, width=1)
    draw.arc([cx-13, cy-13, cx+13, cy+13], 195, 255, fill=C_BRIGHT_CYAN, width=1)
    draw.arc([cx-13, cy-13, cx+13, cy+13], 285, 345, fill=C_BRIGHT_CYAN, width=1)
    
    # Middle shockwave ring 2 (radius 9)
    draw.arc([cx-9, cy-9, cx+9, cy+9], 0, 360, fill=C_VIOLET, width=1)
    for ang in [0, 60, 120, 180, 240, 300]:
        rad = math.radians(ang)
        px = int(cx + 9 * math.cos(rad))
        py = int(cy + 9 * math.sin(rad))
        im.putpixel((px, py), C_BRIGHT_MAGENTA)
        
    # Inner shockwave ring 1 (radius 6)
    draw.arc([cx-6, cy-6, cx+6, cy+6], 0, 360, fill=C_BRIGHT_LILAC, width=1)
    
    # Central Nightmare Eye
    # Dark outline
    draw.polygon([(cx-5, cy), (cx, cy-4), (cx+5, cy), (cx, cy+4)], fill=C_SHADOW_OUTLINE)
    # Magenta Sclera
    draw.polygon([(cx-4, cy), (cx, cy-3), (cx+4, cy), (cx, cy+3)], fill=C_MAGENTA)
    # Iris / Eye center
    draw.ellipse([cx-2, cy-3, cx+2, cy+3], fill=C_DARK_PURPLE)
    # Slit pupil
    draw.line([(cx, cy-2), (cx, cy+2)], fill=C_BLACK, width=1)
    # Pupil specular glint
    im.putpixel((cx-1, cy-1), C_STAR_WHITE)
    im.putpixel((cx, cy), C_BRIGHT_CYAN)
    
    # Shockwave distortion motes
    motes = [
        (cx-12, cy-7), (cx+11, cy-8), (cx-10, cy+11), (cx+12, cy+9),
        (cx, cy-14), (cx, cy+14), (cx-14, cy), (cx+14, cy)
    ]
    for mx, my in motes:
        im.putpixel((mx, my), C_PALE_CYAN)
        
    return im


def create_astral_walk():
    """Astral Walk: Shadow figure shifting into astral jaunt, dissolving into starry dream mist."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    # Humanoid shadow body traversing rightwards
    # Head & horns / ethereal crown
    head_x, head_y = 17, 8
    draw.ellipse([head_x-3, head_y-3, head_x+3, head_y+3], fill=C_SHADOW_OUTLINE)
    draw.ellipse([head_x-2, head_y-2, head_x+2, head_y+2], fill=C_DARK_PURPLE)
    # Glowing psychic eye slit
    im.putpixel((head_x+1, head_y-1), C_BRIGHT_CYAN)
    im.putpixel((head_x+2, head_y-1), C_STAR_WHITE)
    
    # Horn / dream antenna
    draw.line([(head_x-1, head_y-3), (head_x-3, head_y-6)], fill=C_VIOLET)
    draw.line([(head_x+1, head_y-3), (head_x+2, head_y-6)], fill=C_VIOLET)
    im.putpixel((head_x-3, head_y-6), C_BRIGHT_CYAN)
    im.putpixel((head_x+2, head_y-6), C_BRIGHT_CYAN)
    
    # Torso
    draw.polygon([(head_x-3, head_y+3), (head_x+3, head_y+3), (head_x+4, head_y+10), (head_x-2, head_y+10)], fill=C_SHADOW_OUTLINE)
    draw.polygon([(head_x-2, head_y+4), (head_x+2, head_y+4), (head_x+3, head_y+9), (head_x-1, head_y+9)], fill=C_DARK_PURPLE)
    
    # Core heart glow
    im.putpixel((head_x, head_y+6), C_VIOLET)
    im.putpixel((head_x+1, head_y+6), C_BRIGHT_LILAC)
    
    # Reaching forward arm
    draw.line([(head_x+3, head_y+5), (head_x+7, head_y+8), (head_x+9, head_y+7)], fill=C_SHADOW_OUTLINE, width=2)
    draw.line([(head_x+3, head_y+5), (head_x+7, head_y+8), (head_x+9, head_y+7)], fill=C_VIOLET, width=1)
    im.putpixel((head_x+9, head_y+7), C_BRIGHT_CYAN)
    
    # Lower body dissolving into astral wake / jaunt mist (trailing back to left)
    # Streamers of ethereal dream smoke
    streamers = [
        # (start_x, start_y, points)
        [(15, 18), (12, 20), (8, 22), (4, 25)],
        [(17, 19), (14, 23), (11, 26), (6, 28)],
        [(19, 18), (17, 22), (14, 26), (11, 28)],
        [(13, 16), (9, 18), (5, 20), (2, 21)],
    ]
    for st in streamers:
        for i in range(len(st)-1):
            col = C_VIOLET if i == 0 else (C_BRIGHT_CYAN if i == 1 else (C_DARK_PURPLE if i == 2 else (C_DARK_CYAN)))
            draw.line([st[i], st[i+1]], fill=col, width=2 if i < 2 else 1)
            
    # Sparkles & stars in the wake
    stars = [
        (4, 18), (7, 14), (10, 11), (5, 27), (10, 24), (22, 12), (25, 7), (23, 20)
    ]
    for sx, sy in stars:
        im.putpixel((sx, sy), C_STAR_WHITE)
        im.putpixel((sx+1, sy), C_BRIGHT_CYAN)
        im.putpixel((sx, sy+1), C_PALE_CYAN)
        
    return im


def create_mind_web():
    """Mind Web: Glowing geometric psionic spiderweb trapping a radiant consciousness orb."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    cx, cy = 16, 16
    
    # Radial web strands (8 directions)
    rad_angles = [0, 45, 90, 135, 180, 225, 270, 315]
    rad_len = 14
    for a in rad_angles:
        rad = math.radians(a)
        ex = int(cx + rad_len * math.cos(rad))
        ey = int(cy + rad_len * math.sin(rad))
        draw.line([(cx, cy), (ex, ey)], fill=(94, 38, 142, 200), width=1)
        
    # Concentric polygon web loops (3 tiers: r=5, r=9, r=13)
    for r, col in [(5, C_BRIGHT_LILAC), (9, C_VIOLET), (13, (125, 211, 252, 180))]:
        poly_pts = []
        for a in rad_angles:
            rad = math.radians(a)
            # Slight sag between nodes for realistic web curve
            px = int(cx + r * math.cos(rad))
            py = int(cy + r * math.sin(rad))
            poly_pts.append((px, py))
        poly_pts.append(poly_pts[0])
        for i in range(len(poly_pts)-1):
            draw.line([poly_pts[i], poly_pts[i+1]], fill=col, width=1)
            # Web junction node
            im.putpixel(poly_pts[i], C_BRIGHT_CYAN)
            
    # Trapped consciousness orb at center
    draw.ellipse([cx-4, cy-4, cx+4, cy+4], fill=C_DARK_PURPLE, outline=C_SHADOW_OUTLINE)
    draw.ellipse([cx-3, cy-3, cx+3, cy+3], fill=C_MAGENTA)
    draw.ellipse([cx-2, cy-2, cx+2, cy+2], fill=C_BRIGHT_MAGENTA)
    im.putpixel((cx-1, cy-1), C_STAR_WHITE)
    im.putpixel((cx, cy-1), C_STAR_WHITE)
    im.putpixel((cx, cy), C_PALE_LAVENDER)
    
    # Silken psychic threads binding the orb
    draw.line([(cx-4, cy-2), (cx+4, cy+2)], fill=C_BRIGHT_CYAN)
    draw.line([(cx-2, cy+4), (cx+2, cy-4)], fill=C_BRIGHT_CYAN)
    
    # Little dewdrop / dream sparks at corners
    for dx, dy in [(-11, -11), (11, -11), (-11, 11), (11, 11)]:
        im.putpixel((cx+dx, cy+dy), C_STAR_WHITE)
        
    return im


def create_nightmare_cascade():
    """Nightmare Cascade: Cosmic dream vortex / third eye tearing the reality veil with psionic storm."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    cx, cy = 16, 16
    
    # 1. Swirling Vortex Spiral Arms
    for arm in range(4):
        base_angle = arm * (math.pi / 2.0)
        points = []
        for step in range(16):
            t = step / 15.0
            r = 3.0 + t * 12.0
            theta = base_angle + t * 2.8
            px = int(cx + r * math.cos(theta))
            py = int(cy + r * math.sin(theta))
            points.append((px, py))
            
        for i in range(len(points)-1):
            t_col = i / float(len(points))
            if t_col < 0.3:
                c = C_STAR_WHITE
            elif t_col < 0.6:
                c = C_BRIGHT_CYAN
            elif t_col < 0.8:
                c = C_VIOLET
            else:
                c = C_DARK_PURPLE
            draw.line([points[i], points[i+1]], fill=c, width=2 if t_col < 0.5 else 1)
            
    # 2. Central Nightmare Eye of the Void
    draw.ellipse([cx-6, cy-4, cx+6, cy+4], fill=C_SHADOW_OUTLINE)
    draw.ellipse([cx-5, cy-3, cx+5, cy+3], fill=C_DARK_MAGENTA)
    draw.ellipse([cx-3, cy-2, cx+3, cy+2], fill=C_BRIGHT_MAGENTA)
    draw.ellipse([cx-2, cy-1, cx+2, cy+1], fill=C_STAR_WHITE)
    
    # 3. Psionic Lightning Bolts branching outward
    lightning_bolts = [
        [(13, 12), (10, 8), (6, 5), (3, 3)],
        [(19, 12), (23, 9), (27, 6), (29, 3)],
        [(13, 20), (9, 23), (5, 26), (2, 29)],
        [(19, 20), (22, 24), (26, 27), (30, 29)],
    ]
    for bolt in lightning_bolts:
        for i in range(len(bolt)-1):
            draw.line([bolt[i], bolt[i+1]], fill=C_PALE_CYAN if i == 0 else C_BRIGHT_CYAN, width=1)
            
    # 4. Shattered reality shards drifting
    shards = [
        [(7, 14), (9, 13), (8, 16)],
        [(24, 17), (26, 16), (25, 19)],
        [(15, 6), (17, 5), (16, 7)],
        [(16, 26), (18, 25), (17, 27)],
    ]
    for s in shards:
        draw.polygon(s, fill=C_STAR_WHITE, outline=C_VIOLET)
        
    return im


def create_psionic_node_organ():
    """Psionic Weaver Node organ sprite (32x32)."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    # Brain Organ Base Shape (centered, width ~20, height ~16, y: 7..24)
    # Lobes outline
    # Left hemisphere
    draw.ellipse([6, 8, 17, 22], fill=C_SHADOW_OUTLINE)
    # Right hemisphere
    draw.ellipse([14, 8, 25, 22], fill=C_SHADOW_OUTLINE)
    # Frontal lobes
    draw.ellipse([8, 6, 23, 16], fill=C_SHADOW_OUTLINE)
    
    # Inner dark crystalline fleshy mass
    draw.ellipse([7, 9, 16, 21], fill=C_DARK_PURPLE)
    draw.ellipse([15, 9, 24, 21], fill=C_DARK_PURPLE)
    draw.ellipse([9, 7, 22, 15], fill=(42, 24, 68, 255))
    
    # Convolutions / Sulci & Gyri (crevasses in violet and glowing cyan fissures)
    gyri = [
        # Left hemisphere sulci
        [(9, 10), (12, 12), (10, 15), (13, 17), (11, 20)],
        # Right hemisphere sulci
        [(22, 10), (19, 12), (21, 15), (18, 17), (20, 20)],
        # Longitudinal fissure (center dividing line)
        [(15, 7), (16, 11), (15, 16), (16, 21)],
    ]
    
    for g in gyri:
        for i in range(len(g)-1):
            draw.line([g[i], g[i+1]], fill=(25, 12, 40, 255), width=2)
            draw.line([g[i], g[i+1]], fill=C_VIOLET, width=1)
            
    # Glowing psionic synaptic nodes
    nodes = [
        (11, 11), (20, 11), (10, 16), (21, 16), (13, 14), (18, 14), (16, 9)
    ]
    for nx, ny in nodes:
        im.putpixel((nx, ny), C_STAR_WHITE)
        for ox, oy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            im.putpixel((nx+ox, ny+oy), C_BRIGHT_CYAN)
            
    # Central Pineal Dream Crystal (rhombus at center top)
    crystal_pts = [(15, 10), (18, 13), (15, 16), (12, 13)]
    draw.polygon(crystal_pts, fill=C_MAGENTA, outline=C_SHADOW_OUTLINE)
    draw.polygon([(15, 11), (17, 13), (15, 15), (13, 13)], fill=C_BRIGHT_LILAC)
    im.putpixel((15, 13), C_STAR_WHITE)
    
    # Trailing gossamer dream filaments / brainstem (y: 22..29)
    filaments = [
        [(15, 21), (14, 24), (13, 27), (12, 29)],
        [(16, 21), (16, 25), (15, 28)],
        [(17, 21), (18, 24), (19, 27), (20, 29)],
    ]
    for fil in filaments:
        for i in range(len(fil)-1):
            draw.line([fil[i], fil[i+1]], fill=C_MID_CYAN if i == 0 else C_BRIGHT_LILAC, width=1)
            
    return im


def create_dreamweaver_aura_frames():
    """4-frame animated mob overlay for Dreamweaver (32x32)."""
    frames = []
    
    for f in range(4):
        im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
        draw = ImageDraw.Draw(im)
        
        # Bobbing offset for the psychic triad / crown
        bob = int(math.sin(f * math.pi / 2.0) * 1.5)
        
        # 1. Ethereal Dream Crown (3 floating motes above head at y: 2..5 + bob, x: 12..20)
        # Center third eye star
        cx, cy = 16, 3 + bob
        im.putpixel((cx, cy), C_STAR_WHITE)
        im.putpixel((cx-1, cy), C_BRIGHT_CYAN)
        im.putpixel((cx+1, cy), C_BRIGHT_CYAN)
        im.putpixel((cx, cy-1), C_BRIGHT_CYAN)
        im.putpixel((cx, cy+1), C_BRIGHT_CYAN)
        
        # Left mote
        lx, ly = 12, 5 + bob + (1 if f % 2 == 1 else 0)
        im.putpixel((lx, ly), C_BRIGHT_LILAC)
        im.putpixel((lx, ly-1), C_PALE_LAVENDER)
        
        # Right mote
        rx, ry = 20, 5 + bob + (0 if f % 2 == 1 else 1)
        im.putpixel((rx, ry), C_BRIGHT_LILAC)
        im.putpixel((rx, ry-1), C_PALE_LAVENDER)
        
        # Subtle psychic halo curve connecting them
        draw.arc([11, 2+bob, 21, 8+bob], 200, 340, fill=(192, 132, 252, 120))
        
        # 2. Drifting dream mist wisps around shoulders / torso
        drift_x1 = 9 + (f % 3)
        drift_y1 = 14 + f
        draw.line([(drift_x1, drift_y1), (drift_x1-2, drift_y1-3)], fill=(147, 51, 234, 140), width=1)
        im.putpixel((drift_x1-2, drift_y1-3), C_BRIGHT_CYAN)
        
        drift_x2 = 22 - (f % 3)
        drift_y2 = 15 + ((f+2) % 4)
        draw.line([(drift_x2, drift_y2), (drift_x2+2, drift_y2-3)], fill=(219, 39, 119, 140), width=1)
        im.putpixel((drift_x2+2, drift_y2-3), C_PALE_CYAN)
        
        # Ground dream mist puddle (y: 28..31)
        mist_w = 10 + f % 2
        draw.ellipse([16 - mist_w//2, 28, 16 + mist_w//2, 30], fill=(74, 20, 110, 80))
        
        frames.append(im)
        
    return frames


def create_dream_web_trap():
    """Mind Web entanglement visual overlay (32x32)."""
    im = Image.new("RGBA", (32, 32), C_TRANSPARENT)
    draw = ImageDraw.Draw(im)
    
    # Cocooning psychic spiderweb wrapped around a humanoid figure (x: 8..24, y: 4..28)
    # Cross diagonal anchor lines
    anchors = [
        [(5, 5), (13, 12), (16, 16), (20, 21), (27, 27)],
        [(27, 5), (20, 11), (16, 16), (12, 22), (5, 27)],
        [(16, 2), (16, 10), (16, 22), (16, 30)],
        [(2, 16), (10, 16), (22, 16), (30, 16)],
    ]
    for anc in anchors:
        for i in range(len(anc)-1):
            draw.line([anc[i], anc[i+1]], fill=(147, 51, 234, 180), width=1)
            
    # Web rings
    for r in [6, 11]:
        draw.ellipse([16-r, 16-r, 16+r, 16+r], outline=(56, 189, 248, 160), width=1)
        
    # Dewdrop sparkles on nodes
    nodes = [(13, 12), (20, 11), (12, 22), (20, 21), (16, 10), (16, 22), (10, 16), (22, 16)]
    for nx, ny in nodes:
        im.putpixel((nx, ny), C_STAR_WHITE)
        im.putpixel((nx+1, ny), C_BRIGHT_CYAN)
        
    return im


def main():
    print("Generating Dreamweaver sprites...")
    
    # 1. Update antag_hud.dmi with 'dreamweaver' state
    hud_path = 'icons/mob/huds/antag_hud.dmi'
    hud_dmi = Dmi.from_file(hud_path)
    
    # Remove existing dreamweaver state if present to allow clean replacement
    hud_dmi.states = [s for s in hud_dmi.states if s.name != "dreamweaver"]
    
    dw_hud_state = State(hud_dmi, "dreamweaver")
    dw_hud_im = create_antag_hud_state()
    dw_hud_state.frame(dw_hud_im)
    hud_dmi.states.append(dw_hud_state)
    hud_dmi.to_file(hud_path)
    print(f"Updated {hud_path} with 'dreamweaver' HUD icon!")
    
    # 2. Create icons/mob/actions/actions_dreamweaver.dmi
    act_path = 'icons/mob/actions/actions_dreamweaver.dmi'
    act_dmi = Dmi(32, 32)
    
    actions = [
        ("bg_dreamweaver", create_bg_dreamweaver()),
        ("mind_touch", create_mind_touch()),
        ("dread_wave", create_dread_wave()),
        ("astral_walk", create_astral_walk()),
        ("mind_web", create_mind_web()),
        ("nightmare_cascade", create_nightmare_cascade()),
    ]
    
    for name, img in actions:
        st = State(act_dmi, name)
        st.frame(img)
        act_dmi.states.append(st)
        
    act_dmi.to_file(act_path)
    print(f"Created {act_path} with {len(actions)} action sprites!")
    
    # 3. Create icons/obj/antags/dreamweaver.dmi
    obj_path = 'icons/obj/antags/dreamweaver.dmi'
    obj_dmi = Dmi(32, 32)
    
    node_img = create_psionic_node_organ()
    node_st = State(obj_dmi, "psionic_node")
    node_st.frame(node_img)
    obj_dmi.states.append(node_st)
    
    obj_dmi.to_file(obj_path)
    print(f"Created {obj_path} with 'psionic_node'!")
    
    # 4. Create icons/mob/effects/dreamweaver_aura.dmi (animated)
    aura_path = 'icons/mob/effects/dreamweaver_aura.dmi'
    aura_dmi = Dmi(32, 32)
    
    aura_st = State(aura_dmi, "dreamweaver_aura", loop=0)
    for frame in create_dreamweaver_aura_frames():
        aura_st.frame(frame, delay=2)
    aura_dmi.states.append(aura_st)
    
    aura_dmi.to_file(aura_path)
    print(f"Created {aura_path} with animated 'dreamweaver_aura' (4 frames)!")
    
    # 5. Create icons/effects/dream_web.dmi
    web_path = 'icons/effects/dream_web.dmi'
    web_dmi = Dmi(32, 32)
    
    web_st = State(web_dmi, "web")
    web_st.frame(create_dream_web_trap())
    web_dmi.states.append(web_st)
    
    web_dmi.to_file(web_path)
    print(f"Created {web_path} with 'web'!")
    
    print("All sprites generated successfully!")


if __name__ == '__main__':
    main()
