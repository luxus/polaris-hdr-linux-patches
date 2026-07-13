# gamescope-hdr patches

Applied by `pkgs/gamescope-hdr` (nixpkgs gamescope + `enableWsi = true`).

| Patch | Topic |
|-------|--------|
| `01-pipewire-hdr-metadata.patch` | Expose HDR metadata on PipeWire stream (IceDOS / polaris#152) |
| `02-headless-hdr-colorimetry.patch` | Headless backend HDR colorimetry / force-HDR support flags |
| `03-pipewire-prefer-dmabuf.patch` | Prefer `SPA_DATA_DmaBuf` when consumer allows |

## Not applied

| Path | Why |
|------|-----|
| `archived/gamescope/pipewire-color-mgmt.patch` | Forced PQ paint / ColorMgmt LUTs on PW path — **worsened** wash vs stock `paint_pipewire` (Gamma22). Do not re-enable without a measured color plan ([#1](https://github.com/luxus/polaris-hdr-linux-patches/issues/1)). |

## Runtime (host)

- WSI layer is **built** (`enableWsi`); host must **not** set `ENABLE_GAMESCOPE_WSI` / `ENABLE_HDR_WSI` for Proton (CreateSwapchain / wash).
- Force-HDR flags come from `polaris-hdr-force` via idle unit, not from these patches alone.
