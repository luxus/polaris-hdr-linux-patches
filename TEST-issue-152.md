# Test: polaris#152 SDR-first PipeWire capture (4090 / gamescope)

**Maintainer ask** ([#152](https://github.com/papi-ux/polaris/issues/152)):  
Keep **gamescope** `pipewire-prefer-dmabuf`. **Remove** our experimental Polaris patches. Run branch tip `perf/issue-152-pipewire-capture` (`c2bb9cb…`). Focus window required. Report `render_node`, format/modifier, `capture_transport`, `frame_residency`.

## Build matrix

| Component | Config for this test |
|-----------|----------------------|
| Polaris | tip `c2bb9cb475bb5aec3b8c12d1b5fb2d85baa565c3` **or** base `38159f3` + `polaris/upstream/issue-152-pipewire-capture/combined.patch` |
| Polaris experimental | **off** (`polaris/experimental/*` not applied) |
| gamescope | at least `gamescope/pipewire-prefer-dmabuf.patch` (other HDR metadata patches optional for SDR-first) |
| Portal | xdg-desktop-portal-gamescope + portals.conf ScreenCast=gamescope when capturing gamescope |
| GPU | hybrid hosts: pin NVIDIA render node for gamescope + polaris |

Prefer **pinning the tip rev** over the patch when packaging (fewer moving parts).

## Runtime steps

1. Start gamescope HDR/idle session with a **focus client** (Steam gamepadui / glxgears / game). Bare idle → zero frames.
2. Switch polaris to portal capture against gamescope (not labwc).
3. Stream once (Moonlight SDR first is fine; branch is SDR-first foundation).
4. Collect host logs for:

```text
render_node
# format / fourcc / modifier
capture_transport
frame_residency
# first-frame SPA_DATA_* if present
```

5. Optional: end stream and reconnect; note fallback-to-SHM reason if any.

## What not to do

- Do not re-apply gist / `experimental/` Polaris patches for this run.
- Do not treat washed HDR color as a failure of this branch (out of scope; SDR-first).
- Do not compare encode-ms to labwc HDR path as the primary gate.

## After the run

Post log excerpts on #152. If GPU path fails, include the fallback reason string from polaris. Rebase this archive’s tip SHA if the branch moves.
