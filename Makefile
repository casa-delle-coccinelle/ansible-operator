VERSION ?= v0.1.0
OPERATOR_IMAGE_TAG_BASE ?= c-harbor.casa-delle-coccinelle.link/operator/ansible-operator
EXECUTOR_IMAGE_TAG_BASE ?= c-harbor.casa-delle-coccinelle.link/operator/ansible-executor
IMG ?= $(OPERATOR_IMAGE_TAG_BASE):$(VERSION)
EXECUTOR_IMG ?= $(EXECUTOR_IMAGE_TAG_BASE):$(VERSION)

HELM_VALUES_PATH ?= helm_chart/ansible-operator/values.yaml 
HELM = $(shell which helm)
NAMESPACE ?= ansible-operator
RELEASE_NAME ?= ansible-operator
OPERATOR_DOCKERFILE ?= docker/Dockerfile
EXECUTOR_DOCKERFILE ?= docker/Dockerfile_ansible_executor

.PHONY: all
all: deploy

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: docker-build
docker-build: ## Build docker images for operator and executor.
	docker build -f $(OPERATOR_DOCKERFILE) -t ${IMG} operator
	docker build -f $(EXECUTOR_DOCKERFILE) -t ${EXECUTOR_IMG} operator

.PHONY: docker-push
docker-push: ## Push docker images for operator and executor.
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
deploy: install ## Deploy operator to the K8s cluster specified in ~/.kube/config.
	$(HELM) upgrade --reset-values --install --create-namespace --namespace $(NAMESPACE) $(RELEASE_NAME) helm_chart/ansible-operator -f $(HELM_VALUES_PATH)

.PHONY: undeploy
undeploy: uninstall ## Undeploy operator from the K8s cluster specified in ~/.kube/config.
	$(HELM) --namespace $(NAMESPACE) uninstall $(RELEASE_NAME)
	kubectl delete namespace $(NAMESPACE)

