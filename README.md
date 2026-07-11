# polaris-hdr-linux-patches

**Status: ON HOLD (2026-07)**

Experimental Linux patches for **HDR GameStream** on hybrid NVIDIA hosts:

- [papi-ux/polaris](https://github.com/papi-ux/polaris) portal capture (DmaBuf / 10-bit / EGL)
- [gamescope](https://github.com/ValveSoftware/gamescope) headless HDR + PipeWire DmaBuf

Developed in [luxus/luxusAi](https://github.com/luxus/luxusAi) for machine **lea** (RTX 4090 + AMD iGPU).

## Why on hold

The gamescope + patched polaris path **works** for 4K HDR encode (DmaBuf `XB30`, NVENC ~8 ms, convert ~1 ms), but:

- HDR **color** can look washed vs HDMI ([notes](docs/polaris-hdr-color.md))
- Stack is heavy (custom gamescope, portal, idle session)
- Next experiment: **physical 4K HDR dummy** on the 4090 + KWin capture (simpler display path)

Patches stay here so they are not lost and can be offered upstream / rebased later.

## Layout

```
polaris/     Apply to papi-ux/polaris (portal_grab, graphics, cuda)
gamescope/   Apply to Valve gamescope (headless + pipewire)
docs/        Design / color / fake-display notes from luxusAi
```

### Polaris (apply in order)

1. `polaris/portal-dmabuf-capture.patch` — PipeWire DmaBuf, prefer `xBGR_210LE`, first-frame log  
2. `polaris/egl-dmabuf-import.patch` — bare-tex + `TexStorageEXT` (NVIDIA + gamescope)  
3. `polaris/cuda-gl-dmabuf.patch` — prefer `renderD*`, EGL import + mmap fallback  

Also published as a gist:  
https://gist.github.com/luxus/e2cf68243c3f23b9934cea8ade4339bb

Upstream context: [polaris#152](https://github.com/papi-ux/polaris/issues/152)

### Gamescope

1. `gamescope/headless-hdr-colorimetry.patch` — fake EDID / HDR on headless backend  
2. `gamescope/pipewire-hdr-metadata.patch`  
3. `gamescope/pipewire-color-mgmt.patch`  
4. `gamescope/pipewire-prefer-dmabuf.patch` — DmaBuf without modifier fixation  

## Proven on lea (at freeze)

| Item | Result |
|------|--------|
| Capture | DmaBuf, 10-bit `XB30` / `xBGR_210LE` |
| Import | EGL TexStorageEXT OK; CUDA extmem fails on gamescope dmabufs |
| Dual-GPU | Pin NVIDIA `renderD128` (do not blacklist amdgpu) |
| Encode | HEVC NVENC HDR P010; ~8–9 ms at 4K |
| Client | Apple TV max 60 Hz |

## Not included

- Full NixOS module packaging (`polaris-stream`, `gamescope-hdr` packages) — lives in luxusAi  
- Software force-EDID fake KWin head (`video=DP-1:e`) — still in luxusAi host config  
- JetKVM — TC358743 ~1080p class; not a 4K HDR sink  

## License

Patches are modifications of GPL projects (Polaris GPL-3, gamescope BSD-2-Clause / MIT mix).  
Distribute patches under the same terms as the upstream trees you apply them to.

## Resume checklist

1. Rebase onto current polaris / gamescope tips  
2. Re-test DmaBuf first frame + HDR metadata  
3. Decide: keep for gamescope path vs drop if KWin+dummy HDR is good enough  
