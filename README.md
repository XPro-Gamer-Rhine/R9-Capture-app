# R9 Capture

By **Rhineul Islam**.

Screen capture & recording for macOS — with a cinematic twist. Part of the R9 family.

**Install (one line):**

```bash
curl -fsSL https://raw.githubusercontent.com/XPro-Gamer-Rhine/R9-Capture-app/main/install.sh | bash
```

## What it does

- **Screenshots** — full screen, drag-an-area, or every monitor stitched into one image
- **Recordings** — full screen or area, system audio and/or microphone (H.264,
  native Retina pixels, MP4 or MOV), with a live recorded-area outline and a
  floating pause / resume / stop bar (pausing leaves no gap in the file)
- **Focus key** — hold your chosen key while recording and the *video* smoothly zooms
  to your cursor, like the pros do in tech videos. Your actual screen never changes.
- **Radial annotate menu** — a hotkey pops a circular tool wheel at your cursor, live
  during recording: pen, highlighter, lines, arrows, squares, circles, message bubbles,
  emoji, a pixel ruler, a protractor, an eraser and a color palette. Hold ⇧ to snap
  lines perfectly straight (or to 45°). Esc stops drawing, ⌘Z undoes.
  The wheel itself never appears in your recording.
- **Multi-monitor** — pick monitors with a third hotkey, record them all at once, then
  arrange: side-by-side with a divider, seamless ultrawide, your true desktop layout,
  or free drag/resize — exported as ONE video (up to 8K).

100% Apple frameworks (ScreenCaptureKit + AVFoundation). No third-party code. Free.

## Permissions

- **Screen Recording** — required (macOS asks on first capture; reopen the app after allowing)
- **Microphone** — only if you switch the mic pill on
- **Accessibility** — only if you assign hotkeys (they need a global key listener)

Updates itself: the app checks this repo daily and offers one-click updates.
