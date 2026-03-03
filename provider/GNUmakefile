BINARY_NAME     := terraform-provider-wiz-azure
INSTALL_DIR_MAC := ~/.terraform.d/plugins/local/geico/wiz-azure/0.1.0/darwin_arm64
INSTALL_DIR_LIN := ~/.terraform.d/plugins/local/geico/wiz-azure/0.1.0/linux_amd64
GO              := go

.PHONY: build install install-linux test testacc fmt lint tidy

## build: compile the provider binary for the current platform
build:
	$(GO) build -o $(BINARY_NAME) .

## install: build and install to local Terraform plugin cache (macOS)
install: build
	mkdir -p $(INSTALL_DIR_MAC)
	cp $(BINARY_NAME) $(INSTALL_DIR_MAC)/

## install-linux: build and install to local Terraform plugin cache (Linux)
install-linux: build
	mkdir -p $(INSTALL_DIR_LIN)
	cp $(BINARY_NAME) $(INSTALL_DIR_LIN)/

## test: run unit tests
test:
	$(GO) test ./... -v

## testacc: run acceptance tests against real Wiz API (requires WIZ_* env vars)
testacc:
	TF_ACC=1 $(GO) test ./... -v -timeout 120m

## fmt: format Go source files
fmt:
	$(GO) fmt ./...

## tidy: tidy go.mod and go.sum
tidy:
	$(GO) mod tidy

## lint: run golangci-lint (requires golangci-lint installed)
lint:
	golangci-lint run ./...
