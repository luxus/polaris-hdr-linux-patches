# polaris-hdr-linux-patches

Public patch archive for **Linux GameStream / HDR research** around [polaris#152](https://github.com/papi-ux/polaris/issues/152).

Host flake / domain names stay private ([luxusAi](https://github.com/luxus/luxusAi) is private). **Patches and test notes live here** so upstream and others can reuse them without that tree.

## Layout

```
gamescope/                 Valve gamescope patches (keep for tests)
  pipewire-prefer-dmabuf.patch   ← required for #152 DMA-BUF producer
  pipewire-hdr-metadata.patch
  pipewire-color-mgmt.patch
  headless-hdr-colorimetry.patch

polaris/
  upstream/issue-152-pipewire-capture/   ← papi-ux branch as patches (test this)
  experimental/                          ← our gist spike (ON HOLD; do not stack for #152 test)

docs/                      Color / DMA-BUF / fake-display notes
TEST-issue-152.md          Exact maintainer test matrix
STATUS.md                  Freeze / on-hold log
```

## Test #152 (current priority)

Maintainer branch: `perf/issue-152-pipewire-capture`  
Tip archived as: `c2bb9cb475bb5aec3b8c12d1b5fb2d85baa565c3`  
Base: `38159f31b0c4cea2e3373e373bf4aaf6aa38e043`

**Rules from papi-ux:**

1. Keep gamescope **`pipewire-prefer-dmabuf`**.
2. **Do not** apply `polaris/experimental/*`.
3. Run the upstream tip (or `combined.patch` on base).
4. Focus window active; log `render_node`, format/modifier, `capture_transport`, `frame_residency`.

Details: [TEST-issue-152.md](TEST-issue-152.md) · patch notes: [polaris/upstream/…](polaris/upstream/issue-152-pipewire-capture/README.md)

### Nix (recommended)

```nix
# polaris — pin tip, no experimental patches
src = fetchFromGitHub {
  owner = "papi-ux";
  repo = "polaris";
  rev = "c2bb9cb475bb5aec3b8c12d1b5fb2d85baa565c3";
  hash = "sha256-YwcK2SR6Nx38a60Nxf73fKLzM6z/rBr2K8LKzykBiVM=";
  fetchSubmodules = true;
};
patches = [ ];

# gamescope — producer fix only (or full HDR set)
patches = [ ./gamescope/pipewire-prefer-dmabuf.patch ];
```

Or stay on base rev and apply `polaris/upstream/issue-152-pipewire-capture/combined.patch`.

## Experimental (on hold)

`polaris/experimental/` — portal DmaBuf prefer + EGL TexStorageEXT + CUDA/GL path from the 4090 spike. Useful inspiration; **not** for the #152 validation run. See [STATUS.md](STATUS.md) and [docs/](docs/).

## What still lives only in the private host flake

- Full `polaris-stream` / `gamescope-hdr` / portal Nix packages and module wiring
- Machine hostname, secrets, dual-GPU pin helpers, labwc default session
- Force-EDID / JetKVM experiments

**Possible next step:** move pure packages + a tiny flake here so `luxusAi` only consumes `inputs.polaris-hdr-linux-patches` (no domain leakage). Host modules stay private.

## Proven on lea (experimental path, freeze)

| Item | Result |
|------|--------|
| Capture | DmaBuf, 10-bit `XB30` / `xBGR_210LE` (with experimental + gamescope set) |
| Import | EGL TexStorageEXT OK; CUDA extmem failed on gamescope dmabufs |
| Dual-GPU | Pin NVIDIA `renderD*` |
| Encode | HEVC NVENC HDR P010; ~8–9 ms at 4K (encode-bound) |

## License

Patches modify GPL (Polaris) and BSD/MIT-mix (gamescope) trees — same terms as upstream when redistributing.
