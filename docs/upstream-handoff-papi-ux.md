# Upstream handoff: Gamescope / Portal / HDR (for non-NixOS)

**Audience:** Polaris maintainers (e.g. papi-ux) integrating this work upstream.  
**Distro:** Written so it works on any Linux host (systemd user session assumed; no NixOS required).  
**Repo:** [polaris-hdr-linux-patches](https://github.com/luxus/polaris-hdr-linux-patches) — packaging + patches on pinned Polaris master.  
**Not an issue comment** — technical reference only.

---

## 1. What you can expect

### 1.1 Working end state (measured on a hybrid NVIDIA desktop)

When the full stack is wired:

| Piece | Behavior |
|--------|----------|
| Capture | XDG Desktop Portal ScreenCast → PipeWire node from **headless Gamescope** (`WAYLAND_DISPLAY=gamescope-0`) |
| Transport | Prefer LINEAR DMA-BUF when same GPU as encoder; else **MemFd/MemPtr (SHM)** — supported, not a broken path |
| NVIDIA fast path | DMA-BUF → Vulkan buffer copy → exportable memory → CUDA map → NVENC (`convert_path=vulkan_cuda`) |
| Fallback | Sticky loud `mmap_cuda` if Vulkan bridge fails; SHM host upload if no DMA-BUF |
| HDR | Only when client/`enable_hdr`, gamescope HDR flags, 10-bit capture, and P010 encode **agree** |
| SDR | Independent 8-bit / NV12 path; no hybrid “PQ-shaped capture + SDR encode” |
| Desktop coexistence | Optional: ScreenCast on a **private D-Bus** so host KDE ScreenCast (e.g. KRDP) keeps working |

### 1.2 What is *not* claimed

- Private portal bus is **not** required for Phase 1 or for a pure Gamescope/Steam-Deck-like host.
- Nested Gamescope WSI is a **presentation** choice for Proton/Steam; it is not required for portal capture of idle gamescope.
- Building Gamescope with the FROG WSI layer ≠ enabling `ENABLE_GAMESCOPE_WSI` on every Proton process.
- Desktop `cuImport(DMABUF_FD)` / `cuGraphicsEGLRegisterImage` as a generic path — **dead ends** on desktop NVIDIA; do not reintroduce as the main story.

### 1.3 Suggested upstream phasing (matches this repo)

| Phase | Scope | Local patch(es) | Ship when green |
|-------|--------|-----------------|-----------------|
| **1** | Portal/PipeWire foundation + **reliable SHM/MemFd fallback** + honest diagnostics | `phase1-portal-pipewire-shm.patch` | Stream works; `capture_transport=shm\|dmabuf`; force SHM with env still works |
| **2** | NVIDIA LINEAR DMA-BUF → Vulkan → CUDA behind capability detection | `phase2-portal-vulkan-cuda.patch` | `convert_path=vulkan_cuda`; sticky `mmap_cuda` on fail |
| **3** | First-class **Gamescope Stream** mode (own gamescope lifecycle) | *mostly host scripts today* — product work inside Polaris | Start/wait/stop without external shell glue |
| **4** | HDR only when session request + format + encode + compositor flags agree | `phase4-*.patch` (four files) | No hybrid PQ+SDR; force-file / metadata consistent |
| Optional | Private ScreenCast bus for multi-desktop hosts | `optional-portal-private-bus.patch` | KDE KRDP + Polaris gamescope in parallel |

Phase 3 is the main gap for a polished product: today lifecycle is external (`polaris-hdr-session` + idle unit). Phases 1–2–4 are largely in the Polaris patches listed above.

---

## 2. What you need to do (maintainer checklist)

### 2.1 Phase 1 (Portal + SHM) — start here

1. Review / land **portal PipeWire capture** with:
   - Real ScreenCast CreateSession → SelectSources → Start → PipeWire remote FD + node.
   - Negotiation of packed 8-bit formats (and later 10-bit when HDR lands).
   - **Fail-closed DMA-BUF offer**: only if capture render node + encoder adapter are same-GPU and modifiers importable; otherwise **MemFd/MemPtr**.
   - Logs that never lie: `capture_transport=shm|dmabuf`, `frame_residency=cpu|gpu`.
2. Keep an escape hatch (this stack uses `POLARIS_PORTAL_DMABUF=0`) that forces non-DMA-BUF.
3. Encoder probes must **not** open a real picker (dummy/probe mode).
4. Restore tokens: optional persist for auto source selection; treat as private local state.

**Phase 1 success criteria**

```text
Portal: XDG Desktop Portal ScreenCast interface detected
portal: PipeWire format negotiated: WxH format=…
portal: capture_transport=shm frame_residency=cpu …   # with POLARIS_PORTAL_DMABUF=0 or no GPU path
# OR
portal: capture_transport=dmabuf frame_residency=gpu …
# Stream connects; no crash when DMA-BUF is refused
```

SHM path still encodes (e.g. CUDA upload to NV12). That is intentional.

### 2.2 Phase 2 (Vulkan → CUDA)

1. Only after Phase 1 is stable.
2. Fast path: LINEAR one-plane BGRx/BGRA (SDR) or xBGR_210LE / XB30 (HDR later) → Vulkan copy → CUDA/NVENC.
3. On failure: **sticky** fallback with explicit log (`mmap_cuda`), not silent CPU labeled as GPU-native.
4. Same GPU for capture + CUDA + NVENC (explicit `/dev/dri/renderD*` adapter).

### 2.3 Phase 3 (Gamescope Stream ownership)

Productize what external scripts do today (see §3):

- Own headless Gamescope process (or attach to an already-running one).
- Env contract: `gamescope-0`, DISPLAY for XWayland, HDR force file if used.
- Prep/cmd lifecycle: start → wait for compositor → launch app → wait for exit → cleanup.
- Do not require users to assemble systemd + shell by hand for the happy path.

### 2.4 Phase 4 (HDR)

1. Single source of truth for “HDR on this session” (client profile / `enable_hdr`, not fuzzy device_db “hdr_capable” alone).
2. Capture 10-bit + encode P010 + portal/compositor HDR flags must match.
3. Detect P010 via hwframe **`sw_format`**, not `frame->format` (CUDA frames are `AV_PIX_FMT_CUDA`).
4. Non-HDR stays 8-bit NV12; force 8-bit when HDR is off.

### 2.5 What not to take as “core Phase 1”

- Private D-Bus portal stack (optional coexistence).
- Nested WSI defaults / Steam Big Picture orchestration.
- Gamescope ColorMgmt / PQ paint patches (gamescope packaging, not Polaris).

---

## 3. How the session is built (distro-agnostic)

Topology:

```text
[Moonlight client]
       │
[Polaris process] ──session D-Bus──► Avahi, tray, host desktop services
       │
       └──ScreenCast (portal)──► PipeWire ──► encode (NVENC/…)
                    ▲
                    │ captures compositor output
                    │
         [headless Gamescope]  WAYLAND_DISPLAY=gamescope-0
                    │
         [Steam / game]  either:
            A) attach: X11 on gamescope XWayland (no ENABLE_GAMESCOPE_WSI)
            B) nested: Steam is gamescope primary child (WSI for presentation)
```

Polaris usually runs in the **user’s desktop session** (e.g. KDE). It does **not** have to run inside Gamescope. Capture targets Gamescope’s PipeWire stream via portal.

### 3.1 Components you need (any distro)

| Component | Role |
|-----------|------|
| Polaris build with Phase 1+ patches | Capture + encode |
| Gamescope (ideally with PipeWire HDR metadata + prefer DMA-BUF if available) | Headless compositor to capture |
| `xdg-desktop-portal` + a ScreenCast backend | Session bus default, **or** gamescope portal on a private bus |
| `xdg-desktop-portal-gamescope` | ScreenCast implementation that talks to gamescope |
| PipeWire | Video + audio transport |
| NVIDIA stack if using NVENC / Vulkan→CUDA | Same GPU as capture |
| Optional: user systemd units or equivalent process supervisor | Idle gamescope + polaris + portal helpers |

### 3.2 Idle Gamescope (always-on compositor for attach path)

Purpose: keep `gamescope-0` alive between streams so portal has something to capture.

**Command shape** (geometry from env or config):

```bash
# Optional hybrid GPU pin (see §3.5), then:
gamescope \
  --backend headless \
  --expose-wayland \
  --steam \
  --xwayland-count 2 \
  [--prefer-vk-device 10de:XXXX] \
  [--hdr-enabled --sdr-gamut-wideness 0 --hdr-sdr-content-nits 203] \
  -W WIDTH -H HEIGHT -r REFRESH \
  -w WIDTH -h HEIGHT \
  -- sleep infinity
```

**After start**, write a small env file (e.g. `$XDG_RUNTIME_DIR/polaris-hdr.env`):

```bash
DISPLAY=:1
WAYLAND_DISPLAY=gamescope-0
# optional: GAMESCOPE_WAYLAND_DISPLAY=gamescope-0
```

**HDR flags:** only if a force file says HDR is wanted (see §3.4). Default idle is often SDR-safe (no `--hdr-enabled`).

**Do not** set `ENABLE_GAMESCOPE_WSI` / `ENABLE_HDR_WSI` on the idle/attach path “to fix capture”. WSI is for nested presentation, not PipeWire capture.

### 3.3 Stream session script (start / wait / stop)

Conceptually three verbs (implemented today as `polaris-hdr-session`):

#### `start [steam_appid]`

1. Map client audio layout → Pulse/PipeWire sink if you use virtual sinks.
2. Decide HDR: e.g. `POLARIS_CLIENT_HDR` from Polaris prep-cmd / client profile → write force file.
3. Kill leftover Steam from previous session.
4. **Nested WSI path** (default for direct Steam titles that paint only as gamescope children):
   - Stop idle gamescope; free `gamescope-0`.
   - Pin GPU.
   - Launch Gamescope with Steam as primary child (no host `WAYLAND_DISPLAY` on children):

```bash
env -u WAYLAND_DISPLAY -u DISPLAY -u ENABLE_HDR_WSI \
  PULSE_SINK="$audio_sink" \
  STEAM_MULTIPLE_XWAYLANDS=1 \
  QT_QPA_PLATFORM=xcb \
  DISABLE_HDR_WSI=1 \
  [STEAM_GAMESCOPE_HDR_SUPPORTED=1 DXVK_HDR=1 if HDR] \
  gamescope \
    --backend headless \
    --steam \
    --xwayland-count 2 \
    [--prefer-vk-device …] \
    [--hdr-enabled …] \
    -W … -H … -r … -w … -h … \
    -- steam -gamepadui [-applaunch APPID]
```

   - Wait until `$XDG_RUNTIME_DIR/gamescope-0` exists.
   - Rewrite env file for portal/Polaris.
   - Mark nested mode (file flag) for cleanup.

5. **Attach path** (known-good for capture; no WSI):
   - Ensure idle gamescope is running; restart if HDR force file flipped.
   - Launch Steam **on gamescope X11 only**, stripping host Wayland so games do not paint on the host compositor while portal captures empty gamescope:

```bash
env -u WAYLAND_DISPLAY -u ENABLE_GAMESCOPE_WSI -u ENABLE_HDR_WSI \
  DISPLAY="${DISPLAY:-:1}" \
  GAMESCOPE_WAYLAND_DISPLAY=gamescope-0 \
  GDK_BACKEND=x11 SDL_VIDEODRIVER=x11 XDG_SESSION_TYPE=x11 \
  QT_QPA_PLATFORM=xcb \
  PULSE_SINK=… \
  [HDR steam env…] \
  steam -gamepadui [-applaunch APPID]
```

#### `wait`

- If appid set: poll until that game process exits (debounce short respawns), then shut down Steam → stream ends.
- If Big Picture only: wait until Steam exits.
- Optionally re-pin audio sink periodically (desktop audio routing fights).

#### `stop`

- Steam shutdown / kill.
- If nested: kill headless gamescope, clear nested flag + env file, restart idle if still in portal mode.
- Restore any helpers you stopped for the session (example: speech stack).

### 3.4 HDR force file lifecycle

Simple IPC between Polaris, session script, and Gamescope:

| Path | Example |
|------|---------|
| File | `$XDG_RUNTIME_DIR/polaris-hdr-force` |
| Contents | `1` / `true` = HDR wanted; `0` = SDR |

| Writer | When |
|--------|------|
| Session `start` | From client HDR intent (`POLARIS_CLIENT_HDR` / profile) |
| Polaris (local patch) | On session prep from final `enable_hdr` only — **do not** rewrite from encoder probes (they flip dynamicRange 0/1 and thrash) |

| Reader | When |
|--------|------|
| Idle / nested Gamescope launch | Whether to pass `--hdr-enabled` (+ nits/gamut defaults) |
| Portal HDR metadata path | Optional gate so metadata matches force |

**Hard rule:** Never leave Gamescope in HDR/PQ-shaped capture while the bitstream is SDR NV12 (hybrid). Clients (e.g. some mobile decoders) show wild chroma.

Also: device database “HDR capable” is **not** a session HDR request. Only an explicit client/profile lock should force `enable_hdr`.

### 3.5 GPU pinning (hybrid NVIDIA + iGPU)

Capture, Vulkan convert, CUDA, and NVENC must hit the **same** NVIDIA device. Do **not** fix this by blacklisting the AMD/Intel GPU.

Practical approach (shell, any distro):

1. Scan `/dev/dri/renderD*` → sysfs `vendor == 0x10de`.
2. Export:
   - `POLARIS_NVIDIA_RENDER_NODE=/dev/dri/renderD###`
   - `POLARIS_NVIDIA_VK_DEVICE=10de:XXXX` (for `gamescope --prefer-vk-device`)
   - `WLR_RENDER_DRM_DEVICE` / `WLR_DRM_DEVICES` if you also run wlroots compositors
   - Optional: `VK_ICD_FILENAMES` → nvidia ICD, `__GLX_VENDOR_LIBRARY_NAME=nvidia`
3. Point Polaris encoder adapter at that render node (`adapter_name = /dev/dri/renderD###`).

Reference script in this repo: `lib/polaris-nvidia-pin.sh` (sourceable bash).

### 3.6 Portal / D-Bus setups

#### A) Simple (recommended for Phase 1 demos)

- One session bus.
- `xdg-desktop-portal` + `xdg-desktop-portal-gamescope` (or only gamescope if that is the desktop).
- Polaris: `capture = portal`, normal `DBUS_SESSION_BUS_ADDRESS`.
- If the host desktop is KDE/GNOME, ScreenCast may go to **KWin/Mutter** unless the portal prefers gamescope — then you capture the wrong screen.

#### B) Coexistence with host desktop ScreenCast (optional)

Problem: host portal often ignores the app’s `XDG_CURRENT_DESKTOP=gamescope` and keeps KDE ScreenCast → Polaris captures the desktop ultrawide, not gamescope.

Worked approach:

1. Run a **private** `dbus-daemon`:  
   `unix:path=$XDG_RUNTIME_DIR/polaris-portal/bus`
2. On that bus only:
   - `xdg-desktop-portal` with `XDG_CURRENT_DESKTOP=gamescope` and gamescope-preferring portals config
   - `xdg-desktop-portal-gamescope` with `WAYLAND_DISPLAY=gamescope-0` and `GAMESCOPE_WAYLAND_DISPLAY=gamescope-0`
3. Polaris process stays on the **session** bus (Avahi discovery, tray, notifications).
4. Polaris ScreenCast only uses:  
   `POLARIS_PORTAL_DBUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/polaris-portal/bus`  
   (local patch `optional-portal-private-bus.patch` / upstream equivalent)

**Do not** put the whole Polaris process on the private bus: Avahi “host disappears”, and missing `org.freedesktop.Notifications` can stall ~60s per session.

**Do not** rely on a global `portals.conf` `ScreenCast=gamescope` if you need host KRDP/desktop capture at the same time.

### 3.7 Polaris config knobs (portal mode)

Minimal `polaris.conf` shape used here for gamescope capture:

```ini
headless_mode = disabled
linux_use_cage_compositor = disabled
capture = portal
encoder = nvenc
adapter_name = /dev/dri/renderD128   # pin to NVIDIA render node
stream_audio = enabled
enable_pairing = enabled
enable_discovery = enabled
```

Environment (systemd user unit, env file, or wrapper):

```bash
# Always useful
GAMESCOPE_WAYLAND_DISPLAY=gamescope-0
# Optional coexistence (Phase optional / patch 08)
POLARIS_PORTAL_DBUS_ADDRESS=unix:path=${XDG_RUNTIME_DIR}/polaris-portal/bus
# Force Phase-1 SHM path for testing
# POLARIS_PORTAL_DMABUF=0
```

Pass through from the user session (if Polaris is a user service):  
`WAYLAND_DISPLAY`, `DISPLAY`, `XDG_RUNTIME_DIR`, `DBUS_SESSION_BUS_ADDRESS`, `XAUTHORITY` as needed — but for ScreenCast of **gamescope**, the portal backend’s env must see `gamescope-0`, not only Polaris.

### 3.8 Log lines to trust

| Log | Meaning |
|-----|---------|
| `capture_transport=shm` | Phase 1 SHM path (CPU) |
| `capture_transport=dmabuf` | PipeWire DMA-BUF |
| `convert_path=vulkan_cuda` | Phase 2 fast path |
| `convert_path=mmap_cuda` | Phase 2 sticky fallback |
| `portal: using POLARIS_PORTAL_DBUS_ADDRESS` | ScreenCast on private bus |
| `spa_format=81` / `xBGR_210LE` / `src_xb30=true dst_p010=true` | HDR capture→P010 path |
| Hybrid symptoms | Gamescope HDR + NV12 SDR encode / wild tablet colors |

Gamescope only emits PipeWire frames when there are new commits (focused content). Idle black/static is not automatically a capture bug.

---

## 4. Mapping: local patches → upstream work

| Local file | Upstream phase | Notes |
|------------|----------------|--------|
| `polaris/phase1-portal-pipewire-shm.patch` | 1 | Foundation + SHM; includes same-GPU DMA-BUF **offer** logic |
| `polaris/phase2-portal-vulkan-cuda.patch` | 2 | Vulkan→CUDA bridge |
| *(session scripts, not in this package)* | 3 | Gamescope Stream ownership |
| `polaris/phase4-portal-hdr-metadata.patch` | 4 | Metadata + force gate |
| `polaris/phase4-sdr-force-8bit-encode.patch` | 4 | SDR encode path |
| `polaris/phase4-hdr-force-file-sync.patch` | 4 | force-file from `enable_hdr` only |
| `polaris/phase4-device-db-hdr-not-request.patch` | 4 | device_db ≠ force HDR |
| `polaris/optional-portal-private-bus.patch` | optional | `POLARIS_PORTAL_DBUS_ADDRESS` |

Pinned Polaris revision is in `pkgs/polaris-stream/default.nix` (`rev` / `COMMIT`). Apply order: phase1 → phase4 → optional bus → phase2.

This packaging repo uses Nix for builds; **you can apply the same `.patch` files with `git am` / `patch -p1` on a normal git checkout** and run your usual CMake/npm flow.

---

## 5. Minimal non-NixOS bring-up (Phase 1 only)

1. Build Polaris with phase1 patch only.
2. Install gamescope + xdg-desktop-portal + gamescope portal backend + PipeWire.
3. Start headless gamescope (§3.2), confirm `gamescope-0` socket under `$XDG_RUNTIME_DIR`.
4. Start portal stack so ScreenCast resolves to gamescope (simple single-desktop host).
5. `capture=portal`, pin `adapter_name` if multi-GPU.
6. Connect Moonlight; confirm logs in §2.1.
7. Retest with `POLARIS_PORTAL_DMABUF=0` → must stay on SHM and still stream.

Then add Phase 2 binary features, then session ownership (Phase 3), then HDR (Phase 4).

---

## 6. Contact / provenance

- Experimental host stack: luxus (lea), hybrid NVIDIA, KDE + headless gamescope.
- Issues / product tracking for this packaging: GitHub `luxus/polaris-hdr-linux-patches`.
- Upstream Polaris: `papi-ux/polaris`.

When in doubt, prefer **honest logs and SHM continuity** over a fragile zero-copy path that black-screens half the clients.
