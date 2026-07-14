# Polaris patches (topic series)

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal base, HDR, web, force-8bit |
| `05` | **on** | LINEAR DmaBuf + **CUDA import only** (`cuImportExternalMemory`). **No GL convert. No mmap fallback.** |

## Status (lea)

- `cuImportExternalMemory` currently fails (`CUDA_ERROR_UNKNOWN`) on gamescope LINEAR DmaBuf.
- Without fallback → no video until import is fixed (CUDA-EGL image register without GL shaders, or extmem flags).
- Do **not** reintroduce EGL→GL→CUDA as the goal path; goal is get rid of GL.
