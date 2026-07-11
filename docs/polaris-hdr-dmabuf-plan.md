# Polaris HDR DMA-BUF path — gated plan (self-check)

Goal: GameStream of gamescope HDR **without CPU copy** when the producer can
export `SPA_DATA_DmaBuf`. Keep labwc SDR default. No thrash deploys; each gate
must pass before the next.

## Proven facts (do not re-litigate)

1. **G0 MemPtr works**: portal single EnumFormat + MemFd/SHM → video + audio + HDR toggle.
2. **G1 formats**: gamescope Video/Source advertises BGRx±modifier, NV12±modifier, xBGR_210LE (HDR).
3. **G2 baseline (unpatched)**: probe → `FIRST_FRAME type=MemFd` (shm), `has_modifier=0`.
4. **Root cause (fixed)**: gamescope only offered `ParamBuffers dataType=DmaBuf` when a
   modifier was fixated. Clients land on plain EnumFormat → MemFd forever.
5. **G2 green (patched gamescope-hdr `pipewire-prefer-dmabuf`)**: with a focus window
   (e.g. glxgears), probe gets `FIRST_FRAME type=DmaBuf`, `DMA_BUF_IOCTL_SYNC` ok,
   `fd_link=/dmabuf:`. Consumer `dataType=MemFd` only still gets MemFd (fallback).
   **Note:** `paint_pipewire()` only pushes when a focus window has new commits —
   bare `sleep infinity` idle produces **zero** frames (not a probe bug).

## Gates

| Gate | Work | Pass criteria | Fail → |
|------|------|---------------|--------|
| **G0** | MemPtr baseline stable | polaris + gamescope Video/Source; video known-good when using MemPtr portal | restore portal MemPtr; do not touch dual EnumFormat |
| **G1** | Offline EnumFormat dump | `pw-cli e <node> EnumFormat` shows modifier + plain BGRx | fix gamescope idle / node id |
| **G2** | **Producer** export DmaBuf | probe: `FIRST_FRAME type=DmaBuf` (≥1 mode) | fix gamescope-hdr patch only; no portal thrash |
| **G3** | Portal accept DmaBuf + MemPtr fallback | connect works; logs type; MemPtr still works if DmaBuf absent | revert portal EnumFormat; keep MemPtr |
| **G4** | Auto GPU encode on real DmaBuf only | no blank frames on MemPtr; GPU path only if `SPA_DATA_DmaBuf` | force CPU path |
| **G5** | Moonlight A/B 60s | dashboard honest GPU-native or CPU; video visible | rollback to G0 binary |
| **G6** | Upstream-ready patches | small patches + design notes; no dead dual-path mess | split commits |

## Implementation order (this session)

1. **Producer patch** (`gamescope-hdr`): advertise `DmaBuf|MemFd|MemPtr` in
   `ParamBuffers`; `add_buffer` prefers DmaBuf when the type *mask* allows it;
   MemFd/MemPtr fallback unchanged. (Does not depend on flaky modifier fixation.)
2. Rebuild `gamescope-hdr` → restart **only** `polaris-hdr-idle` → re-probe (G2).
3. Only if G2 green: portal consumer dual-safe path (G3–G4).
4. Live Moonlight check (G5) after G4.
5. Clean up patches / docs (G6).

## Dual-GPU (built-in)

Hybrid dGPU+iGPU is normal. Strategy is **same device**, not cross-import:

- `lib/polaris-nvidia-pin.sh` discovers NVIDIA DRM + `10de:xxxx` at runtime.
- **labwc/polaris**: exports `WLR_RENDER_DRM_DEVICE` / Vulkan+EGL ICD pin.
- **gamescope HDR idle**: `--prefer-vk-device` + same pin so PipeWire DmaBuf is NVIDIA.
- Portal GPU path (DmaBuf→NVENC) only works when capture and encode share NVIDIA.
- Escape: `POLARIS_PORTAL_DMABUF=0` → MemFd CPU path (portal_grab).

Do **not** blacklist `amdgpu` for this — pin instead so the iGPU can stay enabled.

### GL 0x502 (DmaBuf → CUDA/GL)

Even with NVIDIA-only capture, `egl::import_source` failed at
`EGLImageTargetTexture2DOES` with **GL 0x502**. Likely cause: portal set
`modifier=DRM_FORMAT_MOD_INVALID` when the format had no modifier prop, so EGL
got **no** modifier attrs; gamescope exports **linear** DmaBuf and NVIDIA wants
`DRM_FORMAT_MOD_LINEAR` (0).

Fix in portal patch: default `sd.modifier = DRM_FORMAT_MOD_LINEAR`. Diagnostics in
`egl-dmabuf-import.patch`. Stable play remains `POLARIS_PORTAL_DMABUF=0`
until a stream with `=1` shows no GL 0x502.

## Hard rules

- Proof before fix: no “maybe GPU” without probe line `type=DmaBuf`.
- Never break G0 video for a speculative portal change.
- User is not playing until done — restarts of hdr-idle/portal OK; avoid full OS thrash.
- Stage (`git add`) before any `nh os switch` / `clan machines update`.

## Commands (agent runs these)

```bash
# G1/G2 probe (node from pw-dump Video/Source gamescope)

# After gamescope-hdr rebuild + idle restart
systemctl --user restart polaris-hdr-idle.service
```

## Follow-up (not this plan)

**HDR looks washed / colorless vs HDMI** (menus hard to read): capture 10-bit DmaBuf is fine;
suspect metadata + Linux matrix-only convert vs PQ-aware path. See
[`docs/agents/polaris-hdr-color.md`](./polaris-hdr-color.md). Do not thrash DmaBuf for color.
