# Status

| Date | State |
|------|--------|
| 2026-07-14 | **0014 split out**: optional `polaris/05` |
| 2026-07-14 | **05 = CUDA import**: `cuImportExternalMemory` + pitch2D + RGBA_to_NV12 (not GL); default on for lea A/B |
| 2026-07-13 | **Patch cleanup**: topic series under `polaris/` + `gamescope/`; old `0001`…`0015` + experimental → `archived/` |
| 2026-07-13 | **HDR OK on lea**: no ENABLE_*_WSI; XWayland + prefer xBGR_210LE + portal HDR |
| 2026-07-13 | **DmaBuf green**: `capture_transport=dmabuf`, EGL import OK, p010 encode |
| 2026-07-13 | Livingroom HDR + Bedroom SDR (client profiles); Bigscreen client HDR / forced SDR apps |

## Active patches (applied by flake)

See [polaris/README.md](polaris/README.md), [gamescope/README.md](gamescope/README.md).

| Package | Patches |
|---------|---------|
| polaris-stream | `01` portal (SHM default) · `02` HDR · `03` web · `04` force-8bit · optional `05` LINEAR DmaBuf |
| gamescope-hdr | `01` PW HDR meta · `02` headless colorimetry · `03` prefer dmabuf |
| xdg-desktop-portal-gamescope | `01` fix stream size |

## Archived (not applied)

| Tree | Why |
|------|-----|
| `archived/polaris/issue-152-series/` | Pre-topic rewrite; includes unused **0009** GL import |
| `archived/polaris/experimental/` | Early gist DmaBuf experiments |
| `archived/gamescope/pipewire-color-mgmt.patch` | Forced PQ paint — wash regression |

## Open work (GitHub Issues)

| # | Topic |
|---|--------|
| [#1](https://github.com/luxus/polaris-hdr-linux-patches/issues/1) | HDR color / real HDR vs SDR (parity with HDMI) |
| [#2](https://github.com/luxus/polaris-hdr-linux-patches/issues/2) | Native DMA-BUF polish (mostly done on lea) |
| [#3](https://github.com/luxus/polaris-hdr-linux-patches/issues/3) | Web UI preview + path/mode clarity |
| [#4](https://github.com/luxus/polaris-hdr-linux-patches/issues/4) | Stream mode: Gamescope Stream peer of Private Stream |

## Verified on lea (2026-07-13 evening)

| Path | Result |
|------|--------|
| livingroom + client HDR + Bigscreen | HDR Rec.2020+PQ, p010, dmabuf, encode OK |
| Bedroom + profile HDR off | SDR stream, works |
| Forced SDR Bigscreen app | `POLARIS_CLIENT_HDR=false` override path |
| Split encode `auto` | often mode=0 at 4K60; encode headroom fine |

**Still open:** HDMI-like color (#1); Gamescope Stream as first-class UI mode (#4); dual labwc/gamescope switch product.
