# gamescope HDR capture stack (polaris#152).
# enableWsi=true always: layer built; attach-only has been flaky — keep nested path available.
# Color A+B: 04 ColorMgmt LUTs + postPatch EOTF_PQ when HDR.
#
# Tracks ValveSoftware/gamescope master (not only the nixpkgs tag) for compositor
# fixes. Re-check patches + meson flags after each bump.
{
  gamescope,
  fetchFromGitHub,
  lib,
}:

let
  # Master tip 2026-07-27.
  gamescopeRev = "8c676c399c761e4540587f61004c957993d12fea";

  # Master switched glm/stb from system headers to meson wrap-git subprojects.
  # Vendoring keeps wrap_mode=nodownload happy in the nix sandbox.
  glmSrc = fetchFromGitHub {
    owner = "g-truc";
    repo = "glm";
    rev = "0af55ccecd98d4e5a8d1fad7de25ba429d60e863";
    hash = "sha256-GnGyzNRpzuguc3yYbEFtYLvG+KiCtRAktiN+NvbOICE=";
  };
  stbSrc = fetchFromGitHub {
    owner = "nothings";
    repo = "stb";
    rev = "5736b15f7ea0ffb08dd38af21067c314d6a3aae9";
    hash = "sha256-s2ASdlT3bBNrqvwfhhN6skjbmyEnUgvNOrvhgUSRj98=";
  };
in
(gamescope.override { enableWsi = true; }).overrideAttrs (old: {
  pname = "gamescope-hdr";
  version = "0-unstable-2026-07-27";

  src = fetchFromGitHub {
    owner = "ValveSoftware";
    repo = "gamescope";
    rev = gamescopeRev;
    fetchSubmodules = true;
    hash = "sha256-l8jHeCGbm8yiw4GuOterWc53Lnv7bjK7Y9qPlzj7Ojk=";
  };

  # Keep only nixpkgs packaging patches that still apply on master.
  # The two pending upstream fetchpatches on 3.16.24 are already in master.
  patches =
    (builtins.filter (
      p:
      let
        s = toString p;
      in
      lib.hasInfix "shaders-path" s || lib.hasInfix "gamescopereaper" s
    ) (old.patches or [ ]))
    ++ [
      ../../gamescope/01-pipewire-hdr-metadata.patch
      ../../gamescope/02-headless-hdr-colorimetry.patch
      # Prefer SPA_DATA_DmaBuf when the consumer allows it (GameStream zero-copy).
      ../../gamescope/03-pipewire-prefer-dmabuf.patch
      # A: IceDOS color-mgmt LUTs on PipeWire path.
      ../../gamescope/04-pipewire-color-mgmt.patch
    ];

  # Master dropped glm_include_dir / stb_include_dir meson options.
  mesonFlags = [
    (lib.mesonBool "enable_gamescope" true)
    (lib.mesonBool "enable_gamescope_wsi_layer" true)
    (lib.mesonBool "enable_tests" false)
  ];

  # B: IceDOS postPatch — encode PW capture as PQ when HDR output is on.
  # Pin SDR-on-HDR defaults to session-matching values (CLI can still override).
  # sdrGamutWideness=0, sdrContentNits=203 (BT.2408 reference white).
  # Also materialize glm/stb wrap-git deps from nix store.
  postPatch =
    (old.postPatch or "")
    + ''
      rm -rf subprojects/glm subprojects/stb
      cp -a ${glmSrc} subprojects/glm
      cp -a ${stbSrc} subprojects/stb
      chmod -R u+w subprojects/glm subprojects/stb
      # wrap patch_directory meson files (from gamescope packagefiles/)
      cp -f subprojects/packagefiles/glm/meson.build subprojects/glm/meson.build
      cp -f subprojects/packagefiles/stb/meson.build subprojects/stb/meson.build

      substituteInPlace src/steamcompmgr.cpp \
        --replace-fail 'frameInfo.outputEncodingEOTF   = EOTF_Gamma22;' \
                       'frameInfo.outputEncodingEOTF   = g_bOutputHDREnabled ? EOTF_PQ : EOTF_Gamma22;' \
        --replace-fail '.displayColorimetry = displaycolorimetry_2020,' \
                       '.sdrGamutWideness = 0, .flSDROnHDRBrightness = 203, .displayColorimetry = displaycolorimetry_2020,'
    '';

  meta = old.meta // {
    description = "${
      old.meta.description or "gamescope"
    } (HDR PW metadata + WSI; ColorMgmt LUTs + EOTF_PQ paint_pipewire; master ${
      lib.substring 0 7 gamescopeRev
    })";
  };
})
