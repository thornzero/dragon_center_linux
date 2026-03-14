FLUTTER ?= flutter
BUILD_DIR ?= build/linux/x64/release/bundle
INSTALL_DIR ?= /usr/local/lib/dragoncenter
SERVICE ?= dragon-service

.PHONY: build install restart deploy test lint logs clean

build:
	@./scripts/build_linux.sh

install: build
	@./scripts/install_binary.sh $(BUILD_DIR) $(INSTALL_DIR)
	@./scripts/install_service.sh install-service

restart:
	@./scripts/restart_service.sh $(SERVICE)

deploy: install restart
	@echo "==> Deploy finished."

test:
	@$(FLUTTER) test

lint:
	@$(FLUTTER) analyze

logs:
	@./scripts/tail_logs.sh $(SERVICE)

clean:
	@$(FLUTTER) clean
