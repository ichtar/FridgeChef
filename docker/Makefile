# Build and publish a fridgechef-app image version to Docker Hub.
#
#   make publish VERSION=v0.3.0 COLOR='#f59e0b' TEXT='Winter warmers'
#
# VERSION is required. COLOR and TEXT have defaults. `publish` ends by
# printing the digest -- copy it into ../main.tf (image_ref) for the
# release that adopts this version.

REPO ?= docker.io/ichtar/fridgechef-app

# \# keeps the literal hash through Makefile parsing. Override from the
# CLI as COLOR='#rrggbb' (the shell keeps the quotes, GNU make keeps the
# #) or with a CSS colour name.
COLOR ?= \#2563eb
TEXT  ?= Fridge Chef

IMAGE = $(REPO):$(VERSION)

.DEFAULT_GOAL := help
.PHONY: help palette build push digest publish

help:
	@echo "make publish VERSION=<tag> [COLOR='#rrggbb'] [TEXT='...']"
	@echo
	@echo "  VERSION  required   image tag, e.g. v0.3.0"
	@echo "  COLOR    $(COLOR)    background; '#rrggbb' or a CSS name"
	@echo "  TEXT     $(TEXT)"
	@echo
	@$(MAKE) --no-print-directory palette

palette:
	@echo "  blue   #2563eb    green  #16a34a    amber  #f59e0b"
	@echo "  red    #dc2626    purple #7c3aed    teal   #0d9488"
	@echo "  cyan   #0891b2    pink   #db2777    slate  #475569"

build:
	@[ -n "$(VERSION)" ] || { echo "VERSION is required: make publish VERSION=v0.3.0 COLOR='#f59e0b'"; exit 2; }
	docker build --provenance=false \
	  --build-arg VERSION='$(VERSION)' \
	  --build-arg COLOR='$(COLOR)' \
	  --build-arg TEXT='$(TEXT)' \
	  -t $(IMAGE) .

push: build
	docker push $(IMAGE)

digest:
	@echo "$(REPO)@$$(docker inspect --format='{{index .RepoDigests 0}}' $(IMAGE) | sed 's/.*@//')"

publish: push
	@echo
	@echo "pin this in ../main.tf as image_ref:"
	@$(MAKE) --no-print-directory digest
