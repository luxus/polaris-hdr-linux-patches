# Status

| Date | State |
|------|--------|
| 2026-07-13 | **0011**: portal reports HDR metadata (client HDR switch can engage) |
| 2026-07-13 | **0010**: persist Web UI auth sessions across polaris restart |
| 2026-07-13 | **0007 PR candidate**: assume `adapter_name` when PW omits capture render_node (same-GPU DmaBuf) |
| 2026-07-13 | **Working flake** — packages + overlay published; experimental under `polaris/experimental/` (not applied) |
| 2026-07-13 | #152 test: master + rebased combined patch; gamescope prefer-dmabuf |
| 2026-07-12 | Research archive freeze |

## Outputs

- `overlays.default` / `packages.*.{polaris-stream,gamescope-hdr,xdg-desktop-portal-gamescope,polaris-nvidia-pin}`
- Polaris: master `2008458` + `combined.patch` + optional `0007-…-dmabuf.patch` (PR candidate)
- gamescope: all four patches including prefer-dmabuf
- Experimental polaris gist patches: archive only

## Open work (GitHub Issues)

| # | Topic |
|---|--------|
| [#1](https://github.com/luxus/polaris-hdr-linux-patches/issues/1) | HDR color / real HDR vs SDR |
| [#2](https://github.com/luxus/polaris-hdr-linux-patches/issues/2) | Native DMA-BUF (replace SHM) |
| [#3](https://github.com/luxus/polaris-hdr-linux-patches/issues/3) | Web UI preview + path/mode |

Upstream polaris: [papi-ux/polaris#206](https://github.com/papi-ux/polaris/issues/206) (restart UI flaky), [#207](https://github.com/papi-ux/polaris/pull/207) (session persist).
