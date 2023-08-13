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

    eachSystem = let
      inherit (pkgs.lib) listToAttrs nameValuePair;
      inherit (builtins) map;
    in
      systems: attrs: listToAttrs (map (system: nameValuePair system attrs) systems);
  in {
    nixosModules.komapedia = import ./modules/komapedia.nix;

    formatter = eachSystem [system] pkgs.alejandra;
  };
}
