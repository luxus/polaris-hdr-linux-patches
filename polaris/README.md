# Polaris patches (topic series)

Applied by `pkgs/polaris-stream` onto **papi-ux/polaris** master
`2008458634c0d3f04f8abc39fab862bc69a47af8`.

## Apply order

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal SHM CUDA, HDR, web sessions, force-8bit |
| `05-portal-dmabuf-linear-mmap.patch` | **on** (`enablePortalDmabufLinear`) | LINEAR DmaBuf negotiate + `cuImportExternalMemory` encode. **No mmap fallback.** No mmap fallback. If `cuImportExternalMemory` fails → no video (not silent mmap). |

## Lea notes

- SHM (05 off): video OK, encode low.
- 05 on + import fail: no video (by design — no mmap fallback).
- Next experiment: CUDA-EGL (`cudaGraphicsEGLRegisterImage`), not mmap.
