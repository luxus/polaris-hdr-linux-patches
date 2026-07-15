# polaris-hdr-linux-patches

Downstream patch stacks for pinned **Polaris**, **Gamescope**, and
`xdg-desktop-portal-gamescope` (HDR GameStream / portal capture research for
[polaris#152](https://github.com/papi-ux/polaris/issues/152)).

Exports packages + overlay. Consumer hosts (e.g. luxusAi) own session scripts,
services, and runtime force files. **`archived/` is never applied.**

## Flake outputs

| Output | What |
|--------|------|
| `packages.<sys>.polaris-stream` | Polaris + `01`–`04`,`06`,`07` always; `05` Vulkan→CUDA default on |
| `packages.<sys>.gamescope-hdr` | gamescope + HDR PW + prefer-dmabuf + Color **A+B** + **WSI built** |
| `packages.<sys>.xdg-desktop-portal-gamescope` | Jovian portal + stream-size fix |
| `packages.<sys>.polaris-nvidia-pin` | Hybrid-GPU pin shell snippet |
| `overlays.default` | All of the above on `pkgs` |

```nix
inputs.polaris-hdr-linux-patches = {
  url = "github:luxus/polaris-hdr-linux-patches";
  inputs.nixpkgs.follows = "nixpkgs";
};
nixpkgs.overlays = [ inputs.polaris-hdr-linux-patches.overlays.default ];
```

```bash
nix build .#polaris-stream
nix build .#gamescope-hdr
nix build .#xdg-desktop-portal-gamescope
```

## Layout

```
flake.nix / pkgs/          wired packages (source of truth for what applies)
polaris/                   01–07 topic patches
gamescope/                 01–04 + Color B via postPatch in package
xdg-desktop-portal-gamescope/
lib/                       polaris-nvidia-pin.sh
docs/                      research notes (history when they conflict with pkgs)
archived/                  old series + failed experiments — never applied
STATUS.md                  current verified state
```

## Active stack (summary)

| Area | What ships |
|------|------------|
| Polaris portal | PipeWire DmaBuf same-GPU capture → Vulkan buffer copy → CUDA/NVENC (`vulkan_cuda`) |
| HDR | 10-bit `xBGR_210LE` + P010 + Rec.2020/PQ metadata; force file from `enable_hdr` only |
| SDR | Independent 8-bit/NV12 path; device_db capability does not force HDR (`07`) |
| Gamescope | PW HDR meta, headless colorimetry, prefer DmaBuf, ColorMgmt LUTs + PQ paint when HDR |
| WSI | Layer **always built** (`enableWsi = true`). Nested presentation when session opts in; do not spray `ENABLE_*_WSI` on plain attach for “better capture” |

Full topic tables: [polaris/README.md](polaris/README.md), [gamescope/README.md](gamescope/README.md).
Living status / lea evidence: [STATUS.md](STATUS.md).

## Host shape (lea)

- `capture = portal`, pin NVIDIA for capture+CUDA+NVENC (`lib/polaris-nvidia-pin.sh`)
- Hybrid systems: same GPU end-to-end; do not blacklist AMD as the fix
- Session / deploy: consumer flake (luxusAi); this repo is the GitHub input tip

## License

Patches: same as upstream (Polaris GPL-3, gamescope BSD/MIT mix). Packaging: MIT.
