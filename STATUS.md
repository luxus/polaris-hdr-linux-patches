# Status

| Date | State |
|------|--------|
| 2026-07-14 | **05 10-bit restore (code)**: CUDA EnumFormat again offers LINEAR `xBGR_210LE`; vulkan_cuda accepts XB30; `prefer_8bit_encode=false` + CUDA `RGBA_to_P010` for HDR. **Runtime spa 81 + P010 not yet re-verified on lea.** |
| 2026-07-14 | **Session apps cleaned**: keep `Steam Bigscreen (gamescope HDR+WSI)` + `1 Baldur's Gate 3 (gamescope HDR+WSI)`; drop noWSI/forced-SDR/AC6 experimental session entries (local apps.json). |
| 2026-07-14 | **WSI nested OK** (lea, desktop Steam→gamescope→AC6): full FROG WSI hook + HDR10 swapchain; colors good (user); not Polaris attach |
| 2026-07-14 | **HDR color OK** (user): close #1; remaining optional path = **WSI nested** (not attach/color) |
| 2026-07-14 | **05 runtime green on lea** (earlier): `convert_path=vulkan_cuda` 4K60; note later BGRx-only regression until 10-bit restore above |
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
| [#6](https://github.com/luxus/polaris-hdr-linux-patches/issues/6) | Gamescope **WSI nested** path — desktop Steam+gamescope+AC6 proven 2026-07-14; Polaris session wiring still open |

**Closed (2026-07-14):** [#1](https://github.com/luxus/polaris-hdr-linux-patches/issues/1) HDR color · [#2](https://github.com/luxus/polaris-hdr-linux-patches/issues/2) DMA-BUF · [#5](https://github.com/luxus/polaris-hdr-linux-patches/issues/5) Vulkan→CUDA

## Verified on lea

### 2026-07-14 evening (nested WSI — desktop Steam, not Polaris attach)

Topology: Steam on **KWin**; game launch options nest **gamescope-hdr 3.16.24** as parent of Proton. Headless `polaris-hdr-idle` gamescope was also running but was **not** the presentation path.

| Check | Result |
|-------|--------|
| Launch | `DXVK_HDR=1 gamescope --force-grab-cursor --cursor-scale-height 2160 -W 5120 -H 2160 -r 75 -f --hdr-enabled -- %command%` |
| Title | Armored Core VI (`1888160`), GE-Proton11-1, `armoredcore6.exe` |
| Child env | `ENABLE_GAMESCOPE_WSI=1`, `GAMESCOPE_WAYLAND_DISPLAY=/run/pressure-vessel/gamescope-socket`, `DISPLAY=:3`; **no** `WAYLAND_DISPLAY` on game; **no** `ENABLE_HDR_WSI` |
| WSI sequence | full success: Application info → Creating/Made Gamescope surface → Creating/Created swapchain for xid (no `non-Gamescope` warning) |
| Surface state | `server hdr output enabled: true`, `hdr formats exposed to client: true`, steam app id `1888160` |
| HDR swapchain | progressed to `VK_FORMAT_A2B10G10R10_UNORM_PACK32` + `VK_COLOR_SPACE_HDR10_ST2084_EXT`; `VkHdrMetadataEXT` present; refresh ~13.33 ms (75 Hz) |
| Color (user) | **looks excellent** |
| Noise (harmless) | `Atom of T was wrong type`; nested X0–X2 bind fails (idle session already holds them); Proton helpers also load the layer |
| Not verified here | portal/PipeWire capture of this nested instance; Polaris session nested mode; attach path unchanged |

See [docs/polaris-wsi-plan.md](docs/polaris-wsi-plan.md) evidence section.

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

**Still open:** Gamescope Stream UI mode (#4); WebUI path clarity (#3); optional WSI nested (#6) for **Polaris session wiring** (desktop nested WSI + HDR color already green on lea). Attach path + portal color + encode stack remain the default known-good path.
