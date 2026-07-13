# polaris-hdr-linux-patches

Public patch archive for **Linux GameStream / HDR research** around [polaris#152](https://github.com/papi-ux/polaris/issues/152).

Host flake / domain names stay private. **Patches and test notes live here.**

## Layout

```
gamescope/                 Valve gamescope patches
  pipewire-prefer-dmabuf.patch   ← required for #152 DMA-BUF producer
  pipewire-hdr-metadata.patch
  pipewire-color-mgmt.patch
  headless-hdr-colorimetry.patch

xdg-desktop-portal-gamescope/
  fix-stream-size.patch          ← IceDOS stream size negotiation

polaris/
  upstream/issue-152-pipewire-capture/   ← #152 rebased onto master (test this)
  experimental/                          ← our gist spike (do not stack for #152)

docs/
TEST-issue-152.md
STATUS.md
```

## Test #152 (current)

**Prefer:** polaris **master** + `polaris/upstream/issue-152-pipewire-capture/combined.patch`  
(not the floating branch tip — branch was cut before v1.3.1; patch is rebased).

Base: `2008458634c0d3f04f8abc39fab862bc69a47af8`  
Hash: `sha256-e/nltRUAwZ/l6JtBti6uzumzY4zhiwQEA02oPat+7Jw=`

**Rules from papi-ux:**

1. Keep gamescope **`pipewire-prefer-dmabuf`**.
2. **Do not** apply `polaris/experimental/*`.
3. Focus window; log `render_node`, format/modifier, `capture_transport`, `frame_residency`.

Details: [TEST-issue-152.md](TEST-issue-152.md)

### Nix sketch

```nix
# polaris
src = fetchFromGitHub {
  owner = "papi-ux"; repo = "polaris";
  rev = "2008458634c0d3f04f8abc39fab862bc69a47af8";
  hash = "sha256-e/nltRUAwZ/l6JtBti6uzumzY4zhiwQEA02oPat+7Jw=";
  fetchSubmodules = true;
};
patches = [ ./polaris/upstream/issue-152-pipewire-capture/combined.patch ];

# gamescope
patches = [ ./gamescope/pipewire-prefer-dmabuf.patch /* + optional HDR set */ ];
```

## Experimental (on hold)

`polaris/experimental/` — portal DmaBuf prefer + EGL TexStorageEXT + CUDA/GL path. Reference only.

## What still lives only in private host flake

- Full Nix packages (`polaris-stream`, `gamescope-hdr`, portal) and session modules
- Hostnames, secrets, dual-GPU pin helpers, labwc default session

Patches here are the public source of truth; private packages may copy them.

## License

Same terms as upstream trees (Polaris GPL-3, gamescope BSD/MIT mix).
