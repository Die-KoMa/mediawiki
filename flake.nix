{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
    composer2nix = {
      url = "github:svanderburg/composer2nix";
      flake = false;
    };
    mediawiki-extdist = {
      url = "github:Die-KoMa/mediawiki-extdist";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          inputs.mediawiki-extdist.overlays.default
        ];
      };
      composer2nix = import inputs.composer2nix {
        inherit pkgs system;
        noDev = true;
      };

      packages = import ./packages {
        inherit pkgs system composer2nix;
        lib = pkgs.lib;
      };
    in
    {
      nixosModules.komapedia = import ./modules/komapedia.nix (self.packages."${system}");

      apps."${system}".update-extensions = {
        type = "app";
        program =
          let
            updateScript = pkgs.writeShellApplication {
              name = "komapedia-update-extensions";
              meta = {
                license = pkgs.lib.licenses.publicDomain;
                mainProgram = "komapedia-update-extensions";
              };

              text = ''
                pushd packages
                TMPDIR=$(mktemp --directory)
                COMPOSER_HOME="$TMPDIR"
                export COMPOSER_HOME

                cp "${./packages/composer.json}" "$TMPDIR"/config.json

                mediawiki-extdist \
                  --mw-version ${packages._meta.branch} --output "$TMPDIR" \
                  --extension Description2 \
                  --extension EditSubpages \
                  --extension Interwiki \
                  --extension NativeSvgHandler \
                  --extension OpenGraphMeta \
                  --extension UserMerge \
                  --extension Variables \
                  --extension PageForms

                cp "$TMPDIR"/*.tar.gz .
                git add ./*-${packages._meta.branch}.tar.gz

                pushd SemanticMediaWiki
                rm -f composer.lock
                composer2nix -p mediawiki/semantic-media-wiki
                jq -s '.[0] * .[1]' composer.json ../composer.json > "$TMPDIR"/composer-merged.json
                cp "$TMPDIR"/composer-merged.json composer.json
                popd
                git add SemanticMediaWiki
              '';

              runtimeInputs = [
                pkgs.mediawiki-extdist
                pkgs.git
                pkgs.jq
                composer2nix
              ];
            };
          in
          pkgs.lib.getExe updateScript;
      };

      packages."${system}" = pkgs.lib.filterAttrs (name: _: !pkgs.lib.hasPrefix "_" name) packages;

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
