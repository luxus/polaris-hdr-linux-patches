# polaris-hdr-linux-patches

Working flake for Linux GameStream / HDR research around
[polaris#152](https://github.com/papi-ux/polaris/issues/152).

Exports packages + overlay. **Archived** (unused) patches live under `archived/`
and are not applied.

## Flake outputs

| Output | What |
|--------|------|
| `packages.<sys>.polaris-stream` | Polaris **master** + topic patches (`polaris/01`–`03`) |
| `packages.<sys>.gamescope-hdr` | gamescope + HDR PW + prefer-dmabuf + WSI **built** |
| `packages.<sys>.xdg-desktop-portal-gamescope` | Jovian portal + stream-size fix |
| `packages.<sys>.polaris-nvidia-pin` | Hybrid-GPU pin shell snippet |
| `overlays.default` | All of the above on `pkgs` |

```nix
inputs.polaris-hdr-linux-patches = {
  url = "github:luxus/polaris-hdr-linux-patches";
  inputs.nixpkgs.follows = "nixpkgs";
};
# nixos
nixpkgs.overlays = [ inputs.polaris-hdr-linux-patches.overlays.default ];
```

```bash
nix build .#polaris-stream
nix build .#gamescope-hdr
```

## Layout

```
flake.nix
pkgs/                          Nix packages (wired)
polaris/                       Topic patches applied by polaris-stream
  01-portal-pipewire-dmabuf.patch
  02-portal-hdr-metadata.patch
  03-web-ui-session-persist.patch
gamescope/                     Topic patches applied by gamescope-hdr
  01-pipewire-hdr-metadata.patch
  02-headless-hdr-colorimetry.patch
  03-pipewire-prefer-dmabuf.patch
xdg-desktop-portal-gamescope/  Portal package patches
archived/                      Old numbered series + failed experiments
lib/ docs/ STATUS.md
```

## Patch review (active stack)

### Polaris (`polaris/`)

| # | Topic | Status on lea |
|---|--------|----------------|
| 01 | Portal PipeWire capture + same-GPU DmaBuf + CUDA path + prefer xBGR_210LE | **Working** — dmabuf + p010 encode |
| 02 | Portal HDR metadata + force-file gate | **Working** — client HDR → stream_hdr |
| 03 | Web UI session persist | **Working** — survives polaris restart |

### gamescope (`gamescope/`)

| # | Topic | Status |
|---|--------|--------|
| 01 | PipeWire HDR metadata | **Working** |
| 02 | Headless HDR colorimetry | **Working** (with host force flags) |
| 03 | Prefer DmaBuf | **Working** with polaris 01 |

### Portal

| # | Topic | Status |
|---|--------|--------|
| 01 | Fix stream size | **Working** |

### Intentionally not applied

- Polaris GL DmaBuf import (old 0009) — black video on NVIDIA  
- Gist experimental DmaBuf stack — superseded by polaris 01  
- gamescope forced PQ ColorMgmt paint — wash regression  

See [archived/README.md](archived/README.md), [STATUS.md](STATUS.md), GitHub issues #1–#4.

## Known-good host shape (lea)

- `capture = portal`, NVIDIA `adapter_name`, gamescope portal ScreenCast  
- No `ENABLE_*_WSI` in session env  
- Client profiles / Bigscreen apps for HDR vs forced SDR  
- Open product work: [Gamescope Stream mode](https://github.com/luxus/polaris-hdr-linux-patches/issues/4) (UI label), color parity (#1)

## License

Patches: same as upstream (Polaris GPL-3, gamescope BSD/MIT mix). Packaging: MIT.
