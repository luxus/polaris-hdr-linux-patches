# gamescope with IceDOS/Jovian-oriented HDR PipeWire metadata patches
# (https://github.com/papi-ux/polaris/issues/152). Opt-in for HDR headless sessions.
# enableWsi: build VkLayer_FROG_gamescope_wsi (ENABLE_GAMESCOPE_WSI / ENABLE_HDR_WSI).
#
# Color experiment ladder (one step at a time):
#   A (04): paint_pipewire uses g_ColorMgmtLuts (this package)
#   B (later): postPatch outputEncodingEOTF=PQ when HDR + nits/gamut pin
# Stock was screenshot LUTs + EOTF_Gamma22.
{ gamescope }:

(gamescope.override { enableWsi = true; }).overrideAttrs (old: {
  pname = "gamescope-hdr";

  patches = (old.patches or [ ]) ++ [
    ../../gamescope/01-pipewire-hdr-metadata.patch
    ../../gamescope/02-headless-hdr-colorimetry.patch
    # Prefer SPA_DATA_DmaBuf when the consumer allows it (GameStream zero-copy).
    ../../gamescope/03-pipewire-prefer-dmabuf.patch
    # A: IceDOS color-mgmt LUTs on PipeWire path (not EOTF_PQ yet).
    ../../gamescope/04-pipewire-color-mgmt.patch
  ];

  meta = old.meta // {
    description = "${
      old.meta.description or "gamescope"
    } (HDR PW metadata + WSI; ColorMgmt LUTs on paint_pipewire)";
  };
})
