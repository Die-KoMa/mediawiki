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
        name = "data-values-data-values-1084142918095dfedf9b6cc0de0755f8c4628264";
        src = fetchurl {
          url = "https://api.github.com/repos/DataValues/DataValues/zipball/1084142918095dfedf9b6cc0de0755f8c4628264";
          sha256 = "08rwf24b6kdp6ixsvxi6jla000i2v1skcf08lvs4n57gmyjcwygj";
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
        name = "jeroen-file-fetcher-d38fb0587b52b28bd24fda599f2da69ac8530453";
        src = fetchurl {
          url = "https://api.github.com/repos/JeroenDeDauw/FileFetcher/zipball/d38fb0587b52b28bd24fda599f2da69ac8530453";
          sha256 = "1v55rh35xynni7pk467cm802153cd23sx77vhacaqc5yl3vdlk7f";
        };
      };
    };
    "justinrainbow/json-schema" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "justinrainbow-json-schema-feb2ca6dd1cebdaf1ed60a4c8de2e53ce11c4fd8";
        src = fetchurl {
          url = "https://api.github.com/repos/jsonrainbow/json-schema/zipball/feb2ca6dd1cebdaf1ed60a4c8de2e53ce11c4fd8";
          sha256 = "13gy5lh8cza7kwsn7s8960114icjz52lk1ja28kxf4v67yc1qswq";
        };
      };
    };
    "mediawiki/http-request" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "mediawiki-http-request-1818e0731561621121fcc9da90f244a727ef0989";
        src = fetchurl {
          url = "https://api.github.com/repos/SemanticMediaWiki/http-request/zipball/1818e0731561621121fcc9da90f244a727ef0989";
          sha256 = "17d1azjmf7jdpwlh3f35gsxmydrl0x5jkimhcwzq5rh214wybf9f";
        };
      };
    };
    "mediawiki/parser-hooks" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "mediawiki-parser-hooks-45660efef737bcf33abbbb12c1ddb049c4e713fe";
        src = fetchurl {
          url = "https://api.github.com/repos/JeroenDeDauw/ParserHooks/zipball/45660efef737bcf33abbbb12c1ddb049c4e713fe";
          sha256 = "081zb3yql0px95rcyrbcmgm7j3f05jbjpc4m47g2vcldif534xrb";
        };
      };
    };
    "mediawiki/semantic-media-wiki" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "mediawiki-semantic-media-wiki-0a8af7546b81f6dcab3f336f14023c8e7aea3805";
        src = fetchurl {
          url = "https://api.github.com/repos/SemanticMediaWiki/SemanticMediaWiki/zipball/0a8af7546b81f6dcab3f336f14023c8e7aea3805";
          sha256 = "02pg2rjfnhj4ddcy7c1kikyg4mz8cjp4rp7l7f03911dlss86jdr";
        };
      };
    };
    "onoi/blob-store" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "onoi-blob-store-c3e1f15214977e904fc0e91e0480175a464977ce";
        src = fetchurl {
          url = "https://api.github.com/repos/onoi/blob-store/zipball/c3e1f15214977e904fc0e91e0480175a464977ce";
          sha256 = "0yrqmh099i9qml2qg2s8hxmdlbkrzil4j7fvw4zvl4cpzm5aj44m";
        };
      };
    };
    "onoi/cache" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "onoi-cache-ecc999186aab7c8db411aedd892b2e5fe5a0b422";
        src = fetchurl {
          url = "https://api.github.com/repos/onoi/cache/zipball/ecc999186aab7c8db411aedd892b2e5fe5a0b422";
          sha256 = "1nmcklay80lkzfb5yzqdlsp4p8q37k6ha5q4w429l8cx4xha2326";
        };
      };
    };
    "onoi/callback-container" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "onoi-callback-container-cf2f4dda1b2479bc786985fdb5554af528d03e52";
        src = fetchurl {
          url = "https://api.github.com/repos/onoi/callback-container/zipball/cf2f4dda1b2479bc786985fdb5554af528d03e52";
          sha256 = "0cqwiwi767sp3v7qdxi7qdd76irpfma3n1xcp18lkjrp04jl5581";
        };
      };
    };
    "onoi/event-dispatcher" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "onoi-event-dispatcher-2af64e3997fc59b6d1e1f8f77e65fd6311c37109";
        src = fetchurl {
          url = "https://api.github.com/repos/onoi/event-dispatcher/zipball/2af64e3997fc59b6d1e1f8f77e65fd6311c37109";
          sha256 = "05pbh1cmd1kh45f6ha6kjz2hn765m8bazr3x0zyj7v2zgjcwkfs0";
        };
      };
    };
    "onoi/message-reporter" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "onoi-message-reporter-ead8ef8f2868ccee6881e471295ebbaf8428c96c";
        src = fetchurl {
          url = "https://api.github.com/repos/onoi/message-reporter/zipball/ead8ef8f2868ccee6881e471295ebbaf8428c96c";
          sha256 = "1ah15w13b9fc91ib47m6ykhk666ka48wcis0bj51zc77hiarcdw9";
        };
      };
    };
    "param-processor/param-processor" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "param-processor-param-processor-0850dc2af72d31b8f645e0f87a44ff4b68583a64";
        src = fetchurl {
          url = "https://api.github.com/repos/JeroenDeDauw/ParamProcessor/zipball/0850dc2af72d31b8f645e0f87a44ff4b68583a64";
          sha256 = "02qf772fl4ixs72r3wdyy54j5l2pigrcq3ray2pr929rik3qz0yl";
        };
      };
    };
    "psr/log" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "psr-log-d49695b909c3b7628b6289db5479a1c204601f11";
        src = fetchurl {
          url = "https://api.github.com/repos/php-fig/log/zipball/d49695b909c3b7628b6289db5479a1c204601f11";
          sha256 = "0sb0mq30dvmzdgsnqvw3xh4fb4bqjncx72kf8n622f94dd48amln";
        };
      };
    };
    "seld/jsonlint" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "seld-jsonlint-1748aaf847fc731cfad7725aec413ee46f0cc3a2";
        src = fetchurl {
          url = "https://api.github.com/repos/Seldaek/jsonlint/zipball/1748aaf847fc731cfad7725aec413ee46f0cc3a2";
          sha256 = "0a7llwd5vv6s6nxxldpljanznjb1y0y3fbmh0m16k9dw7psf3f2z";
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
    "symfony/css-selector" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "symfony-css-selector-4f7f3c35fba88146b56d0025d20ace3f3901f097";
        src = fetchurl {
          url = "https://api.github.com/repos/symfony/css-selector/zipball/4f7f3c35fba88146b56d0025d20ace3f3901f097";
          sha256 = "1ha6znpb231v8n5cm22898giiad2ify3lrrn95qwqal7r337wvxr";
        };
      };
    };
    "symfony/polyfill-php80" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "symfony-polyfill-php80-60328e362d4c2c802a54fcbf04f9d3fb892b4cf8";
        src = fetchurl {
          url = "https://api.github.com/repos/symfony/polyfill-php80/zipball/60328e362d4c2c802a54fcbf04f9d3fb892b4cf8";
          sha256 = "008nx5xplqx3iks3fpzd4qgy3zzrvx1bmsdc13ndf562a6hf9lrg";
        };
      };
    };
    "wikimedia/cdb" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "wikimedia-cdb-3d7622f39319ea2149cac92415222d1fb39c46d0";
        src = fetchurl {
          url = "https://api.github.com/repos/wikimedia/cdb/zipball/3d7622f39319ea2149cac92415222d1fb39c46d0";
          sha256 = "1vfcfxv5015460xqczb77m90rif9d7b0vqm6bka7j6wn6bdz866v";
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
