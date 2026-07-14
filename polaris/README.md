# Polaris patches (topic series)

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal base, HDR, web, force-8bit |
| `05` | **on** | LINEAR DmaBuf negotiate + **EGL→GL→CUDA** encode (Sunshine-style). **No** `cuImportExternalMemory`, **no** mmap fallback. |

## Why not CUDA extmem?

gamescope LINEAR DmaBufs on NVIDIA fail `cuImportExternalMemory` (`CUDA_ERROR_UNKNOWN`).
Project archive note: *gamescope dmabufs reject CUDA extmem*. Sunshine uses EGL import + GL convert + CUDA map instead.

## Reporting

WebUI `gpu_native` = **capture** DmaBuf residency, not convert path.
Convert is EGL→GL→CUDA (GPU textures, not zero-copy into NVENC).
