{
  inputs =
    {
      nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;
    };

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      composer = pkgs.phpPackages.composer;
      upgrade = pkgs.writeScript "mw-upgrade" ''
        if [[ $# -ne 1 ]]; then
          echo "usage: $0 <RELEASE_BRANCH>"
          exit 1
        fi
        ${pkgs.curl}/bin/curl https://raw.githubusercontent.com/wikimedia/mediawiki/$1/composer.json > composer.json
        ${pkgs.git}/bin/git add composer.json
      '';
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
        upgrade = { type = "app"; program = "${upgrade}"; };
        update = { type = "app"; program = "${update}"; };
        nixify = { type = "app"; program = "${nixify}"; };
        composer = { type = "app"; program = "${composer}/bin/composer"; };
      };
      defaultApp.x86_64-linux = self.apps.x86_64-linux.nixify;
      devShell.x86_64-linux =
        pkgs.mkShell {
          nativeBuildInputs = [ composer ];
        };

    };
}
