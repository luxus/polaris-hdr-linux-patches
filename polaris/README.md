# Polaris patches

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal base, HDR, web, force-8bit |
| `06` (`06-session-hdr-force-sync.patch`) | always | write `polaris-hdr-force` from `enable_hdr` + stream `dynamicRange`; try-restart idle gamescope when force flips (skip if nested WSI) |
| `05` (`05-portal-dmabuf-vulkan-cuda.patch`) | **on** | LINEAR one-plane **BGRx/BGRA** (SDR) and **xBGR_210LE / XB30** (HDR) DmaBuf → **Vulkan buffer copy** → CUDA/NVENC (`vulkan_cuda`); HDR → P010, SDR → NV12; failure sticks to loud `mmap_cuda` |

HDR encode uses hwframe **`sw_format`** (`AV_PIX_FMT_P010` vs `NV12`). Do not gate convert on `frame->format` — CUDA frames are `AV_PIX_FMT_CUDA` and a wrong check writes NV12 into P010 (green/pink chroma).

CUDA `sws_t::convert` clears the full destination Y/UV to true black (Y=0, UV mid) before writing the letterboxed content viewport. Without that, aspect-ratio padding stayed uninitialized and showed as green bars on all clients.

P010 (`bit_depth >= 10`) uses `new_color_vectors_from_colorspace` (H.273 code values) and packs `code << 6`. NV12 keeps legacy UNORM vectors + `*245`/`*256`. Portal HDR metadata (`02`) stubs exact Rec.2020 primaries + D65 (not approximate).

`06` prevents hybrid **PQ capture + SDR encode**: force file follows session HDR and stream `dynamicRange`. SDR clients should show `display_hdr=false` and gamescope without `--hdr-enabled`.

## Convert paths

| convert_path | Meaning |
|--------------|---------|
| `vulkan_cuda` | cached Vulkan DMA-BUF source → persistent OPAQUE_FD destination/CUDA mapping → CUDA conversion |
| `mmap_cuda` | DmaBuf mmap → CUDA upload (sticky fallback; not gpu_native) |
| (01 SHM) | cuda_ram host path when 05 off / no DmaBuf |

The Vulkan bridge is portal-only. Existing GL→CUDA support remains unchanged for KMS, Wayland, and other tiled DMA-BUF capture.
