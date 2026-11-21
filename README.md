# GlitchCrypt

A Wayland screensaver that **encrypts the text on your screen**.

When your machine goes idle, GlitchCrypt takes a snapshot of the screen and runs
OCR on it to find every line of text. Then it opens straight into a coarse,
dark, tinted, scanlined ghost of your desktop, where every line is already
cipher glyphs that keep reshuffling. Every few seconds a short
RGB-split slice glitch tears across the screen. It's calm on purpose:
slow-moving, not a strobe.

The glyphs are random, so they can't be decoded back into your text, and the
background is reduced so far that even text OCR missed can't be recovered.
Only the rough layout of your screen shows through. See [Privacy](#privacy).

| Before | After |
|---|---|
| ![A desktop with notes, a terminal, code and a calendar](docs/before.png) | ![The same desktop with every word replaced by cycling cipher glyphs](docs/after.png) |

*(The demo uses a made-up desktop drawn by [`docs/make-demo.py`](docs/make-demo.py).)*

> **Hands over to your lock screen.** GlitchCrypt isn't a locker itself. With
> *Lock when dismissed* on (the default), coming back with a key, click or
> mouse move locks the session first, so you land on your lock screen and not
> your desktop. GlitchCrypt keeps covering the screen until the session reports
> it's locked. If something else locks the session first, such as your shell's
> own idle lock, GlitchCrypt steps aside right away, and it never starts behind
> a lock screen, so you only ever unlock once. It uses `loginctl lock-session`, which DMS, GNOME, KDE and
> others respond to. For a locker that doesn't listen to logind, set
> `lock_command` in the config, e.g. `swaylock -f`.

## Requirements

- A Wayland compositor that [`grim`](https://sr.ht/~emersion/grim/) can capture,
  i.e. one with wlr-screencopy: niri, Sway, Hyprland, river, Wayfire and others.
  GNOME and KDE Plasma don't support it.
- `python3` with `pygame` and `Pillow`
- `tesseract` (with English data) for OCR
- `swayidle` for the idle trigger

```sh
# Debian / Ubuntu
sudo apt install python3-pygame python3-pil tesseract-ocr grim swayidle
# Arch
sudo pacman -S python-pygame python-pillow tesseract tesseract-data-eng grim swayidle
# Fedora
sudo dnf install python3-pygame python3-pillow tesseract grim swayidle
```

## Install

```sh
git clone https://github.com/phrag/GlitchCrypt.git && cd GlitchCrypt
./install.sh --enable
```

This installs:

- `glitchcrypt`, the screensaver, in `~/.local/bin`
- `glitchcrypt-settings`, a GTK 4 / libadwaita settings app, listed as
  **GlitchCrypt** in your app launcher
- `glitchcrypt.service`, a systemd user service that starts GlitchCrypt when
  you're idle (3 minutes by default) and stops it as soon as you're back

The service is `WantedBy=graphical-session.target`, which niri, Sway (via
`sway-systemd` or uwsm) and Hyprland (via uwsm) all start. In sessions where
`grim` can't capture the screen, such as GNOME or KDE, it exits quietly.

Uninstall with `./install.sh --uninstall`. Your settings in
`~/.config/glitchcrypt/` are kept.

## Settings

Open **GlitchCrypt** from your app launcher to change:

| Setting | Default | |
|---|---|---|
| Start when idle | on | Turns the idle service on or off |
| Start after | 3 min | Keep it shorter than your lock / screen-off timeout |
| Lock when dismissed | on | Lock the session when you come back (not for previews) |
| Lock after | 5 min | Lock anyway after this long on screen, even if untouched (0 = never) |
| Random colour | off | A new bright colour every time it starts, the same on all monitors |
| Colour | `#a9c7ff` | Tint and cipher characters, when random is off |
| Font | monospace | Drawn in bold |
| Background detail | 45 | Grid rows. Capped at 60 so text can't be recovered |
| Cipher characters | `0-9 A-F` + symbols | The alphabet the glyphs are drawn from |
| Scramble speed | 3.5 plugged in / 1.5 on battery | Character changes per second, per line |
| Frame rate | 20 plugged in / 6 on battery | Lower uses less power |
| Glitch effect | every ~6 s plugged in / ~15 s on battery | |

Motion has two profiles. **When plugged in** it's livelier, and **on
battery** it's calmer to save power. GlitchCrypt checks the power source every
few seconds and switches live. Either way, it only redraws the lines whose
characters actually changed, not the whole screen every frame.

Every monitor gets its own cover, from a snapshot of just that monitor, so an
external display never shows your live desktop.

Changes save automatically to `~/.config/glitchcrypt/config.ini` and apply the
next time GlitchCrypt starts. **Preview** runs it for 10 seconds. You can also
edit the file by hand. That's also where `lock_command` lives (default
`loginctl lock-session auto`). Invalid or out-of-range values fall back to
defaults or are clamped, and `glitchcrypt --print-config` shows what's in
effect.

## Command line

```sh
glitchcrypt                    # run now, until a key, click or mouse move
glitchcrypt --seconds 15       # preview for 15 s
glitchcrypt --tint '#ff6ac1'   # override the colour for this run
glitchcrypt --tint random      # a random colour for this run
glitchcrypt --image shot.png --output out.png   # render offscreen to a PNG
```

| Option | |
|---|---|
| `--tint HEX`, `--font NAME`, `--fps N` | Override the saved setting for this run |
| `--image FILE` | Use an image instead of the screen |
| `--seconds N` | Quit after N seconds |
| `--output PNG` | Render offscreen and save the last frame |
| `--idle` | Run swayidle with the configured delay (what the service runs) |
| `--print-config` | Show the effective settings as JSON |

## Privacy

GlitchCrypt is built to show as little of your screen as possible:

- **Nothing is written to disk.** The snapshot goes from `grim` into memory
  and on to tesseract through a pipe, with no temporary files.
- **Nothing is derived from your text.** The recognised text is thrown away
  at once. Words are merged into whole lines, and each line is widened to a
  coarse grid, so neither word lengths nor exact line lengths show. The
  glyphs are random.
- **The real screen is never shown, not even blurred.** Blurring isn't
  redaction: it can be partly reversed by deconvolution, and blurred text can
  be matched by blurring guesses the same way. GlitchCrypt instead averages
  the screen down to a grid 45 cells tall, so each cell is taller than a
  line of text and several characters wide. It then quantises every cell to
  one of 4 grey levels with random dither. That throws the detail away for good: about 2 bits per cell
  survive, which is enough to show "something is here" but nowhere near
  enough to hold text. OCR finishes before the window opens, so the very
  first frame is already fully encrypted.
- **It fails closed.** If the lock command doesn't lock the session, the
  covers stay up and it keeps retrying instead of uncovering your desktop.
  (If `lock_command` is broken, get out with `pkill -KILL -x glitchcrypt` from
  another TTY.) Plugging in a monitor, which would show your live desktop
  uncovered, counts as a touch and locks the session.
- **Its memory stays private.** It disables core dumps and marks itself
  non-dumpable, so other unprivileged processes can't attach to it or read
  its memory.
- **Nothing goes over the network.**

What's left visible: the rough layout of your screen (where windows and
blocks of text are, at grid resolution), the vertical position and height of
each text line, and roughly how long each line is, to within a grid cell.
Not a single character survives.

## How it works

1. `grim` captures the screen as PPM. That's fast, and it works even with
   grim builds that lack JPEG support.
2. `tesseract --psm 11` (sparse text) reads a grayscale copy from stdin and
   returns word boxes as TSV, which are merged into lines and snapped to the
   grid. This takes a second or two, and the window only opens once it's done.
3. pygame draws a fullscreen window. Each frame it shows the coarse, tinted
   background, fills each line box with the background colour and draws the
   cipher glyphs sized to the box. Every few seconds it blends in an
   RGB-split copy of a few slices of the screen.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
