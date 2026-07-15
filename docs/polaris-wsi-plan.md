# Gamescope nested WSI plan

**Tracking:** [#6](https://github.com/luxus/polaris-hdr-linux-patches/issues/6)  
**Priority:** low; the default attach path already works  
**Goal:** either make nested Steam/Proton presentation through `VkLayer_FROG_gamescope_wsi` reliable or remove the experimental mode

## Guardrails

- Keep **XWayland attach** to `polaris-hdr-idle` as the default and known-good path.
- Never set `ENABLE_GAMESCOPE_WSI` or `ENABLE_HDR_WSI` on the attach path to improve portal capture or color. WSI controls client presentation, not PipeWire capture or RGB-to-P010 conversion.
- Do not hide the Gamescope warning, force bypass, or patch around a failed hook. The warning means the layer intercepted swapchain creation without owning the corresponding surface.
- Do not change the active DmaBuf, Vulkan-to-CUDA, HDR metadata, or encode patches while diagnosing WSI.
- Make no Gamescope source patch until a minimal test reproduces the failure and identifies the broken boundary.

## Current evidence

### Packaging / layer (unchanged)

- `gamescope-hdr` is Gamescope 3.16.24 with `enableWsi = true`; its implicit-layer manifest and x86_64 shared library are present.
- Gamescope sets `GAMESCOPE_WAYLAND_DISPLAY` and sets `ENABLE_GAMESCOPE_WSI=1` for a primary nested child. Session code should not need to emulate this.
- The layer creates per-instance state only when `GAMESCOPE_WAYLAND_DISPLAY` exists and does not conflict with a different non-empty `WAYLAND_DISPLAY`.
- A valid X11 path should log `Creating Gamescope surface`, create paired Wayland/XCB surfaces, and register the returned `VkSurfaceKHR` before `CreateSwapchainKHR`.
- The observed `Creating swapchain for non-Gamescope swapchain` message means that registration did not happen, or that a different layer/path supplied the surface later used by the swapchain.
- `ENABLE_HDR_WSI` activates the separate `VK_hdr_layer`; it is not consumed by Gamescope or DXVK. No matching manifest is present in the current host profile or inspected Steam runtimes, so the variable appears inert here. If that layer is installed later, its Gamescope instructions require disabling it for Gamescope's children.
- Known layer conflicts include injected MangoHud/vkBasalt and overlays.

### 2026-07-14 lea — desktop nested WSI success (AC6)

**Topology (not Polaris attach):** Steam started under **KWin**; game launch options run `gamescope-hdr` as the parent of Proton/the title. A headless Polaris idle gamescope was also present on the host but was not the presentation path.

```text
DXVK_HDR=1 gamescope --force-grab-cursor --cursor-scale-height 2160 \
  -W 5120 -H 2160 -r 75 -f --hdr-enabled -- %command%
```

| Item | Observed |
|------|----------|
| Gamescope | `gamescope-hdr` 3.16.24 (`/nix/store/...-gamescope-hdr-3.16.24`) |
| Title | Armored Core VI (`1888160`), GE-Proton11-1, process `armoredcore6.exe` |
| Child env (`/proc`) | `ENABLE_GAMESCOPE_WSI=1`, `GAMESCOPE_WAYLAND_DISPLAY=/run/pressure-vessel/gamescope-socket`, `DISPLAY=:3`, `DXVK_HDR=1`; **no** `WAYLAND_DISPLAY` on the game; **no** `ENABLE_HDR_WSI` |
| Socket | pressure-vessel bind of nested `gamescope-*` socket present and used |
| WSI logs | full success sequence for `armoredcore6.exe` — surface create/made, swapchain create/created **for xid**; **no** `non-Gamescope` / non-hooked warning |
| Surface state | `server hdr output enabled: true`, `hdr formats exposed to client: true`, steam app id `1888160` |
| HDR path | bootstrap SDR → 10-bit sRGB → final `A2B10G10R10` + `VK_COLOR_SPACE_HDR10_ST2084_EXT`; `VkHdrMetadataEXT`; refresh cycle ~13.33 ms (75 Hz) |
| Color | **user-confirmed excellent** (not washed; HDR highlights look correct) |
| Harmless noise | `Atom of T was wrong type`; nested X0–X2 already taken by idle session; Proton helpers (`explorer.exe`, etc.) also emit WSI Application info |

**What this proves:** Phase 4 gate for one Proton title when Gamescope is the **game's** primary parent (Steam launch-option nest under desktop KWin). HDR presentation + metadata + visual color are green on this path.

**What this does not prove:** Polaris session nested mode / opt-in wiring; portal capture (`dmabuf` / `vulkan_cuda`) of a nested-WSI instance; attach-path regression matrix; Steam itself as Gamescope's primary child (Big Picture inside Gamescope).

## Phase 1: freeze the baseline

- [ ] Record one known-good attach run with WSI variables absent from the Steam/Proton process.
- [ ] Save Gamescope, Steam/Proton, Polaris, and Vulkan loader versions plus the selected Vulkan device.
- [ ] Confirm portal capture still reports `capture_transport=dmabuf`, `convert_path=vulkan_cuda`, and the expected SDR or HDR stream tags.
- [ ] Keep this run as the regression reference; do not alter the attach branch during WSI work.

**Gate:** attach remains stable, visually correct, and free of Gamescope WSI-layer logs.

## Phase 2: prove packaging and loader state

- [ ] Build `.#gamescope-hdr` and inspect both the implicit-layer manifest and referenced library.
- [ ] Use Vulkan loader diagnostics to prove which `VK_LAYER_FROG_gamescope_wsi_*` manifest is loaded by the child. Reject duplicate system, Steam-runtime, or Flatpak copies.
- [ ] Confirm that `VK_hdr_layer` is absent from the child. If installed later for an outer Wayland compositor, pass `DISABLE_HDR_WSI=1` to Gamescope's children.
- [ ] Capture the child process environment from `/proc/<pid>/environ`; verify the effective values of `DISPLAY`, `GAMESCOPE_WAYLAND_DISPLAY`, `WAYLAND_DISPLAY`, `ENABLE_GAMESCOPE_WSI`, `DISABLE_GAMESCOPE_WSI`, and Vulkan layer variables.
- [ ] Run the first test without MangoHud, vkBasalt, ReShade, OBS Vulkan capture, or other implicit layers. Add them back only after WSI works alone.
- [ ] Prove the 64-bit path first. Check i686 packaging only if a failing title actually creates a 32-bit Vulkan process.

**Gate:** one known Gamescope layer is loaded into the intended Vulkan process and can connect to the expected `gamescope-*` socket.

## Phase 3: reduce to a minimal primary child

Start with a small native X11 Vulkan client as Gamescope's direct primary child. Do not involve Steam, Proton, Polaris, HDR, or the portal yet.

Test in this order:

1. Headless Gamescope + direct Vulkan child, SDR, no `--expose-wayland`.
2. The same test with `--expose-wayland` only if the final portal topology requires it.
3. The same test with HDR enabled.
4. Steam as the direct primary child, then one Proton title.

The required successful sequence is:

```text
[Gamescope WSI] Application info:
[Gamescope WSI] Creating Gamescope surface: xid: ...
[Gamescope WSI] Made gamescope surface for xid: ...
[Gamescope WSI] Surface state:
  server hdr output enabled: ...
  hdr formats exposed to client: ...
[Gamescope WSI] Creating swapchain for xid: ...
[Gamescope WSI] Created swapchain for xid: ...
```

Interpret failures from the **first missing line**:

| First missing/failing event | Investigation |
|---|---|
| Layer absent | Wrong manifest search path, architecture, runtime namespace, or activation environment |
| `Application info` absent but layer device logs appear | `GAMESCOPE_WAYLAND_DISPLAY` missing, `WAYLAND_DISPLAY` points elsewhere, or instance hooks did not initialize Gamescope state |
| Application initialized, no `Creating Gamescope surface` | XCB/Xlib surface hook bypassed; inspect loader ordering and the WSI backend selected by the application |
| Surface creation starts but does not finish | Gamescope Wayland protocol/socket, XCB fallback surface, or GPU/device mismatch |
| Surface is made, then swapchain is “non-Gamescope” | A second instance/surface path or another Vulkan layer replaced or created the swapchain input |
| Swapchain succeeds, present is “non-hooked” | Secondary swapchain, layer-order conflict, or swapchain bookkeeping failure |
| WSI succeeds only without `--expose-wayland` | Keep it removed from the nested child topology unless portal capture proves it necessary |

**Gate:** a clean native Vulkan child completes surface creation, swapchain creation, and presentation without warning. If this fails, do not edit the Polaris session wrapper.

## Phase 4: isolate Steam and Proton

- [ ] Launch Steam as Gamescope's primary child so Gamescope owns the child environment and enables its WSI layer itself.
- [x] Verify the actual game process inherits the same Gamescope socket and layer activation; do not infer this from Steam's environment alone. *(2026-07-14: AC6 under launch-option gamescope — `/proc` + WSI logs; Steam stayed on KWin)*
- [x] Test one Proton title without Big Picture as the outer compositor child. *(2026-07-14: AC6 / GE-Proton11-1; launch-option nest, not `-applaunch` under nested Steam)*
- [x] Add `DXVK_HDR=1` for the HDR case. *(set in launch options; `STEAM_GAMESCOPE_HDR_SUPPORTED=1` not required for this success)*
- [x] Do not set `ENABLE_HDR_WSI` on the child. *(absent; Gamescope WSI alone handled HDR10)*
- [ ] Add Steam Big Picture, overlay stress, input, and multiple Xwayland servers one at a time if a failure reappears. The first addition that reintroduces the error owns the next investigation.

If native Vulkan works but Proton fails, compare the Vulkan loader logs and surface API used by each process before considering a Gamescope patch.

**Gate:** one Proton title creates and presents a Gamescope-owned swapchain with no hook warning. **Met 2026-07-14** for AC6 (desktop Steam → gamescope → Proton). Steam-inside-Gamescope still unchecked.

## Phase 5: restore HDR and portal capture

- [x] Enable the existing Gamescope HDR flags without changing PipeWire color patches. *(`--hdr-enabled` only on nested desktop run)*
- [x] Require `server hdr output enabled: true` and `hdr formats exposed to client: true` for the game surface. *(both true on AC6 surface)*
- [x] Confirm the HDR swapchain uses an HDR-capable format/colorspace when the title enables HDR. *(`A2B10G10R10` + `HDR10_ST2084`; `VkHdrMetadataEXT` logged; user color OK)*
- [ ] Restore the Gamescope portal and verify the stream independently: 10-bit capture, P010 encode, Rec.2020 + PQ tags, and `convert_path=vulkan_cuda`.
- [ ] Visually compare nested WSI with the known-good attach run on the same scene and **portal client** (not only local KWin).

**Gate:** nested WSI presents HDR correctly **and** the portal stream remains stable and correctly colored. Local HDR presentation is green; portal half still open.

## Phase 6: simplify session wiring

Implementation belongs primarily in `luxusAi/modules/nixos/polaris-hdr-session.nix`; this repository owns the Gamescope package and any proven source patch.

- [ ] Preserve the existing attach branch unchanged and WSI-free.
- [ ] Keep nested mode opt-in until all gates pass.
- [ ] Let Gamescope launch Steam as its primary child and supply `DISPLAY`, `GAMESCOPE_WAYLAND_DISPLAY`, and `ENABLE_GAMESCOPE_WSI` naturally.
- [ ] Remove manually supplied variables and `--expose-wayland` if the earlier matrix proves they are unnecessary.
- [ ] Add only a small readiness check based on the Gamescope socket/process; do not parse success from log prose.
- [ ] Keep lifecycle cleanup scoped to the nested instance. Do not broaden process matching as part of the WSI fix.

**Gate:** start, stop, nested-to-attach fallback, Big Picture, and direct app launch work repeatedly without stale `gamescope-0` sockets or orphaned Steam processes.

## Ship-or-remove decision

Ship nested WSI only when all of these pass:

- [ ] Attach HDR and SDR behavior is unchanged when the opt-in is unset.
- [ ] Native Vulkan and the selected Proton title both hook surface, swapchain, and present successfully.
- [ ] HDR exposure and HDR swapchain selection are visible in logs.
- [ ] Portal capture remains on the proven DmaBuf/Vulkan-CUDA path with good color.
- [ ] No success depends on disabling a required Steam feature or suppressing a WSI error.

Otherwise:

1. If pinned 3.16.24 fails but a newer Gamescope succeeds, update the package or backport the smallest identified upstream fix.
2. If a clean minimal reproducer fails upstream too, file or update an upstream issue with loader diagnostics and the first missing WSI event; keep attach as the default.
3. If no reliable fix exists, remove `POLARIS_GAMESCOPE_WSI` and the nested branch, keep `enableWsi = true` only if another supported consumer needs the layer, and document nested WSI as unsupported.

## Expected deliverables

- Reproduction logs and a completed test matrix attached to issue #6.
- A minimal session-wiring change in `luxusAi`, or deletion of the experimental knob.
- A Gamescope patch in this repository only if the minimal reproducer proves a specific source defect.
- Updated `STATUS.md`, `gamescope/README.md`, and issue #6 with the final supported topology.

## References

- [ValveSoftware/gamescope#1404](https://github.com/ValveSoftware/gamescope/issues/1404) — manual attach lacks the child environment Gamescope normally supplies
- [ValveSoftware/gamescope#1225](https://github.com/ValveSoftware/gamescope/issues/1225) — WSI, HDR, Steam overlay, and input interactions
- [ValveSoftware/gamescope#1346](https://github.com/ValveSoftware/gamescope/issues/1346) — non-Gamescope swapchains and interfering layers
- [VK_hdr_layer: testing with Gamescope](https://github.com/swick/VK_hdr_layer#testing-with-gamescope) — enable the outer HDR layer but disable it for Gamescope children
- [`docs/polaris-hdr-color.md`](./polaris-hdr-color.md) — why WSI is not a portal color fix
