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
    "data-values/common" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "data-values-common-b21c2bd3b213d6233a645003df4f88956afc52f4";
        src = fetchurl {
          url = "https://api.github.com/repos/DataValues/Common/zipball/b21c2bd3b213d6233a645003df4f88956afc52f4";
          sha256 = "12nnzal5bgnk928wgkr3l707c1vc003g1xcyn900d7q4mbbfsslg";
        };
      };
    };
    "data-values/data-values" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "data-values-data-values-45aca708da1f7d39c4fca9e6c7373404627e083b";
        src = fetchurl {
          url = "https://api.github.com/repos/DataValues/DataValues/zipball/45aca708da1f7d39c4fca9e6c7373404627e083b";
          sha256 = "0f09g81714hs0n7d5hxw0963snjp1sbfg1srl362hfxrs64rjfak";
        };
      };
    };
    "data-values/interfaces" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "data-values-interfaces-22573cd52a7b37416f28ed6a8d8706543b0d430a";
        src = fetchurl {
          url = "https://api.github.com/repos/DataValues/Interfaces/zipball/22573cd52a7b37416f28ed6a8d8706543b0d430a";
          sha256 = "173zwd6g63as8b6l8r205d59jb28g6fgjc5p4v559q7nnchnir4y";
        };
      };
    };
    "data-values/validators" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "data-values-validators-83dbac2c5e9442e8fa2119c8b941ecb88156abe8";
        src = fetchurl {
          url = "https://api.github.com/repos/DataValues/Validators/zipball/83dbac2c5e9442e8fa2119c8b941ecb88156abe8";
          sha256 = "1z2jrswys7jh6w2cpi94rgcd67jdf1dfc8652ixyj7jpx4dmbpyh";
        };
      };
    };
    "jeroen/file-fetcher" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "jeroen-file-fetcher-d9fadc0486ef690ce7dd9c6d32d6e5f2857bfd80";
        src = fetchurl {
          url = "https://api.github.com/repos/JeroenDeDauw/FileFetcher/zipball/d9fadc0486ef690ce7dd9c6d32d6e5f2857bfd80";
          sha256 = "068r8vfy0zgdpczm6ikln36vhjf8kj2zbqxxdcbjyfsrksv3znq6";
        };
      };
    };
    "jeroen/message-reporter" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "jeroen-message-reporter-acf6cf8be76f8c6e39f6b22022e377016b6d2ac1";
        src = fetchurl {
          url = "https://api.github.com/repos/JeroenDeDauw/message-reporter/zipball/acf6cf8be76f8c6e39f6b22022e377016b6d2ac1";
          sha256 = "0qvckjvdra3vfib9hq9428csbkj5n2j1n4axp02cyccgyc3ycs54";
        };
      };
    };
    "mediawiki/semantic-media-wiki" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "mediawiki-semantic-media-wiki-317dc05c8f14c5bf0e4eaae576b33540e2068593";
        src = fetchurl {
          url = "https://api.github.com/repos/SemanticMediaWiki/SemanticMediaWiki/zipball/317dc05c8f14c5bf0e4eaae576b33540e2068593";
          sha256 = "0c9qhsj4gdc0gbvg7wpj0r2zqcpg38ama965c4n619z6gc31072g";
        };
      };
    };
    "param-processor/param-processor" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "param-processor-param-processor-1b697b2e69bd1c47e375d2776b943470330adb9a";
        src = fetchurl {
          url = "https://api.github.com/repos/JeroenDeDauw/ParamProcessor/zipball/1b697b2e69bd1c47e375d2776b943470330adb9a";
          sha256 = "00m2y12n9lw04qid19sd9af7dbrlfd4425x7njghw6d09lv6ba4i";
        };
      };
    };
    "psr/log" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "psr-log-f16e1d5863e37f8d8c2a01719f5b34baa2b714d3";
        src = fetchurl {
          url = "https://api.github.com/repos/php-fig/log/zipball/f16e1d5863e37f8d8c2a01719f5b34baa2b714d3";
          sha256 = "14h8r5qwjvlj7mjwk6ksbhffbv4k9v5cailin9039z1kz4nwz38y";
        };
      };
    };
    "serialization/serialization" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "serialization-serialization-4403fbab83e0187791d35caef4eef4395811e58d";
        src = fetchurl {
          url = "https://api.github.com/repos/wmde/Serialization/zipball/4403fbab83e0187791d35caef4eef4395811e58d";
          sha256 = "0gsm2x86lrqh60iff4ybghdvd1wj6ycq6p48m6m0a8ig4sdn62z7";
        };
      };
    };
    "wikimedia/textcat" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "wikimedia-textcat-dfdfb1c41bb016814a9d4da3aa68b62437b54a82";
        src = fetchurl {
          url = "https://api.github.com/repos/wikimedia/textcat/zipball/dfdfb1c41bb016814a9d4da3aa68b62437b54a82";
          sha256 = "0sqrgz1z32dc2ci1s01fvsq9jvkjip84xhxginw5r24rxn2hgndm";
        };
      };
    };
  };
  devPackages = {};
in
composerEnv.buildPackage {
  inherit packages devPackages noDev;
  name = "mediawiki-semantic-media-wiki";
  src = composerEnv.filterSrc ./.;
  executable = true;
  symlinkDependencies = false;
  meta = {};
}
