# Build and Deployment Pipelines for TYPO3 Documentation

The GitHub Actions workflows that render, deploy and delete the manuals on
[docs.typo3.org](https://docs.typo3.org), generate the Fluid ViewHelper
reference, and render [api.typo3.org](https://api.typo3.org).

This repository contains no documentation of its own. The workflows live in
[`.github/workflows/`](./.github/workflows/); each file states its own triggers
and steps, and [`AGENTS.md`](./AGENTS.md) describes what they do and what is
easy to get wrong.

Rendering and deletion are triggered by **Intercept** (`intercept.typo3.com`)
through `repository_dispatch`, which passes the manual's repository, branch and
target path in the event payload. The remaining workflows run on a schedule.

## Reusable CI workflows

The reusable workflows for the organisation are **not** in this repository.
They live in
[TYPO3-Documentation/.github](https://github.com/TYPO3-Documentation/.github),
which documents them and their inputs, and they are referenced as:

```yaml
jobs:
  backport:
    uses: TYPO3-Documentation/.github/.github/workflows/reusable-backport.yml@main
```

## ViewHelper reference

The Fluid ViewHelper Reference is generated from the PHP source files. For each
documented TYPO3 version a slim `composer.json` exists in
[Build/fluid-viewhelpers](./Build/fluid-viewhelpers/). The workflow
[fluid-viewhelper.yml](./.github/workflows/fluid-viewhelper.yml) runs once per
version and, for each:

* installs that TYPO3 version,
* generates the reStructuredText and JSON files,
* commits the result to the branch of the same name in
  [TYPO3CMS-Reference-ViewHelper](https://github.com/TYPO3-Documentation/TYPO3CMS-Reference-ViewHelper).

reStructuredText files are only added, never overwritten, so hand-written pages
are safe. The JSON files are always replaced, which is what keeps descriptions
and argument tables current on pages that already exist.

Adding a TYPO3 version needs **two** changes: a new directory under
`Build/fluid-viewhelpers/`, and an entry in the workflow's matrix. The matrix
entry also pins the PHP version, because TYPO3 `main` requires a newer PHP than
the released branches do.

## Action pins

The organisation enforces an allow-list of SHA-pinned actions, so every `uses:`
here is pinned to a full commit SHA with the version in a trailing comment. The
workflow files are the source of truth for the current pins.
