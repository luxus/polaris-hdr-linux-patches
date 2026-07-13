# polaris-hdr-linux-patches

**Working flake** for Linux GameStream / HDR research around [polaris#152](https://github.com/papi-ux/polaris/issues/152).

Exports packages + overlay. Experimental gist patches stay under `polaris/experimental/` as archive (not applied).

## Flake outputs

| Output | What |
|--------|------|
| `packages.<sys>.polaris-stream` | Polaris on **master** + rebased #152 portal/DMA-BUF patch |
| `packages.<sys>.gamescope-hdr` | gamescope + IceDOS/HDR PW patches + prefer-dmabuf + WSI layer |
| `packages.<sys>.xdg-desktop-portal-gamescope` | Jovian portal + stream-size patch |
| `packages.<sys>.polaris-nvidia-pin` | hybrid-GPU pin shell snippet |
| `overlays.default` | all of the above on `pkgs` |

```nix
# consumer flake.nix
inputs.polaris-hdr-linux-patches = {
  url = "github:luxus/polaris-hdr-linux-patches";
  inputs.nixpkgs.follows = "nixpkgs";
};

# nixos
nixpkgs.overlays = [ inputs.polaris-hdr-linux-patches.overlays.default ];
# then: pkgs.polaris-stream, pkgs.gamescope-hdr, pkgs.xdg-desktop-portal-gamescope
```

```bash
nix build github:luxus/polaris-hdr-linux-patches#gamescope-hdr
nix build github:luxus/polaris-hdr-linux-patches#polaris-stream
```

## Layout

```
flake.nix
pkgs/                 Nix packages (wired)
gamescope/            gamescope patches (applied by gamescope-hdr)
xdg-desktop-portal-gamescope/   portal patches
polaris/
  upstream/issue-152-pipewire-capture/   applied by polaris-stream
  experimental/                          archive only (not applied)
lib/polaris-nvidia-pin.sh
docs/ TEST-issue-152.md STATUS.md
```

## #152 test matrix

1. `gamescope-hdr` (includes `pipewire-prefer-dmabuf`)
2. `polaris-stream` (master + upstream combined patch — **no** experimental)
3. Focus window; log `render_node`, format/modifier, `capture_transport`, `frame_residency`

See [TEST-issue-152.md](TEST-issue-152.md).

## License

Patches: same as upstream (Polaris GPL-3, gamescope BSD/MIT mix). Packaging: MIT.
