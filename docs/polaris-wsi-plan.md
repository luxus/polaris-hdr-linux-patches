# Gamescope nested WSI

**Tracking:** [#6](https://github.com/luxus/polaris-hdr-linux-patches/issues/6)  
**Package:** `gamescope-hdr` keeps **`enableWsi = true`** (layer always built). Attach-only paths have been flaky on lea; nested WSI is the path that has actually worked for presentation.

## Guardrails

- Do **not** set `ENABLE_GAMESCOPE_WSI` / `ENABLE_HDR_WSI` on a plain attach path “to fix capture/color”. WSI is presentation, not PipeWire/CUDA.
- Do not patch around a failed FROG hook; `Creating swapchain for non-Gamescope swapchain` means surface registration never happened.
- Do not change DmaBuf / Vulkan→CUDA / HDR encode while chasing WSI.
- Prefer proving one nested title green over inventing new attach hacks.

## What worked (2026-07-14 lea)

### Desktop nest (not Polaris attach)

Steam on KWin; launch options: `gamescope-hdr` parent of Proton. AC6:

- Child: `ENABLE_GAMESCOPE_WSI=1`, `GAMESCOPE_WAYLAND_DISPLAY=…/gamescope-socket`, `DISPLAY=:N`, `DXVK_HDR=1`; no host `WAYLAND_DISPLAY`; no `ENABLE_HDR_WSI`
- Full surface/swapchain hook; HDR10 `A2B10G10R10` + `HDR10_ST2084`; user color OK

### Polaris nest BP→BG3

`POLARIS_GAMESCOPE_WSI=1` session → nested gamescope + BP → BG3:

- Portal still `spa_format=81` / XB30 → `vulkan_cuda` → P010 + Rec.2020/PQ after `sw_format` fix
- Presentation WSI green; capture stack unchanged

## Remaining (#6)

Session packaging/docs on consumer (luxusAi): when to nest, env contract, not more patch experiments in this repo unless a new broken boundary is isolated.

## Loader notes

- Gamescope sets `GAMESCOPE_WAYLAND_DISPLAY` + `ENABLE_GAMESCOPE_WSI=1` for its primary nested child.
- `ENABLE_HDR_WSI` is the separate `VK_hdr_layer` (often absent); if present, Gamescope children may need `DISABLE_HDR_WSI=1`.
- Conflicts: MangoHud / vkBasalt / other implicit layers.
