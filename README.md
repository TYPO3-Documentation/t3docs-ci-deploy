# Build and Deployment Pipelines for TYPO3 Documentation

## ViewHelper Reference

The Fluid ViewHelper Reference is generated automatically based on the PHP source files.
For each major TYPO3 version (as well as current `main`), a simplified `composer.json`
exists in [Build/fluid-viewhelpers](./Build/fluid-viewhelpers/). The CI workflow works
as follows:

* Install TYPO3
* Generate RST/JSON files for documentation
* Commit results in [TYPO3CMS-Reference-ViewHelper](https://github.com/TYPO3-Documentation/TYPO3CMS-Reference-ViewHelper)

See: [fluid-viewhelper.yaml](./.github/workflows/fluid-viewhelper.yml)

If a new TYPO3 version is released, a new basic composer setup needs to be added to this
repository. Also, this folder name needs to be added to the GitHub Actions version matrix.
