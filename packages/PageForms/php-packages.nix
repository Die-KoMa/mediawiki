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
        name = "mediawiki-page-forms-c861c29cb0bc2a99f5b90cb009e99f828039f6d2";
        src = fetchurl {
          url = "https://api.github.com/repos/wikimedia/mediawiki-extensions-PageForms/zipball/c861c29cb0bc2a99f5b90cb009e99f828039f6d2";
          sha256 = "0w6dr9031hn2h6fac1jsxaxgz632684vp9a8q23idwwiqwwmldd9";
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
