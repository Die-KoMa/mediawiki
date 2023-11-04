{
  pkgs,
  lib,
  system,
  ...
}: let
  jsonForExtension = kind: name: builtins.fromJSON (builtins.readFile (./. + "/${name}/extensions/${name}/${kind}.json"));
  metaForExtension = name: let
    json = jsonForExtension "extension" name;
  in {
    pname = json.name;
    inherit (json) version;
    meta = lib.optionalAttrs (json.license-name == "GPL-2.0-or-later") {
      license = lib.licenses.gpl2Plus;
    };
  };
  pathForExtension = name: let
    json = jsonForExtension "composer" name;
    dir = lib.replaceStrings ["/"] ["-"] json.name;
  in "share/php/${dir}";
  composerExtension = name: composerExtension' name {};
  composerExtension' = name: fixups: let
    drv = import (./. + "/${name}") {
      inherit pkgs system;
      noDev = true;
    };
    meta = metaForExtension name;
    path = pathForExtension name;

    replacements = lib.concatStringsSep " " (lib.mapAttrsToList (name: path: ''--replace "__DIR__ . '/../..' . '/extensions/${name}/" "'${path}/"'') fixups);
  in
    pkgs.stdenv.mkDerivation {
      inherit (meta) pname version meta;

      dontUnpack = true;

      installPhase = ''
        mkdir $out
        cp -R ${drv}/${path}/extensions/${name}/* $out
        cp -R ${drv}/${path}/vendor vendor

        pushd vendor/composer/
        substituteInPlace *.json *.php --replace "/extensions/${name}/" "/" ${replacements}
        popd

        cp -R vendor $out/
      '';
    };
in rec {
  PageForms = composerExtension "PageForms";
  SemanticMediaWiki = composerExtension "SemanticMediaWiki";
  SemanticResultFormats = composerExtension' "SemanticResultFormats" {inherit SemanticMediaWiki;};

  EditSubpages = pkgs.fetchzip {
    url = "https://extdist.wmflabs.org/dist/extensions/EditSubpages-REL1_39-e462ff9.tar.gz";
    sha256 = "sha256-Q0sAaCaF4HOdspxGR97DL16i7WFGv1Ha//ToK/Sq+kc=";
  };
  UserMerge = pkgs.fetchzip {
    url = "https://extdist.wmflabs.org/dist/extensions/UserMerge-REL1_39-55fe954.tar.gz";
    sha256 = "sha256-pQgb5It3nyoL1XOuJo0mURxHXFh4EiXdSm4f4npY4yw=";
  };
  Variables = pkgs.fetchzip {
    url = "https://extdist.wmflabs.org/dist/extensions/Variables-REL1_39-7153f4d.tar.gz";
    sha256 = "sha256-JWGRWChAJYkWAoETCr3ZXxXdND4C0R5Io8Ti4MD1wM4=";
  };
}
