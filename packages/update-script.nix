{
  composer,
  writeShellScriptBin,
  git,
}:
writeShellScriptBin "composer-update" ''
  echo "Running \`composer update' in mediawiki tree"
  pushd mediawiki
  ${composer}/bin/composer update --no-dev
  ${composer}/bin/composer dump-autoload
  popd
  ${git}/bin/git add mediawiki
''
