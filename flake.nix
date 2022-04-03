{
  inputs =
    {
      nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;
    };

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      composer = pkgs.phpPackages.composer;
      update = pkgs.writeScript "composer-update" ''
        ${composer}/bin/composer update --no-dev
      '';
      nixify = pkgs.writeScript "composer-nixify" ''
        ${composer}/bin/composer nixify
      '';
    in
    {
      overlay = final: prev: {
        komapedia-mediawiki = final.pkgs.callPackage ./composer-project.nix { };
      };

      apps.x86_64-linux = {
        update = { type = "app"; program = "${update}"; };
        nixify = { type = "app"; program = "${nixify}"; };
      };
      defaultApp.x86_64-linux = self.apps.x86_64-linux.nixify;
      devShell.x86_64-linux =
        pkgs.mkShell {
          nativeBuildInputs = [ composer ];
        };

    };
}
