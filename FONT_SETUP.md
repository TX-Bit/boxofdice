# Fonts — using the real iOS fonts

The whole app draws text through **one** value: `AppFont` in
`app/src/main/java/com/example/boxofdice/ui/theme/GameTheme.kt`. Right now it uses
**Fredoka** via downloadable Google Fonts (needs Play Services + network). You chose
to supply the real iOS fonts instead — here's how.

## 1. Drop the font files into `app/src/main/res/font/`

Rules for Android font resources:
- File type must be **.ttf or .otf** (NOT `.ttc` — see note below).
- File names: **lowercase letters, digits, underscore only** (no spaces/capitals).

Recommended — **SF Pro Rounded** (the carved-numeral font that gives the iOS feel).
Get "SF Pro" from <https://developer.apple.com/fonts/> (free for developers), then
copy + rename:

| From the SF Pro download        | Rename to (in res/font/) |
|---------------------------------|--------------------------|
| SF-Pro-Rounded-Regular.otf      | `app_font_regular.otf`   |
| SF-Pro-Rounded-Medium.otf       | `app_font_medium.otf`    |
| SF-Pro-Rounded-Semibold.otf     | `app_font_semibold.otf`  |
| SF-Pro-Rounded-Bold.otf         | `app_font_bold.otf`      |
| SF-Pro-Rounded-Heavy.otf        | `app_font_black.otf`     |

One file is enough to start (at minimum `app_font_bold.otf`); more weights = better.

**`.ttc` note:** macOS ships American Typewriter / Avenir Next as `.ttc`
collections, which Android can't use directly. Either choose a font that comes as
`.otf`/`.ttf` (SF Pro Rounded above), or extract one weight to `.ttf` first with
fonttools: `pip install fonttools` then `fonttools ttLib.unpackTTC Font.ttc`.

**Licensing:** Apple's fonts are licensed for Apple platforms — fine for your own
local build, but don't ship them in a Play Store release.

## 2. Tell me — I'll switch `AppFont`

Once the files are in place I'll set `AppFont` to:

```kotlin
val AppFont = FontFamily(
    Font(R.font.app_font_regular,  FontWeight.Normal),
    Font(R.font.app_font_medium,   FontWeight.Medium),
    Font(R.font.app_font_semibold, FontWeight.SemiBold),
    Font(R.font.app_font_bold,     FontWeight.Bold),
    Font(R.font.app_font_black,    FontWeight.Black),
)
```

and remove the `ui-text-google-fonts` dependency + `font_certs.xml`. Everything
(score, tiles, buttons, headings) updates automatically.
