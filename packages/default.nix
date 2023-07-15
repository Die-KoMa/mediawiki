{
  pkgs,
  legacyPkgs,
}: let
  inherit (pkgs.lib) attrNames filter filterAttrs hasPrefix head pipe;
  inherit (builtins) elemAt match readDir;
  version = pipe ../mediawiki [
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

  withMainProgram = mainProgram: drv:
    drv.overrideAttrs (old: {
      meta = old.meta // {inherit mainProgram;};
    });
in rec {
  php71 = legacyPkgs.php72.overrideAttrs (oldAttrs: rec {
    name = "php-7.1.33";
    version = "7.1.33";
    sha256 = "0jsgiwawlais8s1l38lz51h1x2ci5ildk0ksfdmkg6xpwbrfb9cm";
    src = builtins.fetchurl {
      url = "https://www.php.net/distributions/php-${version}.tar.bz2";
      inherit sha256;
    };
  });

  composer1 = withMainProgram "composer" legacyPkgs.phpPackages.composer;
  composer2 = withMainProgram "composer" pkgs.phpPackages.composer;

  upgrade = pkgs.callPackage ./upgrade-script.nix {inherit composer1 composer2;};
  update = pkgs.callPackage ./update-script.nix {composer = composer2;};
  update-legacy = pkgs.callPackage ./update-script.nix {composer = composer1;};

  komapedia-mediawiki = pkgs.callPackage ./mediawiki {inherit version;};
}
