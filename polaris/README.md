# Polaris patches

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal base, HDR, web, force-8bit |
| `05` | **on** | LINEAR DmaBuf + CUDA import; if import fails → **ERROR** `convert_path=mmap_cuda` + stats `encode_target_residency=cpu` (WebUI not gpu_native) |

## Convert paths

| convert_path | Meaning |
|--------------|---------|
| `cuda_import` | cuImportExternalMemory + CUDA kernel (goal) |
| `cuda_mmap` | DmaBuf mmap → CUDA upload (fallback; loud) |
| (01 SHM) | cuda_ram host path when 05 off / no DmaBuf |

No GL convert in 05.
