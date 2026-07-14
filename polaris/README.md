# Polaris patches

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal base, HDR, web, force-8bit |
| `05` (`05-portal-dmabuf-vulkan-cuda.patch`) | **on** | LINEAR one-plane BGRx/BGRA DmaBuf → **Vulkan buffer copy** → CUDA/NVENC; failure sticks to loud `mmap_cuda` with CPU-residency stats |

## Convert paths

| convert_path | Meaning |
|--------------|---------|
| `vulkan_cuda` | cached Vulkan DMA-BUF source → persistent OPAQUE_FD destination/CUDA mapping → CUDA conversion |
| `mmap_cuda` | DmaBuf mmap → CUDA upload (sticky fallback; not gpu_native) |
| (01 SHM) | cuda_ram host path when 05 off / no DmaBuf |

The Vulkan bridge is portal-only. Existing GL→CUDA support remains unchanged for KMS, Wayland, and other tiled DMA-BUF capture.
