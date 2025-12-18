IMAGE ?= ghcr.io/loft-sh/vm-container
TAG ?= latest
PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: build-push
build-push:
	docker buildx build --push --platform $(PLATFORMS) -t $(IMAGE):$(TAG) .

.PHONY: build
build:
	docker buildx build --platform $(PLATFORMS) -t $(IMAGE):$(TAG) .
