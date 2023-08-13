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
    url = "https://extdist.wmflabs.org/dist/extensions/EditSubpages-REL1_39-67938fd.tar.gz";
    sha256 = "sha256-GCjQlIXGbvE6mhf84UYSe6MV3cH3kbpCMQI4JIeyyL4=";
  };
  UserMerge = pkgs.fetchzip {
    url = "https://extdist.wmflabs.org/dist/extensions/UserMerge-REL1_39-a6fd7d8.tar.gz";
    sha256 = "sha256-84I+fUhwAvSfjIrxy4u8LoXvFlvI3TkVlIRAqVy1TvQ=";
  };
  Variables = pkgs.fetchzip {
    url = "https://extdist.wmflabs.org/dist/extensions/Variables-REL1_39-1620bdf.tar.gz";
    sha256 = "sha256-EIYivBIevBaKM7A/Tu/7UkAnQwoVnwGRNnQ88B9yhQw=";
  };
}
