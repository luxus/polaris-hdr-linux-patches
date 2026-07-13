# Status

| Date | State |
|------|--------|
| 2026-07-13 | **gamescope true-SDR**: force=0 → no HDR expose/EDID/2020/display LUTs |
| 2026-07-13 | **0012**: portal is_hdr gated on client HDR force file |
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

## Verified 2026-07-13 (lea)

**HDR switch (0011 portal metadata)** works:

| Client | Request | Log result |
|--------|---------|------------|
| Bedroom | no HDR (`dynamic_range=0`) | `stream_hdr_enabled=false`, SDR Rec.601/709 |
| livingroom | HDR on (`dynamic_range=1`) | `stream_hdr_enabled=true`, HDR Rec.2020 + PQ, metadata usable |

Still **washed / not HDMI-like on both** (Bedroom SDR feel + livingroom HDR-tagged). Capture still logs:

`Using 8-bit NV12 CUDA upload for capture path that cannot do 10-bit GPU frames` (`prefer_8bit` SHM path).

Next for [#1](https://github.com/luxus/polaris-hdr-linux-patches/issues/1): 10-bit encode path / transfer-function correctness, not more metadata stubs.

