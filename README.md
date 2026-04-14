# Custom Android Browser (No Chromium/WebView)

This project is a **from-scratch browser prototype** for Android.
It does **not** embed `WebView` and does not rely on Chromium rendering.

## What it does

- Fetches HTML over HTTP/HTTPS.
- Parses a small subset of HTML tags with a custom renderer.
- Displays rendered text content in a native Android `TextView`.

Supported tags in the custom renderer:

- Headings: `h1`, `h2`, `h3`
- Paragraphs and line breaks: `p`, `br`
- Inline style: `b`, `strong`, `i`, `em`
- Links: `a` (href appended next to link text)

## Important limitations

This is an educational custom engine, not a full modern web browser:

- No JavaScript engine.
- No CSS layout engine.
- No media/video playback pipeline.
- Limited HTML support.

## Run

1. Open in Android Studio.
2. Let Gradle sync.
3. Run on emulator/device (API 26+).
4. Enter a URL and tap **Go**.
