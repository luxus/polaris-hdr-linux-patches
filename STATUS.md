# Status

| Date | State |
|------|--------|
| 2026-07-15 | **Host color polish (not iPhone rootcause)**: `02` Rec.2020 stub primaries exact (35400/14600, 8500/39850, 6550/2300 + D65). `05` P010 uses `new_color_vectors_from_colorspace` (10-bit code values) instead of UNORM+245/255. Gamescope Color A+B left as-is (user undecided on PQ). |
| 2026-07-15 | **CUDA letterbox black fill**: `05` clears full Y/UV (Y=0, UV mid) before viewport convert — fixes green aspect-ratio bars on all clients. CUDA build OK; needs host switch to run. |
| 2026-07-14 | **Color A+B (active)**: A = ColorMgmt LUTs (`04`); B = IceDOS `postPatch` (`outputEncodingEOTF=PQ` when HDR, pin sdrGamut=0 / nits=203). A alone: reds much better, slightly pale. Retest pale/wash with B. |
| 2026-07-14 | **Color A result**: LUTs alone fixed oversaturated reds/torches (user: 10000× better); path still spa81/P010/`vulkan_cuda`. |
| 2026-07-14 | **Polaris nested WSI + HDR + P010 green (lea)**: BP session `POLARIS_GAMESCOPE_WSI=1` → BG3 (`1086940`) under nested gamescope; portal `spa_format=81` / `xBGR_210LE` → `vulkan_cuda` `src_xb30=true` **`dst_p010=true`**; Rec.2020+PQ 10-bit; user picture OK in HDR |
| 2026-07-14 | **05 P010 convert fix**: CUDA hw frames use `frame->format=AV_PIX_FMT_CUDA`; must use `sw_format` for P010 vs NV12. Prior bug wrote NV12 into P010 → green/pink chroma |
| 2026-07-14 | **05 set_frame P010**: `cuda_dmabuf_t` accepts NV12+P010 (base `cuda_t` is NV12-only) so HDR sessions connect |
| 2026-07-14 | **05 10-bit restore**: CUDA EnumFormat offers LINEAR `xBGR_210LE`; vulkan_cuda accepts XB30; `prefer_8bit_encode=false` + `RGBA_to_P010` |
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
| gamescope-hdr | `01` PW HDR meta · `02` headless colorimetry · `03` prefer dmabuf · `04` ColorMgmt LUTs · postPatch EOTF_PQ |
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
| [#6](https://github.com/luxus/polaris-hdr-linux-patches/issues/6) | Gamescope **WSI nested** polish — desktop AC6 + Polaris BP→BG3 WSI+HDR+P010 proven 2026-07-14; remaining = session packaging/docs, not capture stack |

## 2026-07-15 — iPhone / VoidLink teal–magenta colors (handoff)

**Not a host-global color regression.** Mac + livingroom OK on portal/gamescope HDR; iPhone wrong; **same iPhone OK on labwc SDR H.264**.

Full write-up: [`docs/handoff-iphone-color-2026-07-15.md`](docs/handoff-iphone-color-2026-07-15.md)

| Control | Path | iPhone colors |
|---------|------|---------------|
| BAD | gamescope → portal → `vulkan_cuda` XB30→P010 → HEVC Main10 HDR PQ | teal/magenta |
| GOOD | labwc cage → wlr bgra8 → H.264 SDR Rec.601 | correct |

Ruled out for this bug: color_range 0/1/2, `hevc_mode=3` alone, HEVC vs AV1. Do not re-cap `max_bitrate` without explicit ask (agent experiment, not baseline).

**Closed (2026-07-14):** [#1](https://github.com/luxus/polaris-hdr-linux-patches/issues/1) HDR color · [#2](https://github.com/luxus/polaris-hdr-linux-patches/issues/2) DMA-BUF · [#5](https://github.com/luxus/polaris-hdr-linux-patches/issues/5) Vulkan→CUDA

## Verified on lea

### 2026-07-14 late evening (Polaris nested WSI + portal 10-bit P010)

Topology: Moonlight **livingroom** → Polaris app **`Steam Bigscreen (gamescope HDR+WSI)`** (`POLARIS_GAMESCOPE_WSI=1`) → nested headless gamescope + Steam BP → **Baldur's Gate 3** (`AppId=1086940`, `bg3`) launched from BP.

| Check | Result |
|-------|--------|
| Session start | `Executing Do Cmd: [env POLARIS_GAMESCOPE_WSI=1 …/polaris-hdr-session start]` |
| App | `Session resuming for app [Steam Bigscreen (gamescope HDR+WSI)]` → `CLIENT CONNECTED` / `stream_active` livingroom |
| BG3 child env | `ENABLE_GAMESCOPE_WSI=1`, `GAMESCOPE_WAYLAND_DISPLAY=/run/pressure-vessel/gamescope-socket`, `DISPLAY=:2`, `DXVK_HDR=1`; **no** host `WAYLAND_DISPLAY`; `DISABLE_HDR_WSI=1` (FROG layer only) |
| Capture | `spa_format=81` · `Spa:Enum:VideoFormat:xBGR_210LE` · LINEAR modifier=0 · `capture_transport=dmabuf` · `frame_residency=gpu` |
| Convert | `CUDA DMABUF: convert_path=vulkan_cuda 3840x2160 … fourcc=0x30334258 (XB30) src_xb30=true dst_p010=true` |
| Encode / color | `target_format=p010` · `Color depth: 10-bit` · `HDR (Rec. 2020 + SMPTE 2084 PQ)` · `stream_hdr_enabled=true` |
| User | picture present, **HDR**; green/pink gone after `sw_format` P010 fix |
| Errors during stream | none (`Error:` / `mmap_cuda` / FALLBACK absent after connect) |

Fixes that unblocked this path (commits on main):

1. `45c34bd` — restore 10-bit xBGR / `RGBA_to_P010` / `prefer_8bit_encode=false` on portal dmabuf device  
2. `6de55c6` — `cuda_dmabuf_t::set_frame` accepts P010 (stop connect abort)  
3. `31d2cc2` — detect P010 via **hwframe `sw_format`**, not `frame->format` (stop NV12-into-P010 green/pink)

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

**Still open:** Gamescope Stream UI mode (#4); WebUI path clarity (#3); WSI nested (#6) polish/packaging (capture+encode stack green on lea for BP→BG3). Attach path remains the default known-good non-nested path; portal color + P010 encode verified on the nested WSI session path as well.
