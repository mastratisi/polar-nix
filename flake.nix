{
  description = "Nix package for Polar's polar CLI, tracking the npm release feed";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = { self, nixpkgs, systems }:
    let
      inherit (nixpkgs) lib;
      eachSystem = f: lib.genAttrs (import systems) f;
      overlay = final: prev: {
        polar-cli = final.callPackage ./package.nix { };
      };
      pkgsFor = system: import nixpkgs { inherit system; overlays = [ overlay ]; };
    in
    {
      overlays.default = overlay;

      packages = eachSystem (system: rec {
        polar-cli = (pkgsFor system).polar-cli;
        default = polar-cli;
      });

      apps = eachSystem (system: rec {
        polar = {
          type = "app";
          program = "${(pkgsFor system).polar-cli}/bin/polar";
        };
        default = polar;
      });

      devShells = eachSystem (system: {
        default = (pkgsFor system).mkShell {
          packages = with (pkgsFor system); [ nixpkgs-fmt jq curl ];
        };
      });
    };
}
