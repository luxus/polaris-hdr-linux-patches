# Status

| Date | State |
|------|--------|
| 2026-07-13 | **ACTIVE for #152 test** — archived maintainer branch `perf/issue-152-pipewire-capture` @ `c2bb9cb` as patches; experimental polaris moved under `polaris/experimental/` |
| 2026-07-12 | ON HOLD research archive; daily host stream stock Polaris labwc SDR |
| 2026-07-11 | Gamescope path green on lea (experimental): DmaBuf XB30, NVENC HDR P010 |

## #152 validation (now)

- **Polaris:** tip `c2bb9cb…` **or** base `38159f3` + `upstream/issue-152-pipewire-capture/combined.patch`
- **Polaris experimental:** off
- **gamescope:** keep `pipewire-prefer-dmabuf` (producer)
- **Report:** render_node, format/modifier, capture_transport, frame_residency

## Gamescope path — learnings (short)

1. **Producer first.** Unpatched gamescope only offers `SPA_DATA_DmaBuf` when modifier fixation succeeds → clients stick on MemFd. Fix: `pipewire-prefer-dmabuf.patch`.
2. **Idle has no frames.** Need a focus window (Steam/gamepadui/game).
3. **Private portal.** KDE steals ScreenCast without gamescope portal + portals.conf + unit env.
4. **Same GPU.** Hybrid: pin NVIDIA for gamescope and polaris/NVENC.
5. **EGL import, not CUDA extmem** (experimental path).
6. **Convert cheap; encode not.** ~1 ms convert / ~8–9 ms NVENC @ 4K HDR.
7. **Color ≠ zero-copy.** Washed HDR is separate (see `docs/polaris-hdr-color.md`).
8. **MemPtr escape.** Force CPU path when GPU descriptors + MemPtr would black-screen.

See `docs/polaris-hdr-dmabuf-plan.md` for G0–G6.
