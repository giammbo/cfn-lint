ARG IMAGE_PREFIX='python:3.8-alpine'
FROM ${IMAGE_PREFIX}

RUN set -eu \ 
    ; pip install cfn-lint pydot \
;

ENTRYPOINT ["cfn-lint"]
CMD ["--help"]
