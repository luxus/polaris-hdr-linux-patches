# Polaris HDR color quality (washed / colorless)

**Status:** deferred follow-up — capture/perf path is usable; color fidelity is not HDMI-like.  
**Tracking:** [#131](https://github.com/luxus/luxusAi/issues/131)  
**Patches (on hold):** [luxus/polaris-hdr-linux-patches](https://github.com/luxus/polaris-hdr-linux-patches)  
**Related:** `docs/agents/polaris-hdr-dmabuf-plan.md` (DmaBuf/GPU path), KWin dummy path in `polaris-kwin-fake-display.md`.

## Symptom (user)

- HDR stream looks **a little washed out / colorless** vs connecting the PC to the TV over HDMI.
- Menus hard to read; less “pop” / saturation.
- Not investigated live beyond logs yet; more games to A/B later.

## What is already proven (do not re-litigate)

| Fact | Evidence |
|------|----------|
| Capture is **10-bit RGB DmaBuf** | `spa_format=81`, `drm_fourcc=XB30` (`xBGR_210LE`), `cpu_copy=0` |
| Stream tags **HDR HEVC** | `Color coding: HDR (Rec. 2020 + SMPTE 2084 PQ)`, 10-bit |
| Metadata is **present but hardcoded** | `max_luminance=1000`, `max_cll=1000`, `max_fall=400` from portal stub |
| Convert (RGB→P010) is **cheap** vs encode | one-off measure: convert ≈ **0.7–1.0 ms**, encode ≈ **8.2–8.8 ms** |
| UI “encode ms” ≈ **NVENC only** | not convert; window sampling can look a bit higher than a single lucky sample |

**Implication:** washed color is almost certainly **not** “missing native P010” and not “spend another adventure on zero-copy.” Convert must exist for GameStream HEVC HDR; the issue is **how** RGB is interpreted and **how** HDR is signalled.

## Pipeline (mental model)

```text
gamescope  ──XB30 RGB10 DmaBuf──►  EGL texture
                                    │
                                    ▼  GL ConvertY/UV (BT.2020 matrix only on Linux)
                                 P010 Y′CbCr
                                    │
                                    ▼  NVENC HEVC + HDR10 SEI/metadata
                                 Apple TV / Moonlight → TV tone-map
```

HDMI: GPU display path → TV (one HDR chain).  
Stream: capture → convert → compress → client → TV (extra tags + extra tone-map).

## Ranked hypotheses (color / “colorless”)

1. **Hardcoded HDR10 mastering metadata**  
   Portal `get_hdr_metadata()` always reports Rec.2020 + 1000 nit peak / fixed maxCLL/maxFALL.  
   TV/ATV tone-map for the wrong luminance story → flat, desaturated, low contrast text.

2. **Linux GL convert is matrix-only (no PQ-aware path)**  
   Shaders: `ConvertY.frag` / `ConvertUV.frag` — `y = dot(matrix, rgb)` only.  
   Windows has separate **PQ perceptual quantizer** convert shaders; Linux does not.  
   Correct only if gamescope buffer is already **PQ-encoded Rec.2020 R′G′B′** (BT.2100 NCL).  
   If buffer is linear/scRGB-ish / differently shaped 10-bit RGB but stream is tagged PQ → classic washed HDR.

3. **Client + TV double tone-mapping**  
   Gamescope headless already shapes for a virtual ~1000 nit EDID; Apple TV + panel may tone-map again.

4. **Range / bitrate (secondary)**  
   Logs show JPEG vs MPEG range on different sessions; wrong range lifts/crushes. Heavy compression kills chroma.

5. **Not the main issue:** eliminating RGB→P010 “for native” — does not fix HDMI-like look; ~1 ms and required for this codec path.

## What “HDMI-like” actually needs

Priority for **look** (not 120 FPS):

1. Correct transfer + matrix for **what gamescope actually writes** (PQ R′G′B′ vs linear).
2. Honest HDR10 metadata (or measured), not only a fixed 1000/400 stub.
3. Client/TV path not double-tonemapping (or match HDMI’s single map).
4. Then bitrate / limited-vs-full polish.

## Experiments when resuming (minimal)

1. Same scene **HDMI vs stream** (same game, same TV); note ATV HDR indicator and menu text readability.
2. Confirm live log still: `10-bit` DmaBuf + `HDR (Rec. 2020 + SMPTE 2084 PQ)`.
3. Dump or document gamescope output color model (PQ vs linear) for the headless HDR session.
4. A/B metadata: real/measured vs hardcoded stub (if we can read from gamescope/EDID).
5. Only if (3) says linear: investigate Linux PQ-aware convert (Windows shader parity) — do not start that before (3).

## Code touch points (later)

- `pkgs/polaris-stream` → portal `get_hdr_metadata()` / gamescope HDR session detection  
- Linux shaders: `src_assets/linux/assets/shaders/opengl/Convert{Y,UV}.frag`  
- Compare Windows: `convert_*_perceptual_quantizer*`  
- `video_colorspace.cpp` / range (JPEG vs MPEG)  
- UI: stock `encode_time_ms` only (`convert_ms` instrumentation removed — not useful for color work)

## Out of scope for this note

- 120 FPS encode budget (~8 ms NVENC) — separate from color.
- Frontend convert_ms display — not needed.
- Further DmaBuf adventures for color alone.

## Related plan

Fake KWin screen without dummy plug: [`polaris-kwin-fake-display.md`](./polaris-kwin-fake-display.md).

## Live update 2026-07-13

Portal **0011** makes client HDR engage (`stream_hdr_enabled=true` on livingroom; Bedroom stays SDR).  
Visual: still washed on livingroom (HDR-tagged) and not HDMI-like on either device.  
SHM capture still forces **prefer_8bit** NV12 CUDA upload — likely next bottleneck after metadata.

## Live update 2026-07-13 (true-SDR gamescope)

When client HDR force is off (`cv_hdr_enabled=false` / no force file):

- Headless `SetHDR(false)`: **no** `bExposeHDRSupport`, no HDR EDID patch, Gamma22
- PipeWire path keeps **screenshot** LUTs (not display HDR LUTs)
- `outputEncodingEOTF` stays Gamma22 unless `g_bOutputHDREnabled`

Goal: Bedroom SDR no longer inherits HDR-capable headless colorimetry wash.
Livingroom HDR path unchanged when force is on. SHM `prefer_8bit` wash on HDR still open.

## Live update 2026-07-13 (DmaBuf green, wash remains)

After **0014**, portal capture is GPU DmaBuf + EGL import on both clients. Livingroom still washed with HDR game:

- Stream: HDR10 / Rec.2020+PQ / 10-bit tags / stub metadata
- Capture: still `bgra8` (BGRx), not 10-bit `xBGR_210LE`
- Encode: `p010`

**Env research** (gamescope#1404, ChimeraOS#123, gamescope#2037): `GAMESCOPE_WAYLAND_DISPLAY` already set; KDE nested HDR fix N/A for headless. **WSI enabled** in `gamescope-hdr` (`enableWsi`) so `ENABLE_GAMESCOPE_WSI` / client-HDR `ENABLE_HDR_WSI` can load `VkLayer_FROG_gamescope_wsi`. See issue #1 comments for tables.

Wash ranking no longer led by SHM — led by **8-bit capture + HDR tags** (+ metadata/convert).

## Live update 2026-07-13 (0015 prefer 10-bit)

Root cause of BGRx lock: polaris EnumFormat only listed 8-bit packed RGB while gamescope force-HDR **does** advertise `xBGR_210LE` (spa 81). **0015** prefers `xBGR_210LE` / `DRM_FORMAT_XBGR2101010` and force-offers LINEAR so negotiation can settle on 10-bit. Expect log: `spa_format=81` / `frame_format=p010` (10-bit class) when force-HDR.
