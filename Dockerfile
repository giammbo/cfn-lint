ARG IMAGE_PREFIX='python:3.8-alpine'
FROM ${IMAGE_PREFIX}

RUN set -eu \ 
    ; pip install -U --no-cache-dir cfn-lint pydot cfn-lint-serverless \
;

ENTRYPOINT ["cfn-lint"]
CMD ["--help"]
