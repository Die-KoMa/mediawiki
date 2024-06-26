{
  pkgs,
  lib,
  system,
  ...
}:
let
  jsonForExtension =
    kind: name:
    builtins.fromJSON (builtins.readFile (./. + "/${name}/extensions/${name}/${kind}.json"));
  metaForExtension =
    name:
    let
      json = jsonForExtension "extension" name;
    in
    {
      pname = json.name;
      inherit (json) version;
      meta = lib.optionalAttrs (json.license-name == "GPL-2.0-or-later") {
        license = lib.licenses.gpl2Plus;
      };
    };
  pathForExtension =
    name:
    let
      json = jsonForExtension "composer" name;
      dir = lib.replaceStrings [ "/" ] [ "-" ] json.name;
    in
    "share/php/${dir}";
  composerExtension = name: composerExtension' name { };
  composerExtension' =
    name: fixups:
    let
      drv = import (./. + "/${name}") {
        inherit pkgs system;
        noDev = true;
      };
      meta = metaForExtension name;
      path = pathForExtension name;

      replacements = lib.concatStringsSep " " (
        lib.mapAttrsToList (
          name: path: ''--replace "__DIR__ . '/../..' . '/extensions/${name}/" "'${path}/"''
        ) fixups
      );
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
  extdistExtension =
    src:
    let
      components = lib.splitString "/" src;
      filename = lib.last components;
      bare = lib.removeSuffix ".tar.gz" filename;
      parts = lib.splitString "-" bare;
      pname = lib.head parts;
      version = lib.concatStringsSep "-" (lib.tail parts);
    in
    pkgs.stdenv.mkDerivation {
      inherit pname version src;

      installPhase = ''
        mkdir $out
        tar --strip-components=1 --one-top-level=$out -xf $src
      '';
    };
in
rec {
  mediawiki = pkgs.mediawiki.overrideAttrs (old: rec {
    version = "1.39.7";
    src = pkgs.fetchurl {
      url = "https://releases.wikimedia.org/mediawiki/${lib.versions.majorMinor version}/mediawiki-${version}.tar.gz";
      hash = "sha256-K+gVaBfVxWn9Ylc0KidvkdflMNHA3OETS3vysJ7K5Wk=";
    };
  });

  PageForms = composerExtension "PageForms";
  SemanticMediaWiki = composerExtension "SemanticMediaWiki";
  SemanticResultFormats = composerExtension' "SemanticResultFormats" { inherit SemanticMediaWiki; };

  EditSubpages = extdistExtension ./EditSubpages-REL1_39-b57d32d.tar.gz;
  UserMerge = extdistExtension ./UserMerge-REL1_39-7e6949f.tar.gz;
  Variables = extdistExtension ./Variables-REL1_39-c1dea98.tar.gz;
  NativeSvgHandler = extdistExtension ./NativeSvgHandler-REL1_39-6858505.tar.gz;
  OpenGraphMeta = extdistExtension ./OpenGraphMeta-REL1_39-c20af38.tar.gz;
  Description2 = extdistExtension ./Description2-REL1_39-55c1dcd.tar.gz;
}
