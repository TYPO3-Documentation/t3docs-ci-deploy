# Build and Deployment Pipelines for TYPO3 Documentation

## Reusable CI Workflows

Centralized, reusable GitHub Actions workflows for repositories in the
[TYPO3-Documentation](https://github.com/TYPO3-Documentation) organization.

### Why

The TYPO3-Documentation org enforces a GitHub Actions **allow-list** with
SHA-pinned actions. This creates two maintenance challenges:

1. **Composite actions break the allow-list.** Actions like
   `ramsey/composer-install` internally call `actions/cache@v4`, which the
   caller's allow-list must also approve. When the inner action updates its
   SHA, all callers break silently.

2. **~60 workflow files across ~29 repos** must each be updated when action
   SHAs change, backport tooling breaks, or CI patterns evolve.

Reusable workflows solve both problems: they execute in their **own**
context (this repository), so only *this* repo's action references need to
stay current. Callers reference a single workflow by tag/SHA and inherit
all updates automatically.

### Available Reusable Workflows

| Workflow | Purpose |
|----------|--------|
| [`reusable-backport.yml`](.github/workflows/reusable-backport.yml) | Backport merged PRs via `korthout/backport-action` |
| [`reusable-docs-render.yml`](.github/workflows/reusable-docs-render.yml) | Documentation rendering check |
| [`reusable-php-quality.yml`](.github/workflows/reusable-php-quality.yml) | Code quality: CS Fixer, PHPStan, XML lint |
| [`reusable-php-tests.yml`](.github/workflows/reusable-php-tests.yml) | PHP test matrix (unit + integration) |

### Usage

Call a workflow from your repository's workflow file:

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  tests:
    uses: TYPO3-Documentation/t3docs-ci-deploy/.github/workflows/reusable-php-tests.yml@main
    with:
      php-versions: '["8.2", "8.3", "8.4"]'
      test-unit-command: 'make test-unit'

  quality:
    uses: TYPO3-Documentation/t3docs-ci-deploy/.github/workflows/reusable-php-quality.yml@main
    with:
      php-version: '8.2'

  docs:
    uses: TYPO3-Documentation/t3docs-ci-deploy/.github/workflows/reusable-docs-render.yml@main
```

Backport workflow (in a separate workflow file triggered on PRs):

```yaml
name: Backport
on:
  pull_request_target:
    types:
      - closed
      - labeled

jobs:
  backport:
    uses: TYPO3-Documentation/t3docs-ci-deploy/.github/workflows/reusable-backport.yml@main
    with:
      label-pattern: "backport *"
```

Each workflow accepts optional inputs with sensible defaults.
See the individual workflow files for the full list of inputs.

### Action SHA Pins

All actions are SHA-pinned to verified commits. Current pins:

| Action | Version | SHA |
|--------|---------|-----|
| `actions/checkout` | v6.0.2 | `de0fac2e4500dabe0009e67214ff5f5447ce83dd` |
| `actions/cache` | v5.0.3 | `cdf6c1fa76f9f475f3d7449005a359c84ca0f306` |
| `actions/setup-python` | v6.2.0 | `a309ff8b426b58ec0e2a45f0f869d46889d02405` |
| `shivammathur/setup-php` | 2.36.0 | `44454db4f0199b8b9685a5d763dc37cbf79108e1` |
| `korthout/backport-action` | v4.2.0 | `4aaf0e03a94ff0a619c9a511b61aeb42adea5b02` |

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
