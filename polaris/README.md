# Polaris patches

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal base, HDR, web, force-8bit |
| `05` (`05-portal-dmabuf-vulkan-cuda.patch`) | **on** | LINEAR one-plane **BGRx/BGRA** (SDR) and **xBGR_210LE / XB30** (HDR) DmaBuf → **Vulkan buffer copy** → CUDA/NVENC (`vulkan_cuda`); HDR → P010, SDR → NV12; failure sticks to loud `mmap_cuda` |

## Convert paths

| convert_path | Meaning |
|--------------|---------|
| `vulkan_cuda` | cached Vulkan DMA-BUF source → persistent OPAQUE_FD destination/CUDA mapping → CUDA conversion |
| `mmap_cuda` | DmaBuf mmap → CUDA upload (sticky fallback; not gpu_native) |
| (01 SHM) | cuda_ram host path when 05 off / no DmaBuf |

The Vulkan bridge is portal-only. Existing GL→CUDA support remains unchanged for KMS, Wayland, and other tiled DMA-BUF capture.
