# Experimental Polaris patches (ON HOLD)

From the RTX 4090 + gamescope HDR spike (gist + early luxusAi work).

| Patch | Role |
|-------|------|
| `portal-dmabuf-capture.patch` | Prefer DmaBuf / 10-bit, first-frame diag |
| `egl-dmabuf-import.patch` | bare-tex + TexStorageEXT (NVIDIA + gamescope) |
| `cuda-gl-dmabuf.patch` | prefer `renderD*`, EGL import + mmap fallback |

**Do not apply these** when validating maintainer `perf/issue-152-pipewire-capture` ([#152](https://github.com/papi-ux/polaris/issues/152)). That branch is the cleaner SDR-first foundation; stack only gamescope `pipewire-prefer-dmabuf`.

Keep as reference for ideas the maintainer already reviewed (render-node pin, linear modifier, GPU-only-if-DmaBuf).
