{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    legacy-packages.url = "github:NixOS/nixpkgs/nixos-20.03";
  };

  outputs = {
    self,
    nixpkgs,
    legacy-packages,
  }: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {inherit system;};
    composer1 = (import legacy-packages {inherit system;}).phpPackages.composer;
    composer2 = pkgs.phpPackages.composer;
    git = pkgs.git;

    upgradeScript = pkgs.writeShellScript "mw-upgrade" ''
      set -euo pipefail
      if [[ $# -ne 1 ]]; then
        echo "Upgrade mediawiki tree using the given upstream release branch"
        echo "usage: $0 <RELEASE_BRANCH>"
        exit 1
      fi

      COMPOSER=${composer2}
      for legacy in "REL1_28" "REL1_29" "REL1_30" "REL1_31" "REL1_32" "REL1_33" "REL1_34"; do
        if [[ "$1" == "$legacy" ]]; then
          COMPOSER=${composer1}
        fi
      done

      echo "Upgrade mediawiki tree using upstream release branch \`$1'"
      ${git}/bin/git rm -rf --ignore-unmatch mediawiki
      rm -rf mediawiki
      ${git}/bin/git clone --depth 1 --recurse-submodules -b $1 -- https://github.com/wikimedia/mediawiki.git mediawiki
      cp composer.local.json mediawiki
      pushd mediawiki
      $COMPOSER/bin/composer update --no-dev
      $COMPOSER/bin/composer dump-autoload
      popd
      find mediawiki -name .git -exec rm -rf {} +
      ${git}/bin/git add mediawiki
    '';

    updateScript = pkgs.writeShellScript "composer-update" ''
      echo "Running \`composer update' in mediawiki tree"
      pushd mediawiki
      $COMPOSER/bin/composer update --no-dev
      $COMPOSER/bin/composer dump-autoloads
      popd
      ${git}/bin/git add mediawiki
    '';

    komapedia-mediawiki = let
      inherit (pkgs.lib) attrNames filter filterAttrs hasPrefix head pipe;
      inherit (builtins) elemAt match readDir;

      version = pipe ./mediawiki [
        readDir
        (filterAttrs (name: _type: hasPrefix "RELEASE-NOTES-" name))
        attrNames
        (map (name:
          builtins.match "^RELEASE-NOTES-([[:digit:]]+\\.[[:digit:]]+)$"
          name))
        (filter (elt: !isNull elt))
        head
        head
      ];
    in
      pkgs.stdenv.mkDerivation {
        pname = "KoMapedia mediawiki";
        inherit version;

        src = ./mediawiki;
      };
  in {
    overlay = final: prev: {inherit komapedia-mediawiki;};

    apps.x86_64-linux = let
      update = {
        type = "app";
        program = "${updateScript}";
      };
      upgrade = {
        type = "app";
        program = "${upgradeScript}";
      };
    in {
      inherit update upgrade;
      composer = {
        type = "app";
        program = "${composer2}/bin/composer";
      };
      composer1 = {
        type = "app";
        program = "${composer1}/bin/composer";
      };
      default = update;
    };
    devShell.x86_64-linux =
      pkgs.mkShell {nativeBuildInputs = [composer1 composer2];};
    packages.x86_64-linux = {inherit komapedia-mediawiki;};
    nixosModules.komapedia = import ./modules/komapedia.nix;
    formatter.x86_64-linux = pkgs.alejandra;
  };
}
