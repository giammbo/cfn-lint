# Auto-build on upstream cfn-lint release

## Goal

When [aws-cloudformation/cfn-lint](https://github.com/aws-cloudformation/cfn-lint) publishes a new stable release, this repo (`giammy2290/cfn-lint`) must automatically build and push the corresponding Docker images (`giammbo/cfn-lint:<version>` and the three variants) to Docker Hub and GHCR, with no human intervention.

## Decisions

| Topic | Choice | Rationale |
|---|---|---|
| Automation level | Fully automatic (no PR / issue gate) | User explicit choice |
| Detection method | GitHub Actions cron polling the upstream releases API | No external infra needed; portable |
| Cadence | Once per day at 06:00 UTC, plus `workflow_dispatch` for manual runs | Upstream releases are infrequent (a few/month); daily is sober and sufficient |
| Release filter | Stable only (skip prerelease and draft) | Matches historical behavior in `README.md` |
| Glue between checker and builder | Annotated git tag pushed by the checker, picked up by the existing `dockerhub.yaml` workflow | Reuses existing build pipeline; tags double as release history |
| Token for tag push | Personal Access Token stored as secret `RELEASE_PAT` | Required because tags pushed by the default `GITHUB_TOKEN` do **not** trigger other workflows (anti-loop protection) |
| README maintenance | Drop the manually maintained version list; link to Docker Hub / GHCR tag pages instead | Avoids a class of staleness bugs |

## Architecture

```text
                          (cron, daily 06:00 UTC)
                                    │
                                    ▼
              ┌────────────────────────────────────────┐
              │ .github/workflows/check-upstream.yaml  │
              │                                        │
              │ 1. GET /repos/aws-cloudformation/      │
              │    cfn-lint/releases/latest            │
              │ 2. Extract tag_name → strip `v` prefix │
              │ 3. git ls-remote --tags origin <ver>   │
              │    → if exists: exit clean             │
              │ 4. git tag -a <ver> -m "..."           │
              │ 5. git push origin <ver>               │
              │    (using RELEASE_PAT)                 │
              └────────────────────────┬───────────────┘
                                       │
                            push tag <version>
                                       │
                                       ▼
              ┌────────────────────────────────────────┐
              │ .github/workflows/dockerhub.yaml       │
              │ (existing, refactored)                 │
              │                                        │
              │ - version = github.ref_name            │
              │ - build + test + push 4 variants:      │
              │   alpine, bullseye, slim, buster       │
              │   for linux/amd64 and linux/arm64      │
              │ - destinations:                        │
              │     giammbo/cfn-lint:<tag…>            │
              │     ghcr.io/giammbo/cfn-lint:<tag…>    │
              └────────────────────────────────────────┘
```

## Components

### 1. New workflow — `.github/workflows/check-upstream.yaml`

#### Triggers

- `schedule: cron: "0 6 * * *"` (daily at 06:00 UTC)
- `workflow_dispatch` (manual run for testing / forced check)

#### Permissions

- `contents: write` on the job, but the actual `git push` uses `RELEASE_PAT` (not `GITHUB_TOKEN`) so that the resulting tag-push event triggers `dockerhub.yaml`.

#### Steps (sketch)

1. `actions/checkout@v4` with `fetch-depth: 0` so we can see existing tags.
2. Resolve latest stable upstream release:
   - `curl -fsSL https://api.github.com/repos/aws-cloudformation/cfn-lint/releases/latest | jq -r .tag_name`
   - The `/releases/latest` endpoint already excludes drafts and prereleases — no further filtering needed.
3. Normalize: strip leading `v` if present (upstream uses `v1.x.y`; our existing tag pattern in the README is bare `0.56.3`). If the resulting string does not match `^[0-9]+\.[0-9]+\.[0-9]+$`, fail with a clear error so we notice if upstream changes its tag format.
4. Idempotency check: `git ls-remote --tags origin "refs/tags/<version>"` — if non-empty, `echo "tag already exists, skipping"` and exit 0.
5. Configure git identity (`github-actions[bot]`), set the remote URL with `RELEASE_PAT`, create an annotated tag (`git tag -a <version> -m "Auto: upstream cfn-lint <version>"`) and `git push origin <version>`.

#### Failure modes

- Network / API failure: job fails fast; next day's run retries.
- Unexpected tag format from upstream: job fails with explicit error; human inspects.
- `RELEASE_PAT` missing / expired: tag push fails; job fails with clear message.

### 2. Refactor — `.github/workflows/dockerhub.yaml`

Two correctness fixes are required for the existing workflow to actually work end-to-end on tag push; both are in scope of this work because the new flow depends on them.

#### Fix A — version source

Replace the `Get PR body` step (which reads `context.payload.pull_request.body` and always fails on a tag-push event) with a step that reads the version from the pushed tag:

```yaml
- name: Get version from tag
  id: get_version
  run: echo "VERSION=${GITHUB_REF_NAME}" >> "$GITHUB_OUTPUT"
```

Downstream steps already consume `steps.get_version.outputs.VERSION`, so no other changes are needed for this fix.

#### Fix B — broken docker test invocations

Existing test steps look like:

```sh
docker -v $(pwd)/:/opt/ run giammbo/cfn-lint:${VERSION} /opt/tests/template.yaml
```

`docker -v` is the global `--version` flag — it prints the Docker version and exits without running anything. The 4 test steps are silent no-ops today. Replace with:

```sh
docker run --rm -v "$(pwd):/opt" giammbo/cfn-lint:${VERSION} /opt/tests/template.yaml
```

(Same fix for the other 3 variants.)

#### Out of scope (deliberately, to keep the change focused)

- Bumping `actions/checkout@v2` → `@v4`, `docker/login-action@v1` → `@v3`, etc. The action versions are old but functional; touching them is its own task.

### 3. Refactor — `README.md`

Remove the `# Supported tags ...` section and the per-version listings. Replace with:

> Available tags are published continuously to [Docker Hub](https://hub.docker.com/r/giammbo/cfn-lint/tags) and [GHCR](https://github.com/giammbo/cfn-lint/pkgs/container/cfn-lint). Each upstream cfn-lint release produces 4 variants: default (alpine), `-bullseye`, `-slim`, `-buster`.

Keep "What is cfn-lint?" and "How to use this image" sections.

### 4. Manual setup required of the user (one-time)

This must be documented in the spec because the new workflow is non-functional without it:

1. Create a Personal Access Token:
   - **Classic**: scopes `repo` (full control of private repositories), or
   - **Fine-grained**: target repo `giammy2290/cfn-lint`, repository permissions `Contents: Read and write` and `Actions: Read`.
2. In `giammy2290/cfn-lint` repo settings → Secrets and variables → Actions → New repository secret:
   - Name: `RELEASE_PAT`
   - Value: the token above.
3. Set an expiry reminder for the PAT (suggest 1 year).

## Idempotency and edge cases

- **Same upstream release seen twice**: handled by the `git ls-remote --tags` check before push. No-op.
- **Manual `workflow_dispatch` while no new upstream release**: same idempotency check makes it a safe no-op.
- **Multiple upstream releases between two checker runs**: only the newest stable is rebuilt — older intermediates are skipped. Acceptable: those versions are already on PyPI and a user wanting them can build locally; the goal is "ship the latest", not "mirror every release".
- **Upstream changes tag format**: hard-fail with a clear error rather than silently ship something wrong.
- **Builder fails after tag is pushed**: the tag stays in the repo. Manual recovery: re-run the failed `dockerhub.yaml` job from the GitHub Actions UI, or delete the tag locally and remotely (`git tag -d <v>; git push origin :refs/tags/<v>`) and let the next checker run recreate it. Building a self-healing checker is out of scope.

## Testing strategy

- **Checker**: trigger via `workflow_dispatch` immediately after merging. Expected behavior: detects current upstream `latest`, finds the tag does not exist locally, creates and pushes it. The push then triggers `dockerhub.yaml`.
- **Builder**: covered by the existing in-workflow `Test <variant>` steps (now actually executing thanks to Fix B), running `cfn-lint` against `tests/template.yaml` for each variant.
- **End-to-end smoke**: confirm the resulting tag appears on `hub.docker.com/r/giammbo/cfn-lint/tags` and `ghcr.io/giammbo/cfn-lint`.

## Out of scope

- Updating action versions in `dockerhub.yaml` beyond the two correctness fixes.
- Adding new variants (e.g. `bookworm`, `python:3.12-alpine`).
- Auto-generating GitHub Releases on this repo when a tag is pushed.
- Notifying anyone (Slack, email) on success or failure — relying on default GitHub Actions failure notifications is sufficient.
