# #152 capture smoke test

Keep **gamescope** `03-pipewire-prefer-dmabuf`. Polaris uses topic patches only
(`polaris/01`–`03`). Archived experimental / numbered series stay off.

Focus window required. Report `render_node`, format/modifier, `capture_transport`, `frame_residency`.

## Matrix

| Component | Version |
|-----------|---------|
| Polaris | **master** `2008458` + `polaris/01`–`03` |
| gamescope | `gamescope-hdr` with `01`–`03` |
| portal | `xdg-desktop-portal-gamescope` + `01-fix-stream-size` |

## Expect (known-good lea)

- `capture_transport=dmabuf` (or honest SHM fallback)
- HDR client: `xBGR_210LE` / p010, `stream_hdr_enabled=true` when force+metadata
- SDR client / forced SDR app: no force-HDR wash

## Do not

- Apply `archived/polaris/**` or old `0009` GL import
- Set `ENABLE_GAMESCOPE_WSI` / `ENABLE_HDR_WSI` for Proton
