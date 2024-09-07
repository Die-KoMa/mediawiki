{composerEnv, fetchurl, fetchgit ? null, fetchhg ? null, fetchsvn ? null, noDev ? false}:

let
  packages = {
    "composer/installers" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "composer-installers-12fb2dfe5e16183de69e784a7b84046c43d97e8e";
        src = fetchurl {
          url = "https://api.github.com/repos/composer/installers/zipball/12fb2dfe5e16183de69e784a7b84046c43d97e8e";
          sha256 = "0mvfi9rn5m6j4gmbi15jas3rd6gvgvipf5anhmxx4mqslc7pggx8";
        };
      };
    };
    "mediawiki/page-forms" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "mediawiki-page-forms-6ae070587e3ab05b2831a0002f5f53fe90cb024c";
        src = fetchurl {
          url = "https://api.github.com/repos/wikimedia/mediawiki-extensions-PageForms/zipball/6ae070587e3ab05b2831a0002f5f53fe90cb024c";
          sha256 = "0di5l5w2d4w1vlfm0gab2pni1g8v1pqamh6akn3wigh93acjdvlg";
        };
      };
    };
  };
  devPackages = {};
in
composerEnv.buildPackage {
  inherit packages devPackages noDev;
  name = "mediawiki-page-forms";
  src = composerEnv.filterSrc ./.;
  executable = true;
  symlinkDependencies = false;
  meta = {};
}
