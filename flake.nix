{
  description = "Polaris + gamescope packages and patches for Linux HDR GameStream (polaris#152)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      overlays.default = final: prev: {
        gamescope-hdr = final.callPackage ./pkgs/gamescope-hdr { };
        xdg-desktop-portal-gamescope = final.callPackage ./pkgs/xdg-desktop-portal-gamescope { };
        # Full stack (all phases + optional private bus).
        polaris-stream = final.callPackage ./pkgs/polaris-stream { };
        # Step packages: disable later phases when testing / after upstream lands a phase.
        polaris-stream-phase1 = final.callPackage ./pkgs/polaris-stream {
          enablePhase1Portal = true;
          enablePhase2VulkanCuda = false;
          enablePhase4Hdr = false;
          enablePortalPrivateBus = false;
        };
        polaris-stream-phase1-2 = final.callPackage ./pkgs/polaris-stream {
          enablePhase1Portal = true;
          enablePhase2VulkanCuda = true;
          enablePhase4Hdr = false;
          enablePortalPrivateBus = false;
        };
        polaris-stream-phase1-2-4 = final.callPackage ./pkgs/polaris-stream {
          enablePhase1Portal = true;
          enablePhase2VulkanCuda = true;
          enablePhase4Hdr = true;
          enablePortalPrivateBus = false;
        };
        # Shell helper: source ${pkgs.polaris-nvidia-pin}/share/polaris/polaris-nvidia-pin.sh
        polaris-nvidia-pin = final.runCommand "polaris-nvidia-pin" { } ''
          mkdir -p $out/share/polaris
          cp ${./lib/polaris-nvidia-pin.sh} $out/share/polaris/polaris-nvidia-pin.sh
        '';
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs)
            gamescope-hdr
            xdg-desktop-portal-gamescope
            polaris-stream
            polaris-stream-phase1
            polaris-stream-phase1-2
            polaris-stream-phase1-2-4
            polaris-nvidia-pin
            ;
          default = pkgs.polaris-stream;
        }
      );

      # Overlay only — consumers own polaris.service / session units.
      nixosModules.default = {
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}
