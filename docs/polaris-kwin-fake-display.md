# Plan: Fake 4K HDR screen for KWin (no dummy plug)

**Goal:** Force a virtual monitor on the **4090** so we can stream from a real KWin
output without ordering a DP/HDMI dummy adapter. Prove “screen exists → KWin sees
it → optional HDR / capture” before any Polaris rewrite.

**Tracking context:** polaris [#152](https://github.com/papi-ux/polaris/issues/152)
(forged EDID / semi-headless), local [#131](https://github.com/luxus/luxusAi/issues/131)
(washed HDR color), gamescope headless path already in use.

**Status:** **P1 green on lea (2026-07-12).** P3 HDR enable **rejected** (expected NVIDIA virtual-connector limit).

**Research used:**
- [HarryAnkers gist](https://gist.github.com/HarryAnkers/8dbf551d66f00e8156ef4dd2b2b090a0) — NVIDIA: both `drm.edid_firmware` + `video=<conn>:e`; EDID needs HDMI VSDB or modes cap ~1080p; HDR often still fails on virtual connectors.
- [NixOS discourse virtual screen](https://discourse.nixos.org/t/nixos-sunshine-setup-using-a-virtual-screen/64857) — `hardware.display.edid` + outputs.
- NixOS `hardware.display.outputs."<conn>".mode = "e"` + `.edid = "….bin"`.

### Results (lea)

| Check | Result |
|-------|--------|
| Connector | `card1-DP-1` (4090), free — real screens stay DP-2 + HDMI-A-1 |
| Kernel | `connected`, modes include 3840×2160 |
| KWin | enabled, **3840×2160@60**, scale 1, window movable |
| HDR toggle | **rejected** / stays disabled — matches NVIDIA virtual/force-enabled connector limit (no real SCDC/HDMI 2.1 link) |
| Config | `modules/hosts/lea/default.nix` + `firmware/lea-stream-4k60.bin` |

---

## Why this first

| Without adapter | With dummy plug later |
|-----------------|------------------------|
| Kernel EDID + `video=…e` on a free 4090 connector | Same UX, hardware EDID |
| Zero shopping delay | Backup if firmware EDID flaky on NVIDIA |

If this fails on proprietary NVIDIA, order a cheap DP dummy plug and skip to
hardware EDID — same KWin/capture plan after that.

---

## Hardware reality on lea (snapshot)

| DRM | GPU | Connectors (all often `disconnected` when idle) |
|-----|-----|--------------------------------------------------|
| `card1` / `renderD128` | **NVIDIA 4090** | `DP-1`, `DP-2`, `DP-3`, `HDMI-A-1`, `HDMI-A-2` |
| `card0` / `renderD129` | AMD | `DP-4`, `DP-5`, `HDMI-A-3` |

**Rule:** force EDID only on **`card1`** (4090). Never on AMD — capture GPU must
stay equal to NVENC (`polaris_pin_nvidia_gpu` / `renderD128`).

**Connector:** any free **card1** name is fine — **DP or HDMI, no preference**.
Try in order until one sticks: `DP-1` → `DP-2` → `DP-3` → `HDMI-A-1` → `HDMI-A-2`.
Document which name won; kernel params must match that name.

**Refresh:** **4K@60 first** (easier EDID + modes). 120 only after 60 is solid (stretch; ATV is 60 max anyway).

Confirm after boot with:

```bash
for c in /sys/class/drm/card1-*; do
  [ -e "$c/status" ] || continue
  echo "$(basename "$c") status=$(cat "$c/status") enabled=$(cat "$c/enabled")"
done
```

---

## Approach (chosen)

**Kernel forced connector + firmware EDID** (community Sunshine/Moonlight path).

```text
drm.edid_firmware=DP-1:edid/<blob>.bin
video=DP-1:e                    # phase 1: enable connector
# later: video=DP-1:3840x2160@60e  or @120e once modes work
```

Not using for phase 1:

- `krfb-virtualmonitor` — easy extra desktop, weak/no real HDR pipeline  
- gamescope headless fake EDID — already have that; goal here is **KWin**  
- Full Polaris/KWin capture rewrite — only after KWin lists the output  

---

## Phases

### Phase 0 — Prep (no reboot)

1. Choose connector: default **`DP-1`** (card1). Document if another is preferred.
2. Obtain or build an EDID binary:
   - **Phase 0 (only):** known **4K60** EDID (HDR10 flags nice-to-have, not required for P1).
   - **Later:** swap or extend blob for 120 only after 60 works.
3. Ship blob in Nix as firmware, e.g.:
   - `hardware.firmware` / `hardware.display.edid.packages` style, or  
   - `environment.etc` + initrd include so `drm.edid_firmware=` can load early.
4. **Must** include EDID in **initrd** if the mode is needed at KMS early boot  
   (dracut/nixos: `boot.initrd.extraFirmwarePaths` or equivalent).

**Success (P0):** blob path known, e.g. `/run/current-system/firmware/edid/…bin`,
size ~128–256+ bytes, documented source.

### Phase 1 — Fake the screen only (SDR OK)

1. Add kernel params on lea (host module only), connector name = whatever we chose:

   ```nix
   boot.kernelParams = [
     "drm.edid_firmware=<CONN>:edid/lea-stream-4k60.bin"  # e.g. DP-1 or HDMI-A-1
     "video=<CONN>:e"  # force enable; optional :3840x2160@60e once stable
   ];
   ```

   Exact `edid/` path must match firmware layout.

2. `nh os switch` + **reboot** (kernel params / firmware).

3. Verify (replace `<CONN>`):

   ```bash
   cat /sys/class/drm/card1-<CONN>/status    # expect connected
   cat /sys/class/drm/card1-<CONN>/enabled
   kscreen-doctor -o
   ```

4. Manually set **4K60** if needed:

   ```bash
   kscreen-doctor output.<CONN>.enable
   kscreen-doctor output.<CONN>.mode.3840x2160@60
   ```

   (KWin name may differ slightly — use `kscreen-doctor -o`.)

**Success (P1):** KWin shows the output at **3840×2160@60**, no cable.  
**Fail:** try next card1 connector name; all fail → dummy plug.

### Phase 2 — 120 Hz (optional, later)

Only after P1 is boring-stable. New EDID or extra mode; ATV still 60.
Not required to validate “fake screen works.”

### Phase 3 — HDR enable on that output

1. System Settings → Display → HDR on the fake output, **or** KWin HDR toggle.
2. Log whether KWin reports HDR active vs “capable only” (NVIDIA often sticks at capable).
3. Note max luminance / color profile if exposed.

**Success (P3):** HDR **enabled** (not only capable) on the fake head.  
**Soft fail:** capable-only — still useful for capture geometry; color work
(partially) still on #131 / gamescope path.

### Phase 4 — Capture smoke (minimal)

No new polaris patches required at first:

1. Ensure polaris **not** forcing `XDG_CURRENT_DESKTOP=gamescope` (labwc/portal
   default or KDE portal).
2. Start a short stream; in logs look for portal/KWin path and frame format.
3. Optionally fullscreen a color chart on the fake output only.

**Success (P4):** visible stream of that output; log first-frame transport/format.  
Compare washed menus vs gamescope HDR only if both work (inform #131).

### Phase 5 — Decide (stop or invest)

| Outcome | Next |
|---------|------|
| Fake 4K works, HDR on, capture OK | Optional: polaris “stream head” app + pin to that output; drop gamescope for daily HDR |
| Fake 4K works, HDR fails | Keep geometry for SDR stream head; color stays gamescope/#131 |
| Fake connector never connects | Order dummy plug; reuse phases 2–4 with real EDID from plug |
| Cross-GPU / black | Re-check pin to `renderD128`; ensure Steam/KWin on NVIDIA |

---

## Explicit non-goals (this plan)

- Replacing gamescope path before P1 green  
- CUDA / zero-copy work  
- Shipping 120 as a product requirement for ATV  
- Blacklisting `amdgpu`  
- Multi-plane portal adventures  

---

## Risks

| Risk | Mitigation |
|------|------------|
| Wrong connector name after driver renumber | Always re-list `/sys/class/drm/card1-*` after reboot |
| EDID in rootfs but not initrd | Modes missing at boot; add to initrd firmware |
| NVIDIA ignores forced EDID | Dummy plug; don’t invent more kernel hacks |
| Plasma layout breaks (panel on fake head) | kscreen layout: primary = real panel if any; stream head secondary |
| Hybrid: KWin on AMD, encode NVIDIA | Pin + force modeset only on card1 |

---

## Suggested implementation order in *this* repo (when executing)

1. `pkgs/` or `modules/`: EDID derivation + firmware install (one blob, documented origin).  
2. `modules/hosts/lea/default.nix`: `boot.kernelParams` + initrd firmware (comment: connector choice).  
3. Reboot → P1 checklist.  
4. Only then: kscreen one-shots / optional systemd user unit to enable mode (avoid if manual is enough).  
5. Capture notes into `docs/agents/polaris-hdr-color.md` or a short “results” section here.

**Rollback:** remove the two kernel params + firmware entry, switch, reboot.
Connector returns to disconnected.

---

## Success summary (definition of done for “just try to fake the screen”)

**Minimum (what you asked for first):**

- [ ] After reboot, some `card1-*` (DP or HDMI) `status=connected` with **no cable**  
- [ ] KWin/kscreen lists it at **3840×2160@60**  
- [ ] Can place a window on it  

**Stretch (not required first):**

- [ ] 120 Hz mode works  
- [ ] HDR enabled on that output  
- [ ] One Polaris/KWin portal frame of that output  

No adapter ordered unless P1 fails on **all** card1 DP/HDMI names.
