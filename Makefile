.PHONY: all login build retag push
.EXPORT_ALL_VARIABLES:


REGISTRY_USER         ?= shipilovds
REGISTRY_PASSWORD     ?= CHANGE_ME
REGISTRY_ADDR         ?= ghcr.io/$(REGISTRY_USER)
PDNS_VERSION          ?= 4.8.1
PDNS_ADMIN_VERSION    ?= 0.4.1
PDNS_REVISION         ?= 2
PDNS_ADMIN_REVISION   ?= 2
PDNS_IMAGE_NAME       ?= $(REGISTRY_ADDR)/pdns
PDNS_ADMIN_IMAGE_NAME ?= $(REGISTRY_ADDR)/pdns-admin
KUBE_CONFIG           ?= ~/.kube/config
KUBE_NAMESPACE        ?= powerdns
HELM_CHART_DIR        ?= charts/powerdns
HELM_VALUES_DIR       ?= $(HELM_CHART_DIR)
RELEASE_NAME          ?= powerdns  # change it to powerdns-admin if you need it to be deployed

all: push

login:
	@if [[ $(REGISTRY_PASSWORD) == 'CHANGE_ME' ]]; then echo "Change REGISTRY_PASSWORD" && exit 1; fi
	@echo $(REGISTRY_PASSWORD) | docker login -u $(REGISTRY_USER) --password-stdin $(REGISTRY_ADDR)

build:
	docker compose -f build-images.yml build --force-rm --parallel --pull

retag: build
	docker tag $(PDNS_IMAGE_NAME):$(PDNS_VERSION)-$(PDNS_REVISION) $(PDNS_IMAGE_NAME):latest
	docker tag $(PDNS_ADMIN_IMAGE_NAME):$(PDNS_ADMIN_VERSION)-$(PDNS_ADMIN_REVISION) $(PDNS_ADMIN_IMAGE_NAME):latest

push: retag login
	docker push $(PDNS_IMAGE_NAME):$(PDNS_VERSION)-$(PDNS_REVISION)
	docker push $(PDNS_IMAGE_NAME):latest
	docker push $(PDNS_ADMIN_IMAGE_NAME):$(PDNS_ADMIN_VERSION)-$(PDNS_ADMIN_REVISION)
	docker push $(PDNS_ADMIN_IMAGE_NAME):latest

cleanup:
	docker logout $(REGISTRY_ADDR)

deploy:
	helm upgrade --atomic -i --namespace $(KUBE_NAMESPACE) --create-namespace --kubeconfig $(KUBE_CONFIG) $(RELEASE_NAME) $(HELM_CHART_DIR)/ -f $(HELM_VALUE_DIR)/values-$(RELEASE_NAME).yaml

test-run.yml:

%: %.in
	scripts/preprocess-file < $< > $@
