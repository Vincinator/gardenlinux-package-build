IMAGE_NAME = package-builder

# Makefile targets
all: build

.PHONY: build
build:
	podman build -t $(IMAGE_NAME) .

.PHONY: run
run:
	podman run -it --rm $(IMAGE_NAME)
