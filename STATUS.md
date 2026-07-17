# Status

## Now (2026-07-15)

| Item | State |
|------|--------|
| **Polaris pin** | master `ba166ef` (2026-07-16); drop local `03` (upstream webui persist); active `01`–`02`,`04`–`08` |
| **Patch 08** | `POLARIS_PORTAL_DBUS_ADDRESS` → ScreenCast-only private bus; process session bus keeps Avahi/tray (KRDP coexistence path) |
| **Deploy lea** | `d4e5557` → luxusAi lock; `nh os switch` **gen 403**; polaris `/nix/store/3gj4z581…-polaris-stream-…`; units restarted (portal + nvenc OK) |
| Capture/encode | portal DmaBuf → `vulkan_cuda` (sticky `mmap_cuda` fallback); HDR = XB30/P010 + Rec.2020/PQ; SDR = 8-bit/NV12 |
| Gamescope color | **A+B** always: ColorMgmt LUTs (`04`) + `EOTF_PQ` when HDR (`postPatch`) |
| WSI | **`enableWsi = true` always** (layer built). Attach path has been flaky historically; nested WSI is the working presentation path when needed. Still never inject `ENABLE_*_WSI` into plain attach/Proton env “for capture” |
| HDR force file | `06` writes `polaris-hdr-force` from final `enable_hdr` only (no gamescope restart, no encoder-probe thrash) |
| device_db HDR | `07`: `hdr_capable` must **not** force `enable_hdr` (iPad fuzzy→Pro hybrid XB30+SDR). Only `client_profile` locks HDR |
| iPhone teal/magenta | client/hybrid issue — see [handoff](docs/handoff-iphone-color-2026-07-15.md). Host livingroom/Mac HDR OK |

## Active patches

| Package | Patches |
|---------|---------|
| polaris-stream | master `ba166ef` · `01` portal · `02` HDR meta/force · `04` force-8bit · `06` force-file · `07` device_db · `08` portal bus · `05` Vulkan→CUDA (default on); web persist upstream |
| gamescope-hdr | `01` PW HDR · `02` headless colorimetry · `03` prefer dmabuf · `04` ColorMgmt · postPatch EOTF_PQ · **WSI built** |
| xdg-desktop-portal-gamescope | `01` stream size |

Details: [polaris/README.md](polaris/README.md), [gamescope/README.md](gamescope/README.md).
Wiring: `pkgs/*/default.nix`. Research history: `docs/`, never-applied: `archived/`.

## Open issues

| # | Topic |
|---|--------|
| [#3](https://github.com/luxus/polaris-hdr-linux-patches/issues/3) | Web UI preview / path clarity |
| [#4](https://github.com/luxus/polaris-hdr-linux-patches/issues/4) | Gamescope Stream mode (UI) |
| [#6](https://github.com/luxus/polaris-hdr-linux-patches/issues/6) | Nested WSI polish / packaging — evidence in [docs/polaris-wsi-plan.md](docs/polaris-wsi-plan.md) |

**Closed:** [#1](https://github.com/luxus/polaris-hdr-linux-patches/issues/1) HDR color · [#2](https://github.com/luxus/polaris-hdr-linux-patches/issues/2) DMA-BUF · [#5](https://github.com/luxus/polaris-hdr-linux-patches/issues/5) Vulkan→CUDA

## Verified on lea (summary)

| Path | Result |
|------|--------|
| portal + `vulkan_cuda` 4K60 HDR livingroom | `spa_format=81` XB30 → P010, Rec.2020+PQ, stable (not `mmap_cuda`) |
| nested WSI desktop (KWin→gamescope→AC6) | full FROG hook + HDR10 swapchain; user color OK |
| Polaris nested WSI BP→BG3 | same capture/encode green after `sw_format` P010 fix |
| SDR clients / forced-SDR apps | 8-bit NV12 path independent of HDR |

Dead ends (do not reintroduce): desktop `cuImport(DMABUF_FD)`, `cuGraphicsEGLRegisterImage` (Tegra), archive ColorMgmt-only experiments without new A/B.

## Recent tip fixes (2026-07-15)

- `07` + profiles: stop device_db capability forcing HDR (tablet hybrid mess)
- `06`: force-file only; no idle `try-restart` / probe thrash (flicker)
- `05`: letterbox fill only when needed + CUDA sync after convert (black flash)
