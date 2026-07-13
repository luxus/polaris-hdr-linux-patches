# Test: polaris#152 SDR-first PipeWire capture (4090 / gamescope)

**Maintainer ask** ([#152](https://github.com/papi-ux/polaris/issues/152)):  
Keep **gamescope** `pipewire-prefer-dmabuf`. **Remove** experimental Polaris patches. Run #152 capture work. Focus window required. Report `render_node`, format/modifier, `capture_transport`, `frame_residency`.

## Build matrix

| Component | Config |
|-----------|--------|
| Polaris | **master** `2008458` + `polaris/upstream/issue-152-pipewire-capture/combined.patch` |
| Polaris experimental | **off** |
| gamescope | at least `pipewire-prefer-dmabuf` (other HDR metadata patches optional for SDR-first) |
| Portal | xdg-desktop-portal-gamescope + `fix-stream-size` + portals.conf when capturing gamescope |
| GPU | hybrid: pin NVIDIA render node for gamescope + polaris |

Why not branch tip alone: `perf/issue-152-pipewire-capture` is 5 commits behind master (v1.3.1 etc.). Content is rebased onto master with only a changelog conflict.

## Runtime steps

1. gamescope session with a **focus client** (Steam gamepadui / game). Bare idle → zero frames.
2. polaris portal capture against gamescope.
3. Stream once (SDR first is fine).
4. Host logs: `render_node`, fourcc/modifier, `capture_transport`, `frame_residency`.
5. Optional reconnect; note SHM fallback reason if any.

## What not to do

- Do not apply `polaris/experimental/*` for this run.
- Do not treat washed HDR color as a failure of this branch (SDR-first).
