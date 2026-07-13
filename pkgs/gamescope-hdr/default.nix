# gamescope with IceDOS/Jovian-oriented HDR PipeWire metadata patches
# (https://github.com/papi-ux/polaris/issues/152). Opt-in for HDR headless sessions.
# enableWsi: build VkLayer_FROG_gamescope_wsi (ENABLE_GAMESCOPE_WSI / ENABLE_HDR_WSI).
#
# Color experiment (2026-07-13): do NOT force PQ paint / ColorMgmt LUTs on the
# PipeWire path. Stock paint_pipewire uses screenshot LUTs + EOTF_Gamma22.
# IceDOS had the opposite (PQ + LUTs) for Sunshine; with Polaris, game-HDR wash
# looked worse — try letting gamescope's default capture color path stand.
{ gamescope }:

(gamescope.override { enableWsi = true; }).overrideAttrs (old: {
  pname = "gamescope-hdr";

  patches = (old.patches or [ ]) ++ [
    ../../gamescope/pipewire-hdr-metadata.patch
    ../../gamescope/headless-hdr-colorimetry.patch
    # Prefer SPA_DATA_DmaBuf when the consumer allows it (GameStream zero-copy).
    ../../gamescope/pipewire-prefer-dmabuf.patch
  ];

  meta = old.meta // {
    description = "${
      old.meta.description or "gamescope"
    } (HDR PW metadata + WSI; stock paint_pipewire color)";
  };
})
