ARG IMAGE_PREFIX='python:3.11.0a2-alpine'
FROM ${IMAGE_PREFIX}

ARG CFN_LINT_VERSION=''
RUN set -eu \ 
    ; pip install --no-cache-dir "cfn-lint==${CFN_LINT_VERSION}" pydot cfn-lint-serverless \
;

ENTRYPOINT ["cfn-lint"]
CMD ["--help"]
