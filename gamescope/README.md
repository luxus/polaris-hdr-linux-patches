# gamescope-hdr patches

Applied by `pkgs/gamescope-hdr` (nixpkgs gamescope + `enableWsi = true`).

| Patch | Topic |
|-------|--------|
| `01-pipewire-hdr-metadata.patch` | Expose HDR metadata on PipeWire stream (IceDOS / polaris#152) |
| `02-headless-hdr-colorimetry.patch` | Headless backend HDR colorimetry / force-HDR support flags |
| `03-pipewire-prefer-dmabuf.patch` | Prefer `SPA_DATA_DmaBuf` when consumer allows |
| `04-pipewire-color-mgmt.patch` | **A:** `paint_pipewire` uses `g_ColorMgmtLuts` (IceDOS) |
| postPatch in `pkgs/gamescope-hdr` | **B:** `outputEncodingEOTF = HDR ? PQ : Gamma22` + pin nits/gamut |

## Color experiment ladder

| Step | Change | Status |
|------|--------|--------|
| **A** | ColorMgmt LUTs on PW (`04`) | **active** (reds much better; slightly pale) |
| **B** | `outputEncodingEOTF = HDR ? PQ : Gamma22` + nits/gamut postPatch | **active** (A+B) — retest pale/wash |
| archive | older gated ColorMgmt variant | `archived/gamescope/pipewire-color-mgmt.patch` |

## Runtime (host)

- WSI layer is **built** (`enableWsi`); nested Polaris path sets `ENABLE_GAMESCOPE_WSI` for children.
- Session HDR flags: host-owned (`polaris-hdr-session`); prefer flake pin over path overrides.
