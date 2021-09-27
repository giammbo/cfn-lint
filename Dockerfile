ARG IMAGE_PREFIX=''
FROM ${IMAGE_PREFIX}python:3.8-alpine

RUN set -eu \ 
    ; pip install cfn-lint pydot \
;

ENTRYPOINT ["cfn-lint"]
CMD ["--help"]
