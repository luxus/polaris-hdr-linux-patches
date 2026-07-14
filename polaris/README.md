# Polaris patches (topic series)

Applied by `pkgs/polaris-stream` onto **papi-ux/polaris** master
`2008458634c0d3f04f8abc39fab862bc69a47af8`.

## Apply order

| Patch | Topic | What it does |
|-------|--------|----------------|
| `01-portal-pipewire-dmabuf.patch` | Capture | #152 portal + SHM CUDA + diag + xBGR_210LE (no forced LINEAR DmaBuf) |
| `02-portal-hdr-metadata.patch` | HDR | HDR10 metadata + polaris-hdr-force gate |
| `03-web-ui-session-persist.patch` | Web UI | Persist auth sessions |
| `04-sdr-force-8bit-encode.patch` | Encode | Non-HDR streams force 8-bit NV12 |
| `05-portal-dmabuf-linear-mmap.patch` | DmaBuf CUDA | Negotiate LINEAR DmaBuf without SPA modifiers; **CUDA** `cuImportExternalMemory` + pitch2D + `RGBA_to_NV12` (not GL). Toggle: `enablePortalDmabufLinear` |

```bash
git apply polaris/01-portal-pipewire-dmabuf.patch
git apply polaris/02-portal-hdr-metadata.patch
git apply polaris/03-web-ui-session-persist.patch
git apply polaris/04-sdr-force-8bit-encode.patch
git apply polaris/05-portal-dmabuf-linear-mmap.patch   # optional / default on in flake
```

## Notes

- Without 05: SHM `cuda_ram_t` ~4.8ms encode on lea 4K.
- Old 05 (GL EGL + mmap): ~8.8ms.
- Current 05: CUDA import path — measure encode on lea.
