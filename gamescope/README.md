# gamescope-hdr patches

Wired by `pkgs/gamescope-hdr` (nixpkgs gamescope + **`enableWsi = true` always**).

| Patch / hook | Topic |
|--------------|--------|
| `01` | PipeWire HDR metadata |
| `02` | Headless HDR colorimetry / force-HDR flags |
| `03` | Prefer `SPA_DATA_DmaBuf` |
| `04` | **A:** `paint_pipewire` uses `g_ColorMgmtLuts` |
| package `postPatch` | **B:** `EOTF_PQ` when HDR + pin SDR-on-HDR nits/gamut |

## Notes

- **A+B is the measured HDR path.** Do not strip without a livingroom/Mac A/B.
- **WSI stays built on.** Plain XWayland attach has been unreliable here; nested WSI is kept available. Building the layer ≠ enabling it on every Proton env — session wiring decides runtime `ENABLE_GAMESCOPE_WSI`.
- Nested WSI evidence/plan: [docs/polaris-wsi-plan.md](../docs/polaris-wsi-plan.md) (#6).
