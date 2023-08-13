{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};

    packages = import ./packages {inherit pkgs;};

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
          packages.composer
        ];
      };
    };

    formatter = eachSystem [system] pkgs.alejandra;
  };
}
