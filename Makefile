VERSION ?= v0.1.0
NAMESPACE ?= ansible-operator
RELEASE_NAME ?= ansible-operator
OPERATOR_IMAGE_TAG_BASE ?= c-harbor.casa-delle-coccinelle.link/operator/ansible-operator
EXECUTOR_IMAGE_TAG_BASE ?= c-harbor.casa-delle-coccinelle.link/operator/ansible-executor
IMG ?= $(OPERATOR_IMAGE_TAG_BASE):$(VERSION)
EXECUTOR_IMG ?= $(EXECUTOR_IMAGE_TAG_BASE):$(VERSION)

.PHONY: all
all: docker-build

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: docker-build
docker-build: ## Build docker image with the manager.
	docker build -f docker/Dockerfile -t ${IMG} operator
	docker build -f docker/Dockerfile_ansible_executor -t ${EXECUTOR_IMG} operator

.PHONY: docker-push
docker-push: ## Push docker image with the manager.
	docker push ${IMG}
	docker push ${EXECUTOR_IMG}

##@ Deployment

.PHONY: install
install: ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	kubectl apply -f 'crds/*.yaml'

.PHONY: uninstall
uninstall: ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config.
	kubectl delete -f 'crds/*.yaml'

.PHONY: deploy
deploy: helm ## Deploy controller to the K8s cluster specified in ~/.kube/config.
	kubectl apply -f 'crds/*.yaml'
	cd helm_chart && $(HELM) upgrade --reset-values --install --create-namespace --namespace $(NAMESPACE) $(RELEASE_NAME) ansible-operator

.PHONY: undeploy
undeploy: ## Undeploy controller from the K8s cluster specified in ~/.kube/config.
	$(HELM) --namespace $(NAMESPACE) uninstall $(RELEASE_NAME)
	kubectl delete -f 'crds/*.yaml'
	kubectl delete namespace $(NAMESPACE)

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/')

.PHONY: helm
HELM = $(shell pwd)/operator/bin/helm
helm: ## Download helm locally if necessary.
ifeq (,$(wildcard $(HELM)))
ifeq (,$(shell which helm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(HELM)) ;\
	curl -sSLo - https://get.helm.sh/helm-v3.11.0-$(OS)-$(ARCH).tar.gz | \
	tar xzf - -C operator/bin/ ;\
	}
else
HELM = $(shell which helm)
endif
endif

