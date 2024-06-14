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
    "data-values/common" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "data-values-common-9f5e6216ec66ac8f2281351b110bad0eded43e65";
        src = fetchurl {
          url = "https://api.github.com/repos/DataValues/Common/zipball/9f5e6216ec66ac8f2281351b110bad0eded43e65";
          sha256 = "0qgbchshqjpm68z71774adrmr6khfmmz0yjb8i4hsia5asyqpp4y";
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
    "data-values/geo" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "data-values-geo-1dd742dabb63e211862486259b2cbe0274211bf9";
        src = fetchurl {
          url = "https://api.github.com/repos/DataValues/Geo/zipball/1dd742dabb63e211862486259b2cbe0274211bf9";
          sha256 = "0zn6v96f0d7nrvmhmxbp953g7ibqf3has7ksl70maqhn0dd36wpn";
        };
      };
    };
    "data-values/interfaces" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "data-values-interfaces-244d078954bc05edf8f8c6b088e848289171c3a8";
        src = fetchurl {
          url = "https://api.github.com/repos/DataValues/Interfaces/zipball/244d078954bc05edf8f8c6b088e848289171c3a8";
          sha256 = "19dq2s1zaq3rk0ylb9iy0jabfawzwk7ply31chx3si88vdqz4595";
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
        name = "justinrainbow-json-schema-fbbe7e5d79f618997bc3332a6f49246036c45793";
        src = fetchurl {
          url = "https://api.github.com/repos/jsonrainbow/json-schema/zipball/fbbe7e5d79f618997bc3332a6f49246036c45793";
          sha256 = "0yhhv8chrnn2bk21v5b9jn3wbzm6vs415xbxl5rl6y5kkmvf6wng";
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
        name = "mediawiki-semantic-media-wiki-b5e2afe11991fe21a335cb90426de24b85bc9fe7";
        src = fetchurl {
          url = "https://api.github.com/repos/SemanticMediaWiki/SemanticMediaWiki/zipball/b5e2afe11991fe21a335cb90426de24b85bc9fe7";
          sha256 = "1jggiiai70lnfjps8p3001lhn1hsd3yrzxj1bny6wx00rp88p1rb";
        };
      };
    };
    "mediawiki/semantic-result-formats" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "mediawiki-semantic-result-formats-c0dd4bb99fe2ba4ce939eb74a42ec5d4579afb80";
        src = fetchurl {
          url = "https://api.github.com/repos/SemanticMediaWiki/SemanticResultFormats/zipball/c0dd4bb99fe2ba4ce939eb74a42ec5d4579afb80";
          sha256 = "1f41qhbcpb7cfmr9pv8ra0wwh4x2418lnxmizkbs6qpzhvg8272l";
        };
      };
    };
    "nicmart/tree" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "nicmart-tree-0616b54bb49938e1a816141d7943db48ebf76938";
        src = fetchurl {
          url = "https://api.github.com/repos/nicmart/Tree/zipball/0616b54bb49938e1a816141d7943db48ebf76938";
          sha256 = "1qkh5s07nzrcl2yz5gbz30a5q7fqjdl06blpyn6fssvh9gjb5lmp";
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
        name = "seld-jsonlint-9bb7db07b5d66d90f6ebf542f09fc67d800e5259";
        src = fetchurl {
          url = "https://api.github.com/repos/Seldaek/jsonlint/zipball/9bb7db07b5d66d90f6ebf542f09fc67d800e5259";
          sha256 = "1m33fpb161pnq544iwkwi040zj9qyxivb2qx9d363hzqg76xm6qi";
        };
      };
    };
    "serialization/serialization" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "serialization-serialization-6fa293415e2b70c30c1e673d8bcd04d27dc15e44";
        src = fetchurl {
          url = "https://api.github.com/repos/wmde/Serialization/zipball/6fa293415e2b70c30c1e673d8bcd04d27dc15e44";
          sha256 = "0r9y72g79h4ycqlywgkagwya5qj6dfs20v4zxzlnp6hwlbfkhd5y";
        };
      };
    };
    "symfony/css-selector" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "symfony-css-selector-ea43887e9afd2029509662d4f95e8b5ef6fc9bbb";
        src = fetchurl {
          url = "https://api.github.com/repos/symfony/css-selector/zipball/ea43887e9afd2029509662d4f95e8b5ef6fc9bbb";
          sha256 = "1l35g6by3aan0j97663zgwha0xjb0pfmpgrinsllwckyy8819m27";
        };
      };
    };
    "symfony/polyfill-php80" = {
      targetDir = "";
      src = composerEnv.buildZipPackage {
        name = "symfony-polyfill-php80-87b68208d5c1188808dd7839ee1e6c8ec3b02f1b";
        src = fetchurl {
          url = "https://api.github.com/repos/symfony/polyfill-php80/zipball/87b68208d5c1188808dd7839ee1e6c8ec3b02f1b";
          sha256 = "1pn6dzj8b3h8851w3y6mj5qrwklwky5w71v4m455553qlga5cfr7";
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
  devPackages = { };
in
composerEnv.buildPackage {
  inherit packages devPackages noDev;
  name = "mediawiki-semantic-result-formats";
  src = composerEnv.filterSrc ./.;
  executable = true;
  symlinkDependencies = false;
  meta = { };
}
