# Handoff: iPhone / VoidLink wrong colors (teal–magenta)

**Date:** 2026-07-15  
**Host:** lea  
**Status:** **Root cause narrowed, not fixed for HDR path.** iPhone colors OK only on **labwc SDR**; broken on **portal + gamescope HDR** (Mac/tvOS OK on same host).

---

## One-line summary

VoidLink Extreme on iPhone shows severe **cyan/magenta hue shift** on the **gamescope → portal DmaBuf → `vulkan_cuda` → HEVC Main10 HDR/P010** path. Same host bitstream looks correct on **Mac Moonlight** and **Apple TV**. **labwc cage + H.264 SDR** produces correct colors on the same iPhone — so the bug is tied to the **HDR/portal/gamescope/Vulkan convert stack** (as a stream profile iOS mishandles), not generic Polaris connectivity.

---

## Symptom

- **User description:** colors “verdreht”, lots of teal/green (channel-swap feel).
- **Screenshots** (imgur): BG3 title / Steam BP library with strong cyan foliage + pink/magenta mids; HDR still “reads” as HDR (brightness/highlights).
- **Not** simple washed blacks (limited vs full alone).

---

## Client matrix (measured)

| Client | Software | Path | Video colors | Notes |
|--------|----------|------|--------------|--------|
| **livingroom** | Moonlight tvOS | portal + gamescope HDR | **OK** | JPEG or MPEG both OK after user A/B |
| **emily** (Mac) | [AmanBhardwaj25 moonlight-qt v6.1.0-wireless](https://github.com/AmanBhardwaj25/moonlight-qt/releases/tag/v6.1.0-wireless) | portal + gamescope HDR | **OK** | Audio: jitter buffer + AWDL suppress (WiFi crackle mostly fixed) |
| **Bedroom** | same Apple TV ecosystem | portal + gamescope **SDR** (`hdr: false`) | **OK** | JPEG (`color_range: 2`) OK |
| **iPhone** | **VoidLink Extreme** (stock Moonlight iOS failed earlier) | portal + gamescope HDR | **BAD** | HEVC and AV1 both bad |
| **iPhone** | VoidLink Extreme | **labwc** cage SDR H.264 | **OK** | Proves iOS can show correct colors from this host |

---

## Broken path (logs)

Typical **bad** iPhone session (portal + gamescope):

```text
polaris-hdr-session → gamescope --backend headless --hdr-enabled …
portal: PipeWire format … xBGR_210LE (spa_format=81)
CUDA DMABUF: convert_path=vulkan_cuda … fourcc=0x30334258 (XB30)
  src_xb30=true dst_p010=true
Creating encoder [hevc_nvenc]
Color coding: HDR (Rec. 2020 + SMPTE 2084 PQ)
Color depth: 10-bit
Color range: MPEG or JPEG (profile-dependent)
stream_hdr_enabled=true display_hdr=true
```

Host is doing the **intended** HDR encode path that Mac/TV decode correctly.

---

## Good path on same iPhone (logs, ~07:56)

```text
session_runtime: backend=labwc …
labwc: Ready — headless compositor active, socket=wayland-1
wlr: Using ext-image-copy-capture DMA-BUF for headless labwc
wlr: capture_transport=dmabuf frame_residency=gpu frame_format=bgra8
Creating encoder [h264_nvenc]
Color coding: SDR (Rec. 601)
Color depth: 8-bit
Color range: MPEG
stream_hdr_enabled=false display_hdr=false
target_format=nv12
# no vulkan_cuda / no P010
```

---

## Side-by-side: what differs

| Layer | labwc (iPhone colors OK) | portal/gamescope (iPhone colors BAD) |
|-------|--------------------------|--------------------------------------|
| Compositor | labwc headless cage | gamescope headless HDR (+ nested WSI session apps) |
| Capture | wlr `ext-image-copy-capture` | XDG portal ScreenCast → PipeWire |
| Pixel format | **bgra8** | **xBGR_210LE (XB30)** |
| Convert | CUDA → NV12 | **`vulkan_cuda` XB30 → P010** |
| Codec (typical) | H.264 8-bit | HEVC Main10 |
| Color tags | SDR Rec.601 | **HDR Rec.2020 + PQ** |
| HDR decision | all false | stream + display HDR true |

**Conclusion:** iOS/VoidLink mishandles **this HDR/Main10/P010/Rec.2020+PQ profile** (matrix/chroma), not “all streams from lea”.

---

## Hypotheses ruled out (or weak)

| Idea | Result |
|------|--------|
| `color_range` 0 / 1 / 2 | **No fix.** livingroom works with **JPEG and MPEG**. iPhone bad with both. |
| Force iPhone `hdr: false` (SDR encode) while still on portal/gamescope | Still bad earlier (and hybrid risks if gamescope stays HDR). labwc SDR is a *different capture stack*, not just profile flag. |
| HEVC vs AV1 | User tested both; **still wrong**. |
| Reddit Sunshine fix: `hevc_mode = 3` (advertise Main + Main10) | **Set, applied, no visual fix** for this case. (CachyOS/1660 post: different symptom class — capability advertise vs true channel mess with working HDR.) |
| Host globally wrong YUV / BGR | Contradicted by Mac + tvOS correct on same path. |
| “Always 25 Mbps” | **Agent mistake.** Historical norm was `max_bitrate=0` (client-driven ~150 Mbps). 25k/40k were **agent WiFi/audio experiment** mid-session 2026-07-15, not user baseline. |

---

## Hypotheses that still fit

1. **iOS VideoToolbox + HDR HEVC Main10 + Rec.2020/PQ VUI/SEI** wrong matrix/chroma (Mac Qt / tvOS OK).
2. **VoidLink Extreme** decode path (not stock iOS Moonlight; stock already failed for user).
3. Interaction with **portal `vulkan_cuda` convert + P010 tags** producing a combination only fragile iOS clients choke on (content may still be “valid” for other clients).
4. Secondary: gamescope Color A/B / PQ shaping still imperfect vs HDMI, but that is **wash/pale** class on TV — **not** the iPhone teal/magenta channel mess.

---

## Config notes (lea, end of 2026-07-15 investigation)

### `~/.config/polaris/client_profiles.json`

```json
{
  "Bedroom":   { "hdr": false, "color_range": 2 },
  "emily":     { "color_range": 0, "hdr": true },
  "iPhone":    { "color_range": 1, "hdr": true },
  "livingroom":{ "color_range": 2, "hdr": true }
}
```

**Semantics (Polaris / Sunshine `video_colorspace.cpp`):**

| `color_range` | Meaning |
|---------------|---------|
| 0 | Client-negotiated (`encoderCscMode` bit) |
| 1 | Force **limited / MPEG** |
| 2 | Force **full / JPEG** |

Emily/Mac with `0` often lands MPEG; iOS often lands full unless forced.

### `polaris.conf` (gamescope path restored)

- `capture = portal`
- `headless_mode = disabled`, `linux_use_cage_compositor = disabled`
- `max_bitrate = 0` (no host cap; client decides)
- `hevc_mode = 3`, `av1_mode = 3` (Main+Main10 advertise; **did not fix iPhone**)
- `audio_sink = sink-sunshine-surround51`
- systemd drop-in `hdr-portal.conf`: `XDG_CURRENT_DESKTOP=gamescope`, `GAMESCOPE_WAYLAND_DISPLAY=gamescope-0`

### Switch scripts (system)

| Script | Effect |
|--------|--------|
| `polaris-hdr-use-portal` | portal + gamescope portals + drop-in (**rewrites conf**) |
| `polaris-hdr-use-labwc` | labwc cage headless (**rewrites conf**; drops audio/max_bitrate extras unless merged) |

**labwc gotcha:** Session apps wired to `polaris-hdr-session` still start **gamescope** — wrong pairing with labwc capture (black / mismatch). labwc color A/B needs **steam/direct** (or cage-native) apps, not `polaris-hdr-session` prep.

### Apps / inject

- Most Steam titles use `polaris-hdr-session start <appid>` + `wait` (gamescope path).
- **Do not** assume both “STS2” list entries are different: inject/re-add can leave **two** entries both on `polaris-hdr-session`.
- path unit: `polaris-hdr-inject-app` watches `apps.json`.

---

## Operational incidents during investigation (for context)

1. **Agent set `max_bitrate` 40k→25k** during Mac WiFi audio knacks work — **not user**. Restored to `0`.
2. **labwc switch** broke connect when `hevc_mode=3` forced 10-bit probe → `Encoder [nvenc] failed` on cage. Labwc needed `hevc_mode=1` (or non-Main10 probe) for H.264-only success.
3. **Return to portal** failed until `polaris-hdr-use-portal` + restart **`polaris-hdr-idle`** + xdg portals (ScreenCast response code 2 / “interface not available”).
4. Config snapshots:  
   - `~/.config/polaris/snapshots/LATEST-GOOD` (pre-labwc baseline)  
   - `~/.config/polaris/snapshots/PRE-LABWC`

---

## Related (not the same bug)

| Topic | Relation |
|-------|----------|
| Patch `05` P010 / `sw_format` | Fixed earlier green/pink **host** bug for all clients; iPhone issue remains **after** that fix |
| Host polish 2026-07-15 | `02` exact Rec.2020 primaries; `05` P010 uses `new_color_vectors` (10-bit). **Not expected to fix iPhone channel mess**; retest Mac/TV after deploy. Gamescope Color A+B/PQ unchanged. |
| Mac audio crackle | WiFi; mitigated by moonlight-qt wireless fork (jitter buffer + AWDL) |
| Easy Effects / sink-sunshine-* | Audio routing; unrelated to iPhone hue |

---

## Recommended next steps (priority)

1. **Treat iPhone HDR colors as client-profile issue** for VoidLink + gamescope HDR stream; do not thrash host color_range again without a new hypothesis.
2. **Optional host experiments** (only if someone owns the time):  
   - Force **SDR encode** on portal path with **true** gamescope SDR (no hybrid `display_hdr`/PQ capture) and retest iPhone.  
   - Capture one HEVC bitstream sample; compare VUI/SEI Main10 vs what VideoToolbox expects.  
   - Try stock Moonlight iOS again on a clean install (user said stock failed; worth re-check after VoidLink).
3. **Product/docs:** document labwc vs portal for mobile: labwc = iPhone-safe SDR; portal/gamescope = HDR for TV/Mac.
4. **Do not** re-enable experimental ColorMgmt / forced PQ paint without measured plan (`archived/` history).
5. When editing `polaris.conf` via switch scripts, **merge** `audio_sink` / `max_bitrate` / `hevc_mode` — scripts overwrite.

---

## Quick verification commands

```bash
# Current mode
rg 'capture|headless|cage|hevc_mode' ~/.config/polaris/polaris.conf

# Last session color path
journalctl --user -u polaris --since '30 min ago' --no-pager | \
  rg 'Session started|backend=|Color coding|Color range|HDR decision|convert_path|frame_format|labwc|portal:'

# Expect BAD iPhone (portal HDR):
#   Color coding: HDR (Rec. 2020 + SMPTE 2084 PQ) + vulkan_cuda + dst_p010=true

# Expect GOOD iPhone (labwc SDR):
#   backend=labwc + frame_format=bgra8 + h264 + SDR Rec. 601 + stream_hdr_enabled=false
```

---

## Decision for handoff owner

| Goal | Action |
|------|--------|
| Ship TV/Mac HDR | Keep **portal + gamescope**; leave iPhone as known-bad on HDR or use labwc for mobile |
| Fix iPhone HDR | Investigate VoidLink / VideoToolbox vs HEVC Main10 PQ tags; optional host VUI/metadata experiments |
| Don’t break lea again | Use snapshots; prefer `polaris-hdr-use-portal` / `use-labwc` with key merge; don’t invent bitrate caps |

**Bottom line:** Problem is real and reproducible. Host HDR path is valid for Mac/tvOS. iPhone/VoidLink + **portal/gamescope/Vulkan/P010/HDR** stack is the failing combination; labwc SDR is the working control.

---

## Follow-up tests 2026-07-15 ~09:00 (VoidLink UI)

User retested on portal/gamescope with VoidLink Extreme toggles:

| Client toggle | Host log (iPhone) | Picture (user) |
|---------------|-------------------|----------------|
| **Metal render mode** | same as before | **no help** |
| **HDR on** | `HDR Rec.2020+PQ`, P010, `stream_hdr=true` `display_hdr=true` | shifted teal/magenta (known) |
| **HDR off + SDR workaround ON** | (client-side tonemap of Main10-ish path) | “like HDR without HDR” = still wrong hue class |
| **HDR off + SDR workaround OFF** | see hybrid row below | **blue+green only** (screenshot [imgur mP9Rt7S](https://imgur.com/mP9Rt7S)); app banner: enable workaround for SDR play |
| **SDR “works”** | true when path is honest SDR (labwc, or full SDR stack) | colors OK |

### Hybrid SDR-client / HDR-display (host) — important

Sessions **08:57:45** and **08:59:18** (iPhone):

```text
Color coding: SDR (Rec. 601)
Color range: MPEG
target_format=nv12
HDR decision: client_dynamic_range=0 display_hdr=true
  hdr_metadata_available=false stream_hdr_enabled=false
```

Interpretation:

- Client asked **SDR encode** (`stream_hdr_enabled=false`, Rec.601 NV12).
- Gamescope session still **HDR-capable / HDR output** (`display_hdr=true`).
- Capture can still be **PQ-shaped 10-bit RGB** while bitstream is tagged **SDR** → VoidLink without “SDR workaround” shows catastrophic chroma (blue/green plane mess); workaround tries to compensate client-side and lands near the HDR-wrong-hue look.

This matches AGENTS.md / hybrid wash history: **never leave `display_hdr=true` with `stream_hdr=false`** as a supported mobile path.

### Screenshot without SDR workaround

- Steam BP UI: structure visible (BG3 tile, Brotato, PATCH NOTES).
- Palette collapsed to **blue + green only** (R channel effectively dead / UV catastrophic).
- Not the same as HDR teal/magenta — worse, classic “wrong bit depth / PQ as SDR without fixup”.

### Practical VoidLink guidance (after host hybrid fix deploy)

| Play mode | Recommendation |
|-----------|----------------|
| Want correct colors on iPhone | **labwc** or true SDR host (profile `hdr:false` **and** gamescope SDR) |
| HDR stream | accept wrong colors on VoidLink, or use Mac/TV |
| Client HDR off | **enable SDR workaround** or expect blue/green; better force host SDR fully |

### Host fix (done 2026-07-15)

Polaris patch **`06-session-hdr-force-sync`**:
- On session start: write `polaris-hdr-force` from final `enable_hdr` (client profile / negotiation).
- On video HDR probe: re-sync force from stream `dynamicRange` (encode truth).
- If force flips and nested WSI is **not** active → `systemctl --user try-restart polaris-hdr-idle` so headless gamescope drops `--hdr-enabled`.

**iPhone host profile:** `hdr: false` (so prep/`POLARIS_CLIENT_HDR` stay SDR).

**PQ/Color A+B:** left **on** for TV/Mac HDR path (not an iPhone lever).

Expect after deploy: iPhone → `display_hdr=false stream_hdr_enabled=false` + idle/nested **SDR mode** + 8-bit/NV12 (not hybrid `display_hdr=true` + SDR encode).
