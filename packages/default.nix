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
        substituteInPlace *.json --replace "src/Tesa/src/" "Tesa/src"
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
{
  mediawiki = pkgs.mediawiki.overrideAttrs (old: rec {
    version = "1.43.0";
    src = pkgs.fetchurl {
      url = "https://releases.wikimedia.org/mediawiki/${lib.versions.majorMinor version}/mediawiki-${version}.tar.gz";
      hash = "sha256-VuCn/i/3jlC5yHs9WJ8tjfW8qwAY5FSypKI5yFhr2O4=";
    };
  });

  # PageForms 5.9.1 is broken with SemanticMediaWiki, need to use master
  # PageForms = composerExtension "PageForms";
  SemanticMediaWiki = composerExtension "SemanticMediaWiki";

  EditSubpages = extdistExtension ./EditSubpages-REL1_43.tar.gz;
  UserMerge = extdistExtension ./UserMerge-REL1_43.tar.gz;
  Variables = extdistExtension ./Variables-REL1_43.tar.gz;
  NativeSvgHandler = extdistExtension ./NativeSvgHandler-REL1_43.tar.gz;
  OpenGraphMeta = extdistExtension ./OpenGraphMeta-REL1_43.tar.gz;
  Description2 = extdistExtension ./Description2-REL1_43.tar.gz;
  Interwiki = extdistExtension ./Interwiki-REL1_43.tar.gz;
  PageForms = extdistExtension ./PageForms-master.tar.gz;
}
