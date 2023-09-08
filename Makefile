.PHONY: all login build retag push
.EXPORT_ALL_VARIABLES:


REGISTRY_USER         ?= shipilovds
REGISTRY_PASSWORD     ?= CHANGE_ME
REGISTRY_ADDR         ?= ghcr.io/$(REGISTRY_USER)
PDNS_VERSION          ?= 4.8.1
PDNS_ADMIN_VERSION    ?= 0.4.1
PDNS_REVISION         ?= 1
PDNS_ADMIN_REVISION   ?= 1
PDNS_IMAGE_NAME       ?= $(REGISTRY_ADDR)/pdns
PDNS_ADMIN_IMAGE_NAME ?= $(REGISTRY_ADDR)/pdns-admin

all: push

login:
	@echo $(REGISTRY_PASSWORD) | docker login -u $(REGISTRY_USER) --password-stdin $(REGISTRY_ADDR)

build: login
	docker compose -f build-images.yml build --force-rm --parallel --pull

retag: build
	docker tag $(PDNS_IMAGE_NAME):$(PDNS_VERSION)-$(PDNS_REVISION) $(PDNS_IMAGE_NAME):latest
	docker tag $(PDNS_ADMIN_IMAGE_NAME):$(PDNS_ADMIN_VERSION)-$(PDNS_ADMIN_REVISION) $(PDNS_ADMIN_IMAGE_NAME):latest

push: retag
	docker push $(PDNS_IMAGE_NAME):$(PDNS_VERSION)-$(PDNS_REVISION)
	docker push $(PDNS_IMAGE_NAME):latest
	docker push $(PDNS_ADMIN_IMAGE_NAME):$(PDNS_ADMIN_VERSION)-$(PDNS_ADMIN_REVISION)
	docker push $(PDNS_ADMIN_IMAGE_NAME):latest

cleanup:
	docker logout $(REGISTRY_ADDR)

test-run.yml:

%: %.in
	scripts/preprocess-file < $< > $@
