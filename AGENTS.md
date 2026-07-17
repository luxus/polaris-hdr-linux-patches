# Repository Guidance

## Scope and sources of truth

- This repository packages downstream patch stacks for pinned Polaris, Gamescope, and `xdg-desktop-portal-gamescope` sources. It is not an upstream source checkout.
- Determine what ships from `pkgs/*/default.nix`; patch files are active only when those derivations reference them.
- Read `STATUS.md`, the root `README.md`, and the relevant component README before changing a stack. Treat dated plans in `docs/` as research history when they conflict with current package wiring or status.
- `archived/` is historical and is never applied. Do not restore an archived experiment without new measured evidence and an explicit reason.
- The flake exports packages, an overlay, and a minimal overlay module. Consumer repositories own Polaris services, Gamescope session wiring, host deployment, and runtime force files.

## Active patch boundaries

- Polaris patches are **phase-gated** (see `polaris/README.md`): phase1 portal/SHM, phase2 Vulkan→CUDA, phase4 HDR alignment, optional private ScreenCast bus. Defaults all on → same as full stack. Web UI session persist is upstream (no local web patch).
- Keep topics separate: phase1 PipeWire portal + SHM, phase2 LINEAR DmaBuf Vulkan→CUDA, phase4 HDR metadata/force/SDR/device_db, optional `POLARIS_PORTAL_DBUS_ADDRESS`. Phase 3 (Gamescope Stream ownership) is host/session wiring, not this package.
- Step packages: `polaris-stream-phase1`, `…-phase1-2`, `…-phase1-2-4`, full `polaris-stream`. When upstream lands a phase, disable that flag and rebase remaining patches.
- Gamescope applies `01` HDR PipeWire metadata, `02` headless HDR colorimetry, `03` prefer-DMA-BUF, plus Color **A+B** (ColorMgmt LUTs + `EOTF_PQ` when HDR) in `pkgs/gamescope-hdr`. The portal package applies only its stream-size patch.
- Patch formats in this repository are mixed. Preserve the surrounding format and avoid whole-file regeneration unless intentionally rebuilding a topic against its pinned upstream revision.
- When changing an upstream pin, update all coupled revision/version/hash fields and regenerate or rebase every affected active patch. A patch applying with fuzz is not sufficient verification.

## Proven runtime invariants

- Preserve the known-good default: XWayland attach to the idle Gamescope session, with `ENABLE_GAMESCOPE_WSI` and `ENABLE_HDR_WSI` absent from the Proton/session environment. Building Gamescope with `enableWsi = true` does not mean the layer should be enabled at runtime.
- Gamescope Color **A+B** is the current measured HDR path (A alone fixed reds; B = PQ paint when HDR). Do not strip A/B or reintroduce archived ColorMgmt experiments without a livingroom/Mac A/B.
- On hybrid systems, capture, Vulkan conversion, CUDA, and NVENC must select the same NVIDIA GPU. Use `lib/polaris-nvidia-pin.sh`; do not solve this by blacklisting the AMD GPU.
- Polaris `05` supports portal, LINEAR, one-plane BGRx/BGRA DMA-BUF input. Its fast path is Vulkan buffer copy to exportable opaque memory followed by persistent CUDA mapping. Do not change the existing KMS/Wayland GL-to-CUDA paths as part of portal work.
- Desktop NVIDIA `cuImport(DMABUF_FD)` and `cuGraphicsEGLRegisterImage` were dead ends. Do not reintroduce them as a generic desktop path; the latter is Tegra-oriented.
- Preserve honest diagnostics: CPU or mapped fallbacks must not report `gpu_native`; `mmap_cuda` must remain visible and distinguishable from `vulkan_cuda`.
- Keep HDR and SDR behavior independent. HDR should negotiate 10-bit `xBGR_210LE` capture and P010 encode; non-HDR streams should remain on the 8-bit/NV12 path.
- Do not alter the stable DMA-BUF, color, metadata, or encode stack while investigating optional nested WSI. Follow `docs/polaris-wsi-plan.md` and keep attach behavior unchanged.

