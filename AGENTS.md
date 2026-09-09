# AGENTS.md — TYPO3 documentation CI and deployment

## What this repository is

This is **not a manual**. It holds the pipelines that build, deploy and delete
the manuals on docs.typo3.org, generate the Fluid ViewHelper reference, and
render api.typo3.org. There is no `Documentation/`, no Makefile, no reST, and
none of the writing conventions that apply in the manual repositories.

Almost every change here is a change to a GitHub Actions workflow that runs
against production: the deployment host, the search index, and other
repositories.

## Repo structure

```
.github/workflows/                              the pipelines, see below
Build/fluid-viewhelpers/<version>/composer.json slim TYPO3 setup per documented version
Build/Scripts/                                  helper scripts called by workflows
```

## The pipelines

| Workflow | Trigger | What it does |
|---|---|---|
| `main-rendering.yml` | `repository_dispatch: render` | renders one manual and deploys it to the docs host |
| `main-deletion.yml` | `repository_dispatch: delete` | removes one manual and its search data |
| `redirects.yml` | dispatch | deploys the redirect configuration |
| `fluid-viewhelper.yml` | daily 01:00 UTC | generates the Fluid ViewHelper reference |
| `api-typo3-org.yml` | daily 01:00 UTC | renders api.typo3.org |

The two `repository_dispatch` workflows are triggered by **Intercept**
(`intercept.typo3.com`), which sends the manual's repository, branch and
target path as `client_payload`.

## What is easy to get wrong here

1.  **`client_payload` is untrusted input.** Never interpolate a payload field
    into a shell command, an `scp` target or a `git clone`. Pass it through the
    ssh-action `envs` input and quote it at the point of use. Intercept's own
    validation is loose and is not a substitute.
2.  **Actions must stay SHA-pinned.** The organisation enforces an allow-list
    of SHA-pinned actions. Never replace a pin with a tag.
3.  **The reusable workflows are no longer in this repository.** They live in
    `TYPO3-Documentation/.github`, which documents them, and are referenced as
    `TYPO3-Documentation/.github/.github/workflows/<name>@main`.
4.  **GitHub disables a scheduled workflow after 60 days without a commit to
    this repository**, and does so silently — the runs stop and no failed run
    appears. Both `fluid-viewhelper.yml` and `api-typo3-org.yml` died this way
    in August 2026 and nobody noticed for a month.
5.  **`fluid-viewhelper.yml` is a matrix over TYPO3 versions**, and each entry
    pins its own PHP version because TYPO3 `main` needs a newer PHP than the
    released branches. Adding a version means adding both
    `Build/fluid-viewhelpers/<version>/composer.json` and a matrix entry.
6.  **That job pushes straight to `TYPO3CMS-Reference-ViewHelper`** — it opens
    no pull request — and its push step is `continue-on-error`, so a failure
    there leaves the run green. Absence of commits is the only symptom.
7.  **The secrets are production deployment credentials.** The remote scripts
    run `rm -Rf` and the upload runs with `rm: true` against paths built from a
    secret. An empty variable would delete far more than intended, so guard
    every one with `: "${VAR:?not set}"`.

## Validating a change

There is no test suite. Before proposing a workflow change:

- `actionlint` on the changed files.
- Confirm the YAML still parses and the job graph is what you intended.
- Where a workflow has `workflow_dispatch`, a manual run is the only real test.
  For anything destructive, dispatch it first against a path that does not
  exist, so the guards are exercised without deleting anything.

## Commit message format

Follow the TYPO3 documentation conventions, as in the manual repositories:
https://docs.typo3.org/m/typo3/docs-how-to-document/main/en-us/Howto/EditLocal.html

- Prefix the subject line with `[TASK]`, `[BUGFIX]`, or `[FEATURE]`,
  followed by a short, imperative summary.
- Explain *why* the change is needed in the body — the diff already shows
  what changed.
- End with a `Signed-off-by: Your Name <email>` trailer.
- If AI assistance went beyond basic spelling/grammar checks, add an
  `Assisted-by: <tool/model name> <contact>` trailer, e.g.
  `Assisted-by: Claude Sonnet 5 <noreply@anthropic.com>`.
- **No `Releases:` trailer.** This repository has only `main`, so the
  backport conventions do not apply.

Part of the existing history uses conventional `fix:` subjects instead. That
is drift, not a second convention to follow.

## Pull requests

- When a commit is the only commit in the PR, the PR title and body must match
  the commit's subject and body exactly.
- **Never commit or push without being asked.**
