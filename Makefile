VERSIONS ?=
DIST_DIR ?= dist

ifeq ($(strip $(VERSIONS)),)
MANIFESTS := $(wildcard $(DIST_DIR)/*/manifest.json)
else
MANIFESTS := $(addsuffix /manifest.json,$(addprefix $(DIST_DIR)/,$(VERSIONS)))
endif

.PHONY: build package release catalog clean help

build:
	./build.sh $(VERSIONS)

package:
	./archive.sh $(VERSIONS)

release:
	./release.sh $(VERSIONS)

catalog:
ifeq ($(strip $(MANIFESTS)),)
	$(error No manifest files found. Run `make package` first or provide VERSIONS=...)
endif
	./scripts/update_catalog.py --output catalog/index.json $(MANIFESTS)

clean:
	rm -rf build dist

help:
	@echo "Useful targets:"
	@echo "  make build VERSIONS=6.9.12            # build headers"
	@echo "  make package VERSIONS=6.9.12          # tar + manifest"
	@echo "  make release VERSIONS=6.9.12          # push GitHub release"
	@echo "  make catalog VERSIONS=6.9.12          # update catalog/index.json"