## Validation

Run checks appropriate to the changed component:

```bash
git diff --check
nix flake check --no-build --no-write-lock-file
nix build --no-link .#polaris-stream
nix build --no-link .#gamescope-hdr
nix build --no-link .#xdg-desktop-portal-gamescope
```

- Build only the affected outputs, except when shared flake or overlay wiring changes.
- The ordinary flake package evaluates Polaris with `cudaSupport = false`; that does not compile the CUDA/Vulkan code in patch `05`. For changes to CUDA, Vulkan, DMA-BUF conversion, or related build inputs, also build the CUDA-enabled overlay result:

```bash
nix build --no-link --impure --expr 'let f = builtins.getFlake ("path:" + toString ./.); pkgs = import f.inputs.nixpkgs { system = builtins.currentSystem; config = { allowUnfree = true; cudaSupport = true; }; overlays = [ f.overlays.default ]; }; in pkgs.polaris-stream'
```

- A successful Nix build proves evaluation, patch application, and compilation only. Do not claim runtime success without host confirmation.
- For runtime capture claims, require logs showing `capture_transport`, format/modifier, frame residency, and `convert_path`. `vulkan_cuda` is the native portal fast path; `mmap_cuda` is a fallback.
- HDR runtime evidence should include 10-bit capture, P010 encode, HDR enabled, and Rec.2020/PQ tags. Verify an SDR client or forced-SDR app separately after HDR-path changes.
- Gamescope PipeWire capture emits frames only while a focused window has new commits; an idle session producing no frames is not by itself a capture failure.

## Host deploy on lea (always, when this stack changed)

**Default:** after any change that should run on lea (`pkgs/*`, active patches, gamescope Color path, or coupled luxusAi session wiring), **deploy — do not stop at build/check.** User preference: always switch unless they explicitly say repo-only / no switch.

**Long builds:** parent may launch async subagent `lea-build-deploy` (`~/.pi/agent/agents/lea-build-deploy.md`, interactive Herdr tab) for `nix build` / `nh os switch` / unit restart so the chat stays free. Give it a self-contained task (cwd, exact steps, push or not, verify). Do not re-do the same deploy in the parent while it runs.

Consumer flake is **luxusAi** (`NH_FLAKE` / `~/projects/luxusAi`). It consumes this repo as `github:luxus/polaris-hdr-linux-patches` (not a path input). Session scripts live in luxusAi (`modules/nixos/polaris-hdr-session.nix`).

```bash
# 1) this repo: stage/commit/push so GitHub input can see the tip
cd ~/projects/polaris-hdr-linux-patches
git add -A   # keep .pi/ / private junk out if needed
git commit -m '…'   # conventional: feat(polaris): / fix(gamescope): / docs:
git push origin HEAD

# 2) host flake: bump lock + switch
cd ~/projects/luxusAi
nix flake update polaris-hdr-linux-patches
# if session wiring changed in luxusAi, commit that too before switch
nh os switch

# 3) restart units that must pick up new binaries/scripts
systemctl --user daemon-reload
systemctl --user restart polaris.service polaris-hdr-idle.service
```

- Record deploy + short runtime check in `STATUS.md` (store path or generation, unit restart, one log line: `convert_path` / `portal HDR force` / Color coding).
- Repo-only validation (build/check without switch) only when the user says so or the machine is not lea.

## Documentation and change hygiene

- Keep `pkgs/*/default.nix`, root/component READMEs, and `STATUS.md` synchronized when patch names, defaults, wiring, or verified behavior change.
- Keep failed experiments in `archived/`; do not make the active package depend on archived paths.
- Preserve unrelated worktree changes. Use the repository's conventional commit style (`feat(polaris):`, `fix(gamescope):`, `docs:`) when a commit is requested.
