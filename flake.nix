{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    legacy-packages.url = "github:NixOS/nixpkgs/nixos-20.03";
  };

  outputs = {
    self,
    nixpkgs,
    legacy-packages,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    legacyPkgs = import legacy-packages {inherit system;};

    packages = import ./packages {inherit pkgs legacyPkgs;};

    eachSystem = let
      inherit (pkgs.lib) listToAttrs nameValuePair;
      inherit (builtins) map;
    in
      systems: attrs: listToAttrs (map (system: nameValuePair system attrs) systems);
  in {
    overlays.default = final: prev: packages;

    nixosModules = import ./modules packages;

    packages = eachSystem [system] packages;

    devShells = eachSystem [system] {
      default = pkgs.mkShell {
        nativeBuildInputs = [
          packages.composer1
          packages.composer2
        ];
      };
    };

    formatter = eachSystem [system] pkgs.alejandra;
  };
}
