{
  pkgs,
  lib,
  system,
  ...
}: let
  composerExtension = name:
    import (./. + "/${name}") {
      inherit pkgs system;
      noDev = true;
    };
in {
  PageForms = composerExtension "PageForms";
  SemanticMediaWiki = composerExtension "SemanticMediaWiki";
  SemanticResultFormats = composerExtension "SemanticResultFormats";
}
