# R9 Capture

By **Rhineul Islam**.

Screen capture & recording — with a cinematic twist. Part of the R9 family.

**Install (one line):**

macOS
```bash
curl -fsSL https://raw.githubusercontent.com/XPro-Gamer-Rhine/R9-Capture-app/main/install.sh | bash
```

Windows 10 (1903+) / 11 — in PowerShell
```powershell
irm https://raw.githubusercontent.com/XPro-Gamer-Rhine/R9-Capture-app/main/install.ps1 | iex
```

## What it does

- **Screenshots** — full screen, drag-an-area, or every monitor stitched into one image
- **Recordings** — full screen or area, system audio and/or microphone mixed into one
  track (H.264, native pixels, MP4 or MOV), with a live recorded-area outline, a
  countdown before you go live and a floating pause / resume / stop bar (pausing
  leaves no gap in the file)
- **Focus key** — hold your chosen key while recording and the *video* smoothly zooms
  to your cursor, like the pros do in tech videos. Your actual screen never changes.
- **Radial annotate menu** — a hotkey pops a circular tool wheel at your cursor, live
  during recording: pen, highlighter, lines, arrows, squares, circles, message bubbles,
  text, emoji, step numbers, a pixel ruler, redaction, a spotlight, a live magnifier,
  an eraser and a colour palette. Hold ⇧ to snap lines perfectly straight (or to 45°).
  Esc stops drawing. The wheel itself never appears in your recording.
- **Face cam** — a live webcam bubble, draggable and resizable, circle or rounded,
  recorded right into your video.
- **Multi-monitor** — record every monitor at once, then arrange: side by side with a
  divider, seamless ultrawide, stacked, a grid, or your true desktop layout —
  exported as ONE video (up to 8K).
- **Shortcuts** — assign your own keys for recording, screenshots and pause/resume.
  They work anywhere, any time.

100% platform frameworks, no third-party code, free.

- macOS: ScreenCaptureKit + AVFoundation
- Windows: Windows.Graphics.Capture, Direct3D 11, Media Foundation and WASAPI

## Permissions

- **macOS** — Screen Recording is required (macOS asks on first capture; reopen the app
  after allowing). Microphone only if you switch the mic pill on. Accessibility only if
  you assign hotkeys.
- **Windows** — none. Screen capture, the microphone and the global keys are all things
  a normal Windows program may simply do. Windows asks once for the camera if you turn
  the face-cam bubble on.

Updates itself: the app checks this repo daily and offers one-click updates.
