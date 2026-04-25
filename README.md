# Xbox Elite Series 2 — White (Core) Skin

A whitemod of [Cinzya/xbox-elite2-skin](https://github.com/Cinzya/xbox-elite2-skin) styled to match the **Xbox Elite Series 2 Core (White)** controller for use with https://gamepadviewer.com.

## Preview

![Preview](preview.png?raw=true "Preview")

## How to use

On gamepadviewer.com, paste the raw URL of `elite2.css` (hosted via GitHub Pages or similar) into the custom CSS field on the URL-generation dialog.

## How the recolor works

The original skin assets are recolored by `scripts/whitemod.ps1` (PowerShell + System.Drawing, no dependencies):

- **Inverted** to white: `A/B/X/Y`, `Start/Select`, both `Bumper`s, both `Trigger`s.
- **Untouched**: `Stick Left/Right` (black-topped sticks already match the Core), `dpad` (already grayscale), all `F-*` fightstick assets.
- **Polygon-masked invert** for `base.png` and `base-disconnect.png`: the controller body region is inverted (black → white), while the diamond-textured grip area is left as the original black.

The polygon defining the white body lives at the top of `whitemod.ps1` — adjust the vertices and re-run if you want a different grip/body split.

## Regenerate

```powershell
powershell.exe -ExecutionPolicy Bypass -File scripts/whitemod.ps1
powershell.exe -ExecutionPolicy Bypass -File scripts/build-preview.ps1
```

## Credit

- Original skin: [Cinzya/xbox-elite2-skin](https://github.com/Cinzya/xbox-elite2-skin)
- Underlying gamepad viewer: https://gamepadviewer.com (mrmcpowned)
