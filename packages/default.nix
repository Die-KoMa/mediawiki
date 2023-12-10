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
  extdistExtension = {
    url,
    hash,
  }: let
    filename = lib.removePrefix "https://extdist.wmflabs.org/dist/extensions/" url;
    bare = lib.removeSuffix ".tar.gz" filename;
    parts = lib.splitString "-" bare;
    pname = lib.head parts;
    version = lib.concatStringsSep "-" (lib.tail parts);
  in
    pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = pkgs.fetchzip {inherit url hash;};

      installPhase = ''
        cp -R $src $out
      '';
    };
in rec {
  PageForms = composerExtension "PageForms";
  SemanticMediaWiki = composerExtension "SemanticMediaWiki";
  SemanticResultFormats = composerExtension' "SemanticResultFormats" {inherit SemanticMediaWiki;};

  EditSubpages = extdistExtension {
    url = "https://extdist.wmflabs.org/dist/extensions/EditSubpages-REL1_39-e462ff9.tar.gz";
    hash = "sha256-Q0sAaCaF4HOdspxGR97DL16i7WFGv1Ha//ToK/Sq+kc=";
  };
  UserMerge = extdistExtension {
    url = "https://extdist.wmflabs.org/dist/extensions/UserMerge-REL1_39-89621f4.tar.gz";
    hash = "sha256-+Xjh6YWnaBER8v1LOhQaWZNg2EMwkeZq8isPp9u9fBI=";
  };
  Variables = extdistExtension {
    url = "https://extdist.wmflabs.org/dist/extensions/Variables-REL1_39-c1dea98.tar.gz";
    hash = "sha256-iSnPt5VBE1vNRFHIJflmMIIMxsr/fzP1gdGpzQT/7xo=";
  };
  NativeSvgHandler = extdistExtension {
    url = "https://extdist.wmflabs.org/dist/extensions/NativeSvgHandler-REL1_39-95310ed.tar.gz";
    hash = "sha256-EUrHF1JBR3bc3kwwYv6rvPseG0rl/YyBp4GjI5q+ETo=";
  };
}
