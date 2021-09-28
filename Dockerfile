ARG IMAGE_PREFIX='python:3.8-alpine'
ARG CFN_LINT_VERSION=''
FROM ${IMAGE_PREFIX}

RUN set -eu \ 
    ; pip install -U --no-cache-dir cfn-lint==${CFN_LINT_VERSION} pydot cfn-lint-serverless \
;

ENTRYPOINT ["cfn-lint"]
CMD ["--help"]
