{
  composerEnv,
  fetchurl,
  fetchgit ? null,
  fetchhg ? null,
  fetchsvn ? null,
  noDev ? false,
}:

let
  packages = {
    "composer/installers" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "composer-installers-c29dc4b93137acb82734f672c37e029dfbd95b35";
        src = fetchurl {
          url = "https://api.github.com/repos/composer/installers/zipball/c29dc4b93137acb82734f672c37e029dfbd95b35";
          sha256 = "05d2dbfdlf5fbycl7gj6wr4c63dwlq3minm7fg2ampb2ynazc5cr";
        };
      };
    };
    "mediawiki/page-forms" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "mediawiki-page-forms-b3be227fa9650f1a165ab1cc549100f643646714";
        src = fetchurl {
          url = "https://api.github.com/repos/wikimedia/mediawiki-extensions-PageForms/zipball/b3be227fa9650f1a165ab1cc549100f643646714";
          sha256 = "1ylimjm2nzdp0cys8lpsryzl1lnrxgamdr96ianc7crw6g3q0s7a";
        };
      };
    };
  };
  devPackages = { };
in
composerEnv.buildPackage {
  inherit packages devPackages noDev;
  name = "mediawiki-page-forms";
  src = composerEnv.filterSrc ./.;
  executable = true;
  symlinkDependencies = false;
  meta = { };
}
