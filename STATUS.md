# Status

| Date | State |
|------|--------|
| 2026-07-13 | **0007 PR candidate**: assume `adapter_name` when PW omits capture render_node (same-GPU DmaBuf) |
| 2026-07-13 | **Working flake** — packages + overlay published; experimental under `polaris/experimental/` (not applied) |
| 2026-07-13 | #152 test: master + rebased combined patch; gamescope prefer-dmabuf |
| 2026-07-12 | Research archive freeze |

## Outputs

- `overlays.default` / `packages.*.{polaris-stream,gamescope-hdr,xdg-desktop-portal-gamescope,polaris-nvidia-pin}`
- Polaris: master `2008458` + `combined.patch` + optional `0007-…-dmabuf.patch` (PR candidate)
- gamescope: all four patches including prefer-dmabuf
- Experimental polaris gist patches: archive only
