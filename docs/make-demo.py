#!/usr/bin/env python3
"""Draw a fake desktop (docs/before.png) so the README demo shows no real screen.

Then:  ./glitchcrypt --image docs/before.png --output docs/after.png --seconds 4
"""
import os
import subprocess

from PIL import Image, ImageDraw, ImageFont

W, H = 1600, 1000
HERE = os.path.dirname(os.path.abspath(__file__))


def font(style, size):
    path = subprocess.run(["fc-match", "-f", "%{file}", style],
                          capture_output=True, text=True).stdout.strip()
    return ImageFont.truetype(path, size)


mono, sans, bold = font("monospace", 20), font("sans", 21), font("sans:bold", 24)
img = Image.new("RGB", (W, H), "#1b2433")
d = ImageDraw.Draw(img)

# top bar
d.rectangle([0, 0, W, 40], fill="#0f141d")
d.text((20, 9), "Activities", font=sans, fill="#d8dee9")
d.text((W // 2 - 60, 9), "Thu 14:32", font=sans, fill="#d8dee9")
d.text((W - 190, 9), "Wi-Fi  87%", font=sans, fill="#d8dee9")


def window(x, y, w, h, title, lines, f, fg, bg="#fafafa", step=30):
    d.rounded_rectangle([x, y, x + w, y + h], 12, fill=bg)
    d.rounded_rectangle([x, y, x + w, y + 44], 12, fill="#e4e7ec" if bg != "#11161f" else "#222a38")
    d.text((x + 18, y + 10), title, font=bold, fill="#333" if bg != "#11161f" else "#cfd6e2")
    for i, line in enumerate(lines):
        d.text((x + 24, y + 64 + i * step), line, font=f, fill=fg)


window(60, 80, 760, 520, "notes.md", [
    "Weekend plans",
    "",
    "Saturday: repair the bike chain and buy new",
    "brake pads before the long ride on Sunday.",
    "Call the bakery about the birthday cake order,",
    "chocolate with raspberries, ready by noon.",
    "",
    "Reading list",
    "The lighthouse keeper's journal, chapter four.",
    "Notes on building small, quiet software.",
    "Water the tomatoes every second evening.",
], sans, "#20252d", step=38)

window(880, 80, 660, 430, "terminal", [
    "$ uptime",
    " 14:32:07 up 3 days,  2:11,  load 0.42",
    "$ ls ~/photos/2026",
    "harbour.jpg  market.jpg  sunset.jpg",
    "$ git status",
    "On branch main",
    "nothing to commit, working tree clean",
    "$ echo hello world",
    "hello world",
], mono, "#9fe0a8", bg="#11161f", step=34)

window(880, 560, 660, 380, "main.py", [
    "def greet(name):",
    "    message = f'Hello, {name}!'",
    "    print(message)",
    "    return message",
    "",
    "for person in ['Ada', 'Linus', 'Grace']:",
    "    greet(person)",
], mono, "#1c2b4a", step=36)

window(60, 650, 760, 290, "Calendar", [
    "09:00  Stand-up meeting",
    "11:30  Dentist appointment",
    "15:00  Coffee with Sam at the corner cafe",
    "19:00  Football practice",
], sans, "#20252d", step=44)

out = os.path.join(HERE, "before.png")
img.save(out)
print(out)
