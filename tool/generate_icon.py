"""Generate AIMathTest app icon using Pillow (no Cairo needed)."""
from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
HALF = SIZE // 2

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Background: rounded rectangle with gradient effect
# Since Pillow doesn't do gradients natively, we'll simulate with bands
for y in range(SIZE):
    r = int(79 + (124 - 79) * y / SIZE)   # 4F -> 7C
    g = int(70 + (58 - 70) * y / SIZE)    # 46 -> 3A
    b = int(229 + (237 - 229) * y / SIZE)  # E5 -> ED
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

# Apply rounded corner mask
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=255)
img.putalpha(mask)

# Try to load a nice font, fall back to default
try:
    font_large = ImageFont.truetype("arial.ttf", 120)
    font_med = ImageFont.truetype("arialbd.ttf", 64)
    font_small = ImageFont.truetype("arialbd.ttf", 40)
    font_symbols = ImageFont.truetype("arial.ttf", 100)
    font_eyes = ImageFont.truetype("arialbd.ttf", 48)
except:
    font_large = ImageFont.load_default()
    font_med = font_large
    font_small = font_large
    font_symbols = font_large
    font_eyes = font_large

# Background math symbols (subtle)
sym_color = (255, 255, 255, 35)
draw.text((120, 130), "+", fill=sym_color, font=font_symbols)
draw.text((780, 160), "×", fill=sym_color, font=font_symbols)
draw.text((90, 760), "÷", fill=sym_color, font=font_symbols)
draw.text((800, 790), "π", fill=sym_color, font=font_symbols)
draw.text((140, 460), "∑", fill=(255, 255, 255, 25), font=font_symbols)
draw.text((810, 490), "%", fill=(255, 255, 255, 25), font=font_symbols)

# Robot head (rounded rectangle)
head_color = (255, 255, 255, 255)
head_border = (199, 210, 254, 255)
draw.rounded_rectangle([270, 280, 754, 700], radius=80, fill=head_color, outline=head_border, width=8)

# Antenna line
draw.line([(HALF, 280), (HALF, 200)], fill=head_border, width=12)
# Antenna ball
draw.ellipse([HALF - 25, 160, HALF + 25, 210], fill=(52, 211, 153, 255))
draw.ellipse([HALF - 12, 173, HALF + 12, 197], fill=(110, 231, 183, 255))

# Eyes
eye_color = (79, 70, 229, 255)  # #4F46E5
pupil_color = (30, 27, 75, 255)  # #1E1B4B
white = (255, 255, 255, 255)

# Left eye
draw.ellipse([345, 405, 455, 515], fill=eye_color)
draw.ellipse([378, 440, 414, 476], fill=white)  # highlight
draw.ellipse([380, 440, 420, 480], fill=pupil_color)

# Right eye
draw.ellipse([569, 405, 679, 515], fill=eye_color)
draw.ellipse([602, 440, 638, 476], fill=white)  # highlight
draw.ellipse([604, 440, 644, 480], fill=pupil_color)

# Smile (arc)
draw.arc([400, 510, 624, 640], start=10, end=170, fill=eye_color, width=14)

# Ear panels
draw.rounded_rectangle([228, 410, 278, 510], radius=20, fill=head_border)
draw.rounded_rectangle([746, 410, 796, 510], radius=20, fill=head_border)

# Math on forehead: "1+1"
bbox = draw.textbbox((0, 0), "1+1", font=font_med)
tw = bbox[2] - bbox[0]
draw.text((HALF - tw // 2, 310), "1+1", fill=eye_color, font=font_med)

# "AI" badge at bottom
badge_color = (52, 211, 153, 255)  # #34D399
draw.rounded_rectangle([430, 740, 594, 804], radius=32, fill=badge_color)
bbox = draw.textbbox((0, 0), "AI", font=font_small)
tw = bbox[2] - bbox[0]
draw.text((HALF - tw // 2, 752), "AI", fill=white, font=font_small)

# Save
out_path = os.path.join('assets', 'icon', 'app_icon.png')
# Flatten to RGB with background color for non-transparent version
bg = Image.new('RGBA', (SIZE, SIZE), (79, 70, 229, 255))
bg.paste(img, mask=img)
bg.save(out_path, 'PNG')
print(f'Generated {out_path} ({SIZE}x{SIZE})')

# Also generate adaptive icon foreground (with padding for Android adaptive)
adaptive = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
adaptive.paste(img, mask=img)
adaptive_path = os.path.join('assets', 'icon', 'app_icon_adaptive.png')
adaptive.save(adaptive_path, 'PNG')
print(f'Generated {adaptive_path} ({SIZE}x{SIZE})')
