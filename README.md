# AikaTrail website

AikaTrail's website: the app's home page (`index.html`), with its features, screenshots, answers to common questions, and support contact, and its [privacy policy](privacy.html). GitHub Pages serves it from the root of this repository (Settings → Pages → Deploy from a branch → `main`, `/ (root)`). `.nojekyll` makes Pages publish the files as they are, with no Jekyll build. Support requests go to konsta.support@gmail.com.

The site root also serves as the Support URL and `privacy.html` as the Privacy Policy URL wherever the app is distributed, such as App Store Connect, and the app should link to the privacy policy. Verify both public URLs after deployment, and keep the policy aligned with the app's data handling.

The screenshots in `images/` are web-sized JPEG copies (plus `thumbs/` thumbnails and `full/` full-resolution copies for the zoomed view) of the raw simulator captures in the app repository's `design/app-store/*/raw/`; the device frames are drawn by CSS. After new captures, run `tools/prepare-images.sh [path to the app repository]` (macOS, uses `sips`; the default path is `../productivity-tracker`). The device switch and captions are listed in the `SHOTS` table at the end of `index.html`.

Preview locally: `python3 -m http.server 8765`, then open http://localhost:8765/.

Licensing: the pages use only the visitor's system font (nothing is embedded or downloaded), draw their own icons and device frames, and load no external scripts, styles, or fonts. Keep it that way: an icon or font from a set (for example Lucide or SF Symbols) brings that set's license terms with it.
