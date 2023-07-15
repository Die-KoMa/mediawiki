{
  writeShellScriptBin,
  composer1,
  composer2,
  git,
}:
writeShellScriptBin "mw-upgrade" ''
  set -euo pipefail
  if [[ $# -ne 1 ]]; then
    echo "Upgrade mediawiki tree using the given upstream release branch"
    echo "usage: $0 <RELEASE_BRANCH>"
    exit 1
  fi

  COMPOSER=${composer2}
  for legacy in "REL1_28" "REL1_29" "REL1_30" "REL1_31" "REL1_32" "REL1_33" "REL1_34"; do
    if [[ "$1" == "$legacy" ]]; then
      COMPOSER=${composer1}
    fi
  done

  echo "Upgrade mediawiki tree using upstream release branch \`$1'"
  ${git}/bin/git rm -rf --ignore-unmatch mediawiki
  rm -rf mediawiki
  ${git}/bin/git clone --depth 1 \
    --recurse-submodules \
    --branch $1 -- https://github.com/wikimedia/mediawiki.git mediawiki
  cp composer.local.json mediawiki
  pushd mediawiki
  cat <<EOF >> .gitignore
  !/vendor
  !/composer.lock
  !/composer.json
  !/composer.local.json
  EOF
  rm -rf skins extensions/.gitignore
  ${git}/bin/git clone --depth 1 \
    --recurse-submodules=Vector \
    --recurse-submodules=VectorV2 \
    --recurse-submodules=Timeless \
    --recurse-submodules=MonoBook \
    --branch $1 -- https://github.com/wikimedia/mediawiki-skins.git skins
  $COMPOSER/bin/composer update --no-dev
  $COMPOSER/bin/composer dump-autoload
  popd
  find mediawiki -name .git -exec rm -rf {} +
  ${git}/bin/git add mediawiki
''
