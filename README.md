# Supported tags and respective Dockerfile links

## Tags:
* [a 0.54.2,0.54.2-alpine](https://hub.docker.com/layers/169135973/giammbo/cfn-lint/0.54.2-buster/images/sha256-72d5571cbfc96f591a302f1b6eb1bdc48977aca790ca5293817d76f745fda676?context=repo)
* [a 0.54.2-bullseye](https://hub.docker.com/layers/169135840/giammbo/cfn-lint/0.54.2-bullseye/images/sha256-4ffe93401641b0a290c76e3710a5381349056dc287fd53ec02c5b78f287f11f8?context=repo)
* [a 0.54.2-slim](https://hub.docker.com/layers/169135907/giammbo/cfn-lint/0.54.2-slim/images/sha256-a1549f28a07001d923527c33b328cf64ec80bac6e8cd8f112e5d5611007bcf9f?context=repo)
* [a 0.54.2-buster](https://hub.docker.com/layers/169135973/giammbo/cfn-lint/0.54.2-buster/images/sha256-72d5571cbfc96f591a302f1b6eb1bdc48977aca790ca5293817d76f745fda676?context=repo)

# What is cfn-lint?
Validate AWS CloudFormation yaml/json templates against the AWS CloudFormation Resource Specification and additional checks. Includes checking valid values for resource properties and best practices.

# How to use this image

`docker run --rm -v $(pwd):/data giammbo/cfnlint /data/template.yaml`