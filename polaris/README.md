# Polaris patches (upstream-aligned phases)

Wired by `pkgs/polaris-stream/default.nix`. Pin: papi-ux/polaris **master** (see package `rev`).

Goal: land upstream in phases; **turn off a local phase when that code is on main**, rebase remaining patches, keep the same host behavior until everything is upstream.

**Maintainer handoff (English, non-NixOS):** [docs/upstream-handoff-papi-ux.md](../docs/upstream-handoff-papi-ux.md) — what to expect, what to do, session architecture, SHM/portal/HDR/private bus.

## Phases

| Phase | Package flag | Patch file(s) | What to verify |
|-------|----------------|---------------|----------------|
| **1** Portal/PipeWire foundation + **SHM fallback** | `enablePhase1Portal` (default on) | `phase1-portal-pipewire-shm.patch` | Stream works; log `capture_transport=shm` or `dmabuf`; no crash when DMA-BUF refused |
| **2** NVIDIA LINEAR DmaBuf → Vulkan → CUDA | `enablePhase2VulkanCuda` (default on; alias `enablePortalDmabufLinear`) | `phase2-portal-vulkan-cuda.patch` | `convert_path=vulkan_cuda`; sticky `mmap_cuda` on fail; never lie `gpu_native` |
| **3** Gamescope Stream ownership | *(not a Polaris patch)* | host `polaris-hdr-session` / idle unit | Start/wait/stop owns gamescope + cleanup |
| **4** HDR when request + format + encode agree | `enablePhase4Hdr` (default on) | `phase4-*.patch` (4 files) | No hybrid PQ+SDR; force-file from `enable_hdr`; device_db ≠ force HDR |
| Optional | `enablePortalPrivateBus` (default on) | `optional-portal-private-bus.patch` | `POLARIS_PORTAL_DBUS_ADDRESS` ScreenCast only; session bus for Avahi |

**Apply order** (fixed): phase1 → phase4 → optional bus → phase2.

Phase2 and optional bus **require** phase1.

## Step packages (flake)

| Package | Flags | Use |
|---------|--------|-----|
| `polaris-stream-phase1` | phase1 only | SHM/portal foundation A/B |
| `polaris-stream-phase1-2` | phase1+2 | GPU fast path without HDR extras |
| `polaris-stream-phase1-2-4` | phase1+2+4, no private bus | full capture/HDR, session bus portal |
| `polaris-stream` | all on | production stack (private bus + full) |

```bash
nix build .#polaris-stream-phase1
nix build .#polaris-stream-phase1-2
nix build .#polaris-stream
```

When upstream lands phase N: set that flag false (or drop package variant), rebase remaining patches onto new main, rebuild.

## Phase 1: SHM fallback (reliable?)

**Yes — SHM/MemFd is a first-class path in phase1**, not a broken leftover:

- PipeWire offers `MemFd`/`MemPtr` when DMA-BUF is not eligible (or `POLARIS_PORTAL_DMABUF=0`).
- Log: `portal: capture_transport=shm frame_residency=cpu` (warning is intentional honesty).
- CUDA still encodes via host upload (NV12); stream continues.
- DMA-BUF offer is gated on same-GPU + modifiers; fail-closed → SHM, not abort.

**Not** the phase2 `mmap_cuda` sticky path (that is DmaBuf mmap after Vulkan bridge fail).

## Phase 4 files

| File | Role |
|------|------|
| `phase4-portal-hdr-metadata.patch` | Portal HDR metadata + force-file gate |
| `phase4-sdr-force-8bit-encode.patch` | Non-HDR → 8-bit NV12 |
| `phase4-hdr-force-file-sync.patch` | Write `polaris-hdr-force` from `enable_hdr` only |
| `phase4-device-db-hdr-not-request.patch` | `hdr_capable` ≠ force `enable_hdr` |

## Invariants

- HDR encode: gate on hwframe **`sw_format`** (`P010` vs `NV12`), not `frame->format`.
- Letterbox: fill only when letterboxed; CUDA sync after convert.
- Convert honesty: `mmap_cuda` ≠ `vulkan_cuda` ≠ SHM host path.
- Hybrid PQ capture + SDR encode is forbidden.

| convert_path / transport | Phase | Meaning |
|--------------------------|-------|---------|
| `capture_transport=shm` | 1 | MemFd/MemPtr CPU path |
| `capture_transport=dmabuf` | 1+ | PipeWire DMA-BUF |
| `vulkan_cuda` | 2 | portal fast path |
| `mmap_cuda` | 2 | sticky DmaBuf mmap fallback |

Portal-only Vulkan bridge. KMS/Wayland GL→CUDA untouched.
