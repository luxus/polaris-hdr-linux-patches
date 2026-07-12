# Status

| Date | State |
|------|--------|
| 2026-07-12 | **ON HOLD** — research archive; daily host stream is stock Polaris **labwc** SDR |
| 2026-07-11 | Gamescope path green on lea: DmaBuf `XB30`, NVENC HDR P010, convert ~1 ms / encode ~8–9 ms |
| Upstream | [polaris#152](https://github.com/papi-ux/polaris/issues/152); maintainer branch `perf/issue-152-pipewire-capture` (SDR-first) |

Do not treat this tree as production. Rebase before reuse.

## Gamescope path — what we learned (short)

1. **Producer first.** Unpatched gamescope only offers `SPA_DATA_DmaBuf` when modifier fixation succeeds → clients often stick on MemFd forever. Fix is gamescope-side (`pipewire-prefer-dmabuf.patch`), not more polaris thrash.
2. **Idle has no frames.** `paint_pipewire()` only pushes when a focus window commits. Bare `sleep infinity` idle → zero frames (not a probe bug). Need Steam/gamepadui or a focus client.
3. **Private portal.** Session `XDG_CURRENT_DESKTOP=KDE` steals ScreenCast unless gamescope portal + portals.conf + unit env are forced.
4. **Same GPU.** Hybrid 4090+AMD: pin NVIDIA render node for gamescope *and* polaris/NVENC or import fails / falls back to SHM.
5. **EGL import, not CUDA extmem.** CUDA external memory failed on gamescope dmabufs; `TexStorageEXT` + GL→CUDA worked. Default `DRM_FORMAT_MOD_LINEAR` when producer omits modifier (else GL 0x502).
6. **Convert is cheap; encode is not.** RGB10→P010 ≈ 0.7–1.0 ms; NVENC at 4K HDR ≈ 8.2–8.8 ms (UI encode ms ≈ NVENC only). 120 Hz budget is encode-bound.
7. **Color ≠ zero-copy.** Washed HDR vs HDMI is metadata/transfer/matrix (see `docs/polaris-hdr-color.md`), present even with good DmaBuf.
8. **MemPtr escape hatch.** `POLARIS_PORTAL_DMABUF=0` forces CPU path when GPU descriptors + MemPtr would black-screen.

See `docs/polaris-hdr-dmabuf-plan.md` for gated checklist (G0–G6).
