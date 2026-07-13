# Upstream: `perf/issue-152-pipewire-capture`

**Source:** [papi-ux/polaris](https://github.com/papi-ux/polaris) branch `perf/issue-152-pipewire-capture`  
**Tip (frozen for this archive):** `c2bb9cb475bb5aec3b8c12d1b5fb2d85baa565c3`  
**Base:** `38159f31b0c4cea2e3373e373bf4aaf6aa38e043` (v1.3.0 prep — same pin luxusAi used before this test)

## What this is

Maintainer SDR-first PipeWire / portal DMA-BUF capture (same-GPU check, honest SHM fallback, residency logging). **Not** our experimental gist patches.

## Files

| Path | Use |
|------|-----|
| `combined.patch` | Single `git apply` / Nix `patches` entry on **base** above |
| `0001`…`0006-*.patch` | Same series as `git format-patch` (apply in order) |

Verified: `git apply --check combined.patch` on a clean tree at **base**.

## Prefer pinning the rev for tests

Laziest correct option for packaging:

```nix
src = fetchFromGitHub {
  owner = "papi-ux";
  repo = "polaris";
  rev = "c2bb9cb475bb5aec3b8c12d1b5fb2d85baa565c3";
  hash = "..."; # recompute with fetchSubmodules = true
  fetchSubmodules = true;
};
patches = [ ]; # do NOT stack polaris/experimental/*
```

Use the patch only if you must stay on the v1.3.0 base rev and cannot change `rev`.

## Test matrix (papi-ux on #152)

1. **Keep** gamescope `gamescope/pipewire-prefer-dmabuf.patch` (producer must offer DmaBuf).
2. **Drop** `polaris/experimental/*` (gist CUDA/EGL/portal patches).
3. Run this branch tip (or `combined.patch` on base).
4. Focus window active in gamescope (idle alone → zero frames).
5. Capture log lines: `render_node`, format/modifier, `capture_transport`, `frame_residency`.

See repo root `TEST-issue-152.md`.
