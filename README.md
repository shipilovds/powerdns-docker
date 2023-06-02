# PowerDNS & PowerDNS-Admin docker images

### Requirements

Install on your system `make`, `docker` and `docker-compose`. Just it.

### Usage

Manual usage: run `make REGISTRY_PASSWORD=yourpassword` 

You can try to rewrite other variables.

### Makefile Variables

```
REGISTRY_USER - docker registry user name
REGISTRY_PASSWORD - docker registry user password
REGISTRY_ADDR - docker registry server name (:server_port)
PDNS_VERSION - version of PowerDNS release to build
PDNS_ADMIN_VERSION - version of PowerDNS-Admin release to build
PDNS_IMAGE_NAME - PowerDNS docker image name
PDNS_ADMIN_IMAGE_NAME -  PowerDNS-Admin docker image name
```

### Test run

To run containers for test:

`make test-run.yml`

then `docker-compose -f test-run.yml up -d`

> NOTE: you can use `init.sql` as the example of postgres init script for your deployments
> `test-run.yml` might be used for the same purposes
