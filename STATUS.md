# Status

| Date | State |
|------|--------|
| 2026-07-14 | **HDR color OK** (user): close #1; remaining optional path = **WSI nested** (not attach/color) |
| 2026-07-14 | **05 runtime green on lea**: `convert_path=vulkan_cuda` 4K60 portal gamescope; livingroom **HDR Rec.2020+PQ** stable frames + good color; not on mmap |
| 2026-07-14 | **05 renamed**: `05-portal-dmabuf-vulkan-cuda.patch` (was `…-linear-mmap` — mmap is sticky fallback only) |
| 2026-07-14 | **05 = portal-only Vulkan bridge**: LINEAR DMA-BUF → GPU copy → exportable OPAQUE_FD → CUDA map; loud sticky `mmap_cuda` fallback |
| 2026-07-14 | **0014 split out**: optional `polaris/05` |
| 2026-07-13 | **Patch cleanup**: topic series under `polaris/` + `gamescope/`; old `0001`…`0015` + experimental → `archived/` |
| 2026-07-13 | **HDR OK on lea**: no ENABLE_*_WSI; XWayland + prefer xBGR_210LE + portal HDR |
| 2026-07-13 | **DmaBuf green**: `capture_transport=dmabuf`, portal LINEAR → Vulkan→CUDA |
| 2026-07-13 | Livingroom HDR + Bedroom SDR (client profiles); Bigscreen client HDR / forced SDR apps |

## Active patches (applied by flake)

See [polaris/README.md](polaris/README.md), [gamescope/README.md](gamescope/README.md).

| Package | Patches |
|---------|---------|
| polaris-stream | `01` portal · `02` HDR · `03` web · `04` force-8bit · `05` Vulkan→CUDA (on by default) |
| gamescope-hdr | `01` PW HDR meta · `02` headless colorimetry · `03` prefer dmabuf |
| xdg-desktop-portal-gamescope | `01` fix stream size |

## Archived (not applied)

| Tree | Why |
|------|-----|
| `archived/polaris/issue-152-series/` | Pre-topic rewrite; includes unused **0009** GL import |
| `archived/polaris/experimental/` | Early gist DmaBuf experiments; CUDA-EGL / cuImport dead on desktop NVIDIA |
| `archived/gamescope/pipewire-color-mgmt.patch` | Forced PQ paint — wash regression |

## Open work (GitHub Issues)

| # | Topic |
|---|--------|
| [#3](https://github.com/luxus/polaris-hdr-linux-patches/issues/3) | Web UI preview + path/mode clarity |
| [#4](https://github.com/luxus/polaris-hdr-linux-patches/issues/4) | Stream mode: Gamescope Stream peer of Private Stream |
| [#6](https://github.com/luxus/polaris-hdr-linux-patches/issues/6) | Gamescope **WSI nested** path (attach path is known-good; low priority) |

**Closed (2026-07-14):** [#1](https://github.com/luxus/polaris-hdr-linux-patches/issues/1) HDR color · [#2](https://github.com/luxus/polaris-hdr-linux-patches/issues/2) DMA-BUF · [#5](https://github.com/luxus/polaris-hdr-linux-patches/issues/5) Vulkan→CUDA

## Verified on lea

### 2026-07-14 morning (Vulkan bridge)

| Check | Result |
|-------|--------|
| `convert_path` | **`vulkan_cuda`** 3840×2160 (source imports cached; dest mapping persistent) |
| Capture | portal DmaBuf / gamescope headless HDR |
| Client | livingroom HDR, Rec.2020 + SMPTE 2084 PQ, 10-bit, metadata usable |
| Stability | stable frames (user-confirmed); no polaris Error/Warn in session window |
| Fallback | **not** on `mmap_cuda` |
| Dead ends closed | desktop `cuImport(DMABUF_FD)` + `cuGraphicsEGLRegisterImage` (Tegra-only) |

### 2026-07-13 evening

| Path | Result |
|------|--------|
| livingroom + client HDR + Bigscreen | HDR Rec.2020+PQ, dmabuf, encode OK |
| Bedroom + profile HDR off | SDR stream, works |
| Forced SDR Bigscreen app | `POLARIS_CLIENT_HDR=false` override path |
| Split encode `auto` | often mode=0 at 4K60; encode headroom fine |

**Still open:** Gamescope Stream UI mode (#4); WebUI path clarity (#3); optional WSI nested (#6). Attach path + color + encode stack are good on lea.
