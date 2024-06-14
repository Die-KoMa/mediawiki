{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    composer2nix = {
      url = "github:svanderburg/composer2nix";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      composer2nix = import inputs.composer2nix {
        inherit pkgs system;
        noDev = true;
      };
    in
    {
      nixosModules.komapedia = import ./modules/komapedia.nix (self.packages."${system}");

      packages."${system}" = import ./packages {
        inherit pkgs system composer2nix;
        lib = pkgs.lib;
      };

      devShells."${system}".default = pkgs.mkShell {
        nativeBuildInputs = [
          composer2nix
          pkgs.php
          pkgs.phpPackages.composer
        ];
      };

      # build everything as part of nix flake check
      checks = self.packages;

      formatter."${system}" = pkgs.treefmt;
    };
}
