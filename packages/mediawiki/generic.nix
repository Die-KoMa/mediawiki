{
  pkgs,
  version,
}: let
  src =
    ../../mediawiki;
in
  pkgs.stdenv.mkDerivation {
    pname = "KoMapedia-mediawiki";
    description = "KoMapedia MediaWiki distribution";
    inherit version src;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share
      cp --recursive --reflink=auto ${src} $out/share/mediawiki

      runHook postInstall
    '';
  }
