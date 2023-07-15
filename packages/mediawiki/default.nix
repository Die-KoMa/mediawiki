{pkgs, version}:
  pkgs.callPackage ./generic.nix {inherit version;}
