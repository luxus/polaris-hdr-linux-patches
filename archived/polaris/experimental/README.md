# Archived: experimental gist DmaBuf patches

Early RTX 4090 + gamescope spike. **Not applied.**

Superseded by `polaris/01-portal-pipewire-dmabuf.patch` (LINEAR/mmap + EGL path on same-GPU portal).

| Patch | Historical role |
|-------|-----------------|
| `portal-dmabuf-capture.patch` | Prefer DmaBuf / 10-bit, first-frame diag |
| `egl-dmabuf-import.patch` | bare-tex + TexStorageEXT |
| `cuda-gl-dmabuf.patch` | prefer renderD*, EGL + mmap |

Keep as idea archive only.
