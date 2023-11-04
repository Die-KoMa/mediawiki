# KoMapedia

## Update extensions package
Needs to be done individually for each packaged extension.

```bash
cd packages/SemanticMediaWiki
rm composer.lock
composer2nix -p mediawiki/semantic-media-wiki
git add .
```
