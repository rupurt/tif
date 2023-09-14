{
  description = "Nix flake for tif. Lightning fast tabular diffs, patches and merges for large datasets.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    zig-overlay,
    ...
  }: let
    systems = builtins.attrNames zig-overlay.packages;
    outputs = flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          zig-overlay.overlays.default
          self.overlays
        ];
      };
    in rec {
      # packages exported by the flake
      packages = {
        tif-small = pkgs.tif-small {release = "Small";};
        tif-fast = pkgs.tif-fast {release = "Fast";};
        tif-debug = pkgs.tif-debug {release = "Debug";};
        default = packages.tif-small {};
      };

      # nix run
      apps = {};

      # nix fmt
      formatter = pkgs.alejandra;

      # nix develop -c $SHELL
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.bats
          pkgs.b3sum
          pkgs.gprof2dot
          pkgs.valgrind
          pkgs.zigpkgs.master
          pkgs.zls
        ];
      };
    });
  in
    outputs
    // {
      # Overlay that can be imported so you can access the packages
      # using tif.overlays
      overlays = final: prev: {
        tif-small = prev.pkgs.callPackage ./tif.nix {release = "Small";};
        tif-fast = prev.pkgs.callPackage ./tif.nix {release = "Fast";};
        tif-debug = prev.pkgs.callPackage ./tif.nix {release = "Debug";};
      };
    };
}
