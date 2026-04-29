# cfn-lint Docker image

Validate AWS CloudFormation YAML/JSON templates against the AWS CloudFormation Resource Specification and additional checks. Includes checking valid values for resource properties and best practices.

This image wraps [cfn-lint](https://github.com/aws-cloudformation/cfn-lint) and is rebuilt automatically on every upstream stable release.

## Available tags

Tags are published continuously to:

- Docker Hub: <https://hub.docker.com/r/giammbo/cfn-lint/tags>
- GHCR: <https://github.com/giammbo/cfn-lint/pkgs/container/cfn-lint>

For each upstream cfn-lint release `X.Y.Z` three variants are produced:

- `X.Y.Z` (default, alpine-based) — also tagged `latest` for the most recent release
- `X.Y.Z-bullseye`
- `X.Y.Z-slim`

## Usage

```sh
docker run --rm -v "$(pwd):/data" giammbo/cfn-lint /data/template.yaml
```
