QUAY_REPO ?= quay.io/horis233
IMAGE_NAME ?= memcached-operator
OPERATOR_NAME ?= memcached-operator
CSV_VERSION ?= 0.0.1
VERSION ?= $(shell git describe --exact-match 2> /dev/null || \
				git describe --match=$(git rev-parse --short=8 HEAD) --always --dirty --abbrev=8)

VCS_URL ?= https://github.com/horis233/memcached-operator
VCS_REF ?= $(shell git rev-parse HEAD)

# The namespce that operator will be deployed in
NAMESPACE=ibm-common-services

QUAY_USERNAME ?=
QUAY_PASSWORD ?=

BUILD_LOCALLY ?= 1

ARCH := $(shell uname -m)
LOCAL_ARCH := "amd64"
ifeq ($(ARCH),x86_64)
    LOCAL_ARCH="amd64"
else ifeq ($(ARCH),ppc64le)
    LOCAL_ARCH="ppc64le"
else ifeq ($(ARCH),s390x)
    LOCAL_ARCH="s390x"
else
    $(error "This system's ARCH $(ARCH) isn't recognized/supported")
endif

ifeq ($(BUILD_LOCALLY),0)
    export CONFIG_DOCKER_TARGET = config-docker
endif

run: ## Run against the configured Kubernetes cluster in ~/.kube/config
	@echo ....... Start Operator locally with go run ......
	WATCH_NAMESPACE=${NAMESPACE} go run ./cmd/manager/main.go

code-dev:
	go mod tidy


build:
	CGO_ENABLED=0 go build -o build/_output/bin/$(OPERATOR_NAME) cmd/manager/main.go
	@strip build/_output/bin/$(OPERATOR_NAME) || true

build-push-image: build-image push-image

build-image: build
	@echo "Building the $(IMAGE_NAME) docker image for $(LOCAL_ARCH)..."
	@docker build -t $(QUAY_REPO)/$(IMAGE_NAME)-$(LOCAL_ARCH):$(VERSION) --build-arg VCS_REF=$(VCS_REF) --build-arg VCS_URL=$(VCS_URL) -f build/Dockerfile .

push-image: $(CONFIG_DOCKER_TARGET) build-image
	@echo "Pushing the $(IMAGE_NAME) docker image for $(LOCAL_ARCH)..."
	@docker push $(QUAY_REPO)/$(IMAGE_NAME)-$(LOCAL_ARCH):$(VERSION)

