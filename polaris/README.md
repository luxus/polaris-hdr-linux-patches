# Polaris patches (topic series)

Applied by `pkgs/polaris-stream` onto **papi-ux/polaris** master
`2008458634c0d3f04f8abc39fab862bc69a47af8`.

Historical numbered series (`0001`…`0015`, `combined.patch`) lives under
[`archived/polaris/issue-152-series/`](../archived/polaris/issue-152-series/).
Failed experiments: [`archived/polaris/experimental/`](../archived/polaris/experimental/).

## Apply order

| Patch | Topic | What it does |
|-------|--------|----------------|
| `01-portal-pipewire-dmabuf.patch` | Capture / encode | Upstream #152 PipeWire portal capture + same-GPU DmaBuf eligibility (`adapter_name` assume), SHM→CUDA NV12 fallback, negotiate diag, LINEAR mmap/EGL DmaBuf path, prefer gamescope **xBGR_210LE** over BGRx |
| `02-portal-hdr-metadata.patch` | HDR | Portal reports usable HDR10 mastering metadata; gate `is_hdr` on `$XDG_RUNTIME_DIR/polaris-hdr-force` (client HDR) |
| `03-web-ui-session-persist.patch` | Web UI | Persist auth sessions across polaris restart (cookie alone is not enough) |

```bash
# on clean master @ 2008458
git apply polaris/01-portal-pipewire-dmabuf.patch
git apply polaris/02-portal-hdr-metadata.patch
git apply polaris/03-web-ui-session-persist.patch
```

## Not applied (archived)

| Path | Why |
|------|-----|
| `archived/.../0009-portal-dmabuf-gl-import.patch` | NVIDIA black video; superseded by 01’s LINEAR/mmap + EGL path |
| `archived/polaris/experimental/*` | Early gist DmaBuf attempts; do not stack with 01 |

## Host notes (not in these patches)

- `adapter_name = /dev/dri/renderD128` (or your NVIDIA render node) for same-GPU DmaBuf
- Gamescope idle + `xdg-desktop-portal-gamescope` + `capture = portal` (luxusAi `polaris-hdr-session`)
- Do **not** set `ENABLE_GAMESCOPE_WSI` / `ENABLE_HDR_WSI` under Proton (washes present path)
