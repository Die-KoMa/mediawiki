{composerEnv, fetchurl, fetchgit ? null, fetchhg ? null, fetchsvn ? null, noDev ? false}:

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
        name = "mediawiki-page-forms-a17165713eeebfc6fcc125eb2d1bd3a371b4d303";
        src = fetchurl {
          url = "https://api.github.com/repos/wikimedia/mediawiki-extensions-PageForms/zipball/a17165713eeebfc6fcc125eb2d1bd3a371b4d303";
          sha256 = "0674y13i61p08wwp4a1x00birk6zxx675a872wp14gqh6yqpl3pr";
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
