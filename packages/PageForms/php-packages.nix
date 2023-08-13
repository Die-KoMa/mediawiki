{composerEnv, fetchurl, fetchgit ? null, fetchhg ? null, fetchsvn ? null, noDev ? false}:

let
  packages = {
    "composer/installers" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "composer-installers-d20a64ed3c94748397ff5973488761b22f6d3f19";
        src = fetchurl {
          url = "https://api.github.com/repos/composer/installers/zipball/d20a64ed3c94748397ff5973488761b22f6d3f19";
          sha256 = "1rkcf3cmxg7k802lazknhmx9vpwr306s8zhpc5cjmac7vkcwv3qc";
        };
      };
    };
    "mediawiki/page-forms" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "mediawiki-page-forms-f90d67ecc2c111e82db454c71592c83384ff9704";
        src = fetchurl {
          url = "https://api.github.com/repos/wikimedia/mediawiki-extensions-PageForms/zipball/f90d67ecc2c111e82db454c71592c83384ff9704";
          sha256 = "1j3jppaqhgp7hsnaz38ypj5sy5krh9kx077zzv6dq6ffs4n9d7ij";
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
