# Polaris patches

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal base, HDR, web, force-8bit |
| `05` | **on** | LINEAR DmaBuf + **CUDA-EGL** (no GL convert); if that fails → **ERROR** `convert_path=mmap_cuda` + stats `encode_target_residency=cpu` (WebUI not gpu_native) |

## Convert paths

| convert_path | Meaning |
|--------------|---------|
| `cuda_egl` | `eglCreateImage` + `cuGraphicsEGLRegisterImage` + CUDA `RGBA_to_NV12` (goal; no GL shaders) |
| `cuda_mmap` | DmaBuf mmap → CUDA upload (fallback; loud) |
| (01 SHM) | cuda_ram host path when 05 off / no DmaBuf |

**Removed:** `cuImportExternalMemory` / `cuda_import` — always fails on gamescope portal FDs (see issue #5).

No GL BGRA→NV12 convert in 05.
