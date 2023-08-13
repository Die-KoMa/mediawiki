{pkgs}: let
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
  composer = withMainProgram "composer" pkgs.phpPackages.composer;

  upgrade = pkgs.callPackage ./upgrade-script.nix {inherit composer;};
  update = pkgs.callPackage ./update-script.nix {inherit composer;};

  komapedia-mediawiki = pkgs.callPackage ./mediawiki {inherit version;};
}
