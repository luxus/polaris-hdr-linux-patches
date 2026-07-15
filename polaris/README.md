# Polaris patches

Wired by `pkgs/polaris-stream/default.nix`.

| Patch | Default | What |
|-------|---------|------|
| `01`–`04` | always | portal PipeWire/DmaBuf, HDR metadata+force gate, web sessions, SDR force 8-bit |
| `06` | always | write `polaris-hdr-force` from final `enable_hdr` only (no gamescope restart, no encode-probe rewrite) |
| `07` | always | `device_db`/`ai` `hdr_capable` ≠ session HDR request; only `client_profile` locks `enable_hdr` |
| `05` | **on** (`enablePortalDmabufLinear`) | LINEAR one-plane BGRx/BGRA or xBGR_210LE → Vulkan copy → CUDA (`vulkan_cuda`); HDR→P010, SDR→NV12; sticky loud `mmap_cuda` fallback |

## Invariants

- HDR encode: gate on hwframe **`sw_format`** (`P010` vs `NV12`), not `frame->format` (`CUDA` frames are always `AV_PIX_FMT_CUDA`).
- Letterbox: clear Y/UV padding **only when letterboxed**; full-frame clear every frame races NVENC (black flash). Sync CUDA stream after convert.
- Convert honesty: never report `gpu_native` for CPU/mmap paths; keep `mmap_cuda` ≠ `vulkan_cuda`.
- Hybrid tablets: capability-forced HDR + SDR encode = wild colors — fixed by `07` + honest client profiles.

| convert_path | Meaning |
|--------------|---------|
| `vulkan_cuda` | portal fast path |
| `mmap_cuda` | sticky DmaBuf mmap fallback |
| (01 SHM) | host path when no DmaBuf / 05 off |

Portal-only Vulkan bridge. KMS/Wayland GL→CUDA paths stay untouched.
