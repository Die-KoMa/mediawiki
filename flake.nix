{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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
          inputs.mediawiki-extdist.overlays.poetry2nix
        ];
      };
      composer2nix = import inputs.composer2nix {
        inherit pkgs system;
        noDev = true;
      };
    in
    {
      nixosModules.komapedia = import ./modules/komapedia.nix (self.packages."${system}");

      apps."${system}".update-extensions = {
        type = "app";
        program =
          let
            updateScript = pkgs.writeShellScript "komapedia-update-extensions" ''
              pushd packages
              TMPDIR=$(mktemp --directory)
              ${pkgs.mediawiki-extdist}/bin/mediawiki-extdist \
                --mw-version REL1_43 --output $TMPDIR \
                --extension Description2 \
                --extension EditSubpages \
                --extension Interwiki \
                --extension NativeSvgHandler \
                --extension OpenGraphMeta \
                --extension UserMerge \
                --extension Variables
              cp $TMPDIR/*.tar.gz .
              git add *.tar.gz

              pushd PageForms
              rm composer.lock
              composer2nix -p mediawiki/page-forms
              popd
              git add PageForms

              pushd SemanticMediaWiki
              rm composer.lock
              composer2nix -p mediawiki/semantic-media-wiki
              popd
              git add SemanticMediaWiki

              pushd SemanticResultFormats
              rm composer.lock
              composer2nix -p mediawiki/semantic-result-formats
              popd
              git add SemanticResultFormats

              popd
            '';
          in
          "${updateScript}";
      };

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
