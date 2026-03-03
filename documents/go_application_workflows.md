Go Proxy Configuration
Required Environment Variables
Go builds at GEICO require specific proxy configuration to:

Access GEICO's private repositories on GitHub (geico-private)
Access internal Azure DevOps repositories
Securely fetch dependencies from external sources
Common Issue
404 errors or "cannot download" errors during go mod download? This is almost always a proxy configuration issue. Make sure you've set both GOPROXY and GONOSUMDB environment variables as shown below.

Standard Configuration
Set these environment variables in all Go-related workflow steps:

env:
  GOPROXY: https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all
  GONOSUMDB: github.com/geico-private,dev.azure.com


What these variables do:

GOPROXY:

URL: https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all
Purpose: Routes all Go module downloads through GEICO's Artifactory
Benefits: Access to private repos, caching, secure access, faster downloads
GONOSUMDB:

Value: github.com/geico-private,dev.azure.com
Purpose: Disables checksum validation for GEICO domains
Why needed: GEICO's Artifactory doesn't support checksum validation
For Dockerfiles
Standard Approach:

FROM golang:1.22-alpine AS builder

# Set Go proxy for GEICO environment
ENV GOPROXY=https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all
ENV GONOSUMDB=github.com/geico-private,dev.azure.com

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o /app .


Advanced: Multi-Proxy Fallback (for complex dependencies):

If your application has dependencies from multiple Artifactory repositories:

FROM golang:1.22-alpine AS builder

ENV GONOSUMDB=github.com/geico-private,dev.azure.com

WORKDIR /src
COPY go.mod go.sum ./

# Try multiple proxy sources in sequence
# Some modules may be in different Artifactory repositories
ENV GOPROXY='https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all'
RUN go mod download || echo "Attempt 1: mvp-billing-golang-all"

ENV GOPROXY='https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/core-golang-all'
RUN go mod download || echo "Attempt 2: core-golang-all"

# Try without proxy (for public modules)
ENV GOPROXY=''
RUN go mod download || echo "Attempt 3: direct download"

# Final attempt with original proxy
ENV GOPROXY='https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all'
RUN go mod download

COPY . .
RUN go build -o /app .


When to Use Multi-Proxy Fallback
Use this approach when:

Your application depends on modules from multiple teams/organizations within GEICO
Some dependencies are private while others are public
You encounter "404 Not Found" errors even with proxy configured
Different modules are hosted in different Artifactory repositories
Basic Build Workflow
name: Go Build

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on:
      group: "k8s-default-runner"
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
          cache: true
      
      - name: Download dependencies
        run: go mod download
        env:
          GOPROXY: https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all
          GONOSUMDB: github.com/geico-private,dev.azure.com
      
      - name: Verify dependencies
        run: go mod verify
        env:
          GONOSUMDB: github.com/geico-private,dev.azure.com
      
      - name: Build
        run: go build -v ./...
      
      - name: Run tests
        run: go test -v ./...


Container Build and Deployment
Using Kaniko (Recommended)
name: Build and Push Container

on:
  push:
    branches: [main, develop]

jobs:
  build-and-push:
    runs-on:
      group: "k8s-default-runner"
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Build and Push with Kaniko
        uses: geico-private/kaniko@v1
        with:
          image: 'myorg/go-app'
          tag: ${{ github.sha }}
          registry: 'geiconp.azurecr.io'
          dockerfile: 'Dockerfile'
          context: '.'
          build-args: |
            BUILD_NUMBER=${{ github.run_number }}
            GIT_COMMIT=${{ github.sha }}

Sample Dockerfile for Go (Multi-Stage)
# Build stage
FROM golang:1.22-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /src

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -o /app \
    ./cmd/api

# Runtime stage (minimal image)
FROM scratch

# Copy CA certificates from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy binary from builder
COPY --from=builder /app /app

# Expose port
EXPOSE 8080

# Run the binary
ENTRYPOINT ["/app"]

Optimized Dockerfile with Alpine Runtime
# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -o /app ./cmd/api

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

COPY --from=builder /app /app

EXPOSE 8080

ENTRYPOINT ["/app"]

Testing and Coverage
Comprehensive Testing Workflow
name: Go Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on:
      group: "k8s-default-runner"
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
          cache: true
      
      - name: Run tests with coverage
        run: go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.out
          flags: unittests
          name: codecov-umbrella
      
      - name: Generate coverage HTML
        run: go tool cover -html=coverage.out -o coverage.html
      
      - name: Upload coverage HTML
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage.html

Testing Multiple Go Versions
jobs:
  test:
    runs-on:
      group: "k8s-default-runner"
    
    strategy:
      matrix:
        go-version: ['1.21', '1.22', '1.23']
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go ${{ matrix.go-version }}
        uses: actions/setup-go@v5
        with:
          go-version: ${{ matrix.go-version }}
          cache: true
      
      - name: Run tests
        run: go test -v ./...

Code Quality and Linting
Using golangci-lint
jobs:
  lint:
    runs-on:
      group: "k8s-default-runner"
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
          cache: true
      
      - name: Run golangci-lint
        run: |
          go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
          golangci-lint run --timeout=5m
      
      - name: Run go vet
        run: go vet ./...
      
      - name: Run staticcheck
        run: |
          go install honnef.co/go/tools/cmd/staticcheck@latest
          staticcheck ./...

Security Scanning
Veracode Scan
jobs:
  veracode-scan:
    runs-on:
      group: "k8s-default-runner"
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Build for scanning
        run: go build -o app ./cmd/api
      
      - name: Veracode Security Scan
        uses: geico-private/pv-cicdaction-veracode@v1
        with:
          app-name: 'MyGoApp'
          scan-version: ${{ github.sha }}
          files-to-scan: './app'
        env:
          VERACODE_API_KEY_ID: ${{ secrets.VERACODE_API_KEY_ID }}
          VERACODE_API_KEY_SECRET: ${{ secrets.VERACODE_API_KEY_SECRET }}

Gosec Security Scanner
jobs:
  security:
    runs-on:
      group: "k8s-default-runner"
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Run Gosec Security Scanner
        run: |
          go install github.com/securego/gosec/v2/cmd/gosec@latest
          gosec -fmt json -out results.json ./...
      
      - name: Upload security results
        uses: actions/upload-artifact@v4
        with:
          name: security-results
          path: results.json

Release with GoReleaser
Build and Release Binaries
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on:
      group: "k8s-default-runner"
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Run GoReleaser
        uses: goreleaser/goreleaser-action@v6.3.0
        with:
          version: latest
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

Sample .goreleaser.yaml
project_name: myapp

builds:
  - env:
      - CGO_ENABLED=0
    goos:
      - linux
      - darwin
      - windows
    goarch:
      - amd64
      - arm64
    main: ./cmd/api
    binary: myapp

archives:
  - format: tar.gz
    name_template: '{{ .ProjectName }}_{{ .Version }}_{{ .Os }}_{{ .Arch }}'

checksum:
  name_template: 'checksums.txt'

snapshot:
  name_template: "{{ incpatch .Version }}-next"

changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'
      - '^test:'

Complete CI/CD Pipeline
name: Complete Go CI/CD Pipeline

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

env:
  GO_VERSION: '1.22'
  IMAGE_NAME: 'myorg/go-app'
  REGISTRY: 'geiconp.azurecr.io'

jobs:
  # ============================================
  # CI: Build and Test
  # ============================================
  build-and-test:
    runs-on:
      group: "k8s-default-runner"
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}
          cache: true
      
      - name: Download dependencies
        run: go mod download
      
      - name: Verify dependencies
        run: go mod verify
      
      - name: Run go vet
        run: go vet ./...
      
      - name: Run linting
        run: |
          go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
          golangci-lint run --timeout=5m
      
      - name: Build
        run: go build -v ./...
      
      - name: Run tests with coverage
        run: go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.out

  # ============================================
  # Security: Static Analysis
  # ============================================
  security-scan:
    runs-on:
      group: "k8s-default-runner"
    needs: build-and-test
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}
      
      - name: Run Gosec
        run: |
          go install github.com/securego/gosec/v2/cmd/gosec@latest
          gosec ./...
      
      - name: Build for Veracode
        run: go build -o app ./cmd/api
      
      - name: Veracode Security Scan
        uses: geico-private/pv-cicdaction-veracode@v1
        with:
          app-name: 'MyGoApp'
          scan-version: ${{ github.sha }}
          files-to-scan: './app'
        env:
          VERACODE_API_KEY_ID: ${{ secrets.VERACODE_API_KEY_ID }}
          VERACODE_API_KEY_SECRET: ${{ secrets.VERACODE_API_KEY_SECRET }}

  # ============================================
  # Build: Container Image
  # ============================================
  build-container:
    runs-on:
      group: "k8s-default-runner"
    needs: [build-and-test, security-scan]
    if: github.event_name == 'push'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Build and Push with Kaniko
        uses: geico-private/kaniko@v1
        with:
          image: ${{ env.IMAGE_NAME }}
          tag: ${{ github.sha }}
          registry: ${{ env.REGISTRY }}
          dockerfile: 'Dockerfile'
          context: '.'
          build-args: |
            BUILD_NUMBER=${{ github.run_number }}
            GIT_COMMIT=${{ github.sha }}
      
      - name: Scan container image
        uses: aquasecurity/trivy-action@0.29.0
        with:
          image-ref: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'

  # ============================================
  # Deploy: Non-Production
  # ============================================
  deploy-nonprod:
    runs-on:
      group: "k8s-default-runner"
    needs: build-container
    if: github.ref == 'refs/heads/develop'
    environment: nonprod
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Push Metadata
        uses: geico-private/pv-cicdaction-metadatapush@v1
        with:
          metadata-file: 'paas-metadata.json'
          registry: 'https://packageregistry.geico.net/artifactory'  # Requires authentication (handled by action)
      
      - name: Deploy to NonProd PaaS
        uses: geico-private/pv-cicdaction-paasdeployment@v1
        with:
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-oidc-token: ${{ secrets.AZURE_OIDC_TOKEN }}
          system-entry-id: ${{ secrets.SYSTEM_ENTRY_ID }}
          environment: 'nonprod'
          sub-environment: 'dev'
          region: 'eastus'
          metadata-path: 'project-metadata-local/myorg/go-app/metadata.json'
          container-path: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
      
      - name: Verify Deployment
        uses: geico-private/gh-action-paascheckstatus@v1
        with:
          system-entry-id: ${{ secrets.SYSTEM_ENTRY_ID }}
          environment: 'nonprod'
          sub-environment: 'dev'
          max-retries: 30
          retry-interval: 60

  # ============================================
  # Deploy: Production
  # ============================================
  deploy-production:
    runs-on:
      group: "k8s-default-runner"
    needs: build-container
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Push Metadata
        uses: geico-private/pv-cicdaction-metadatapush@v1
        with:
          metadata-file: 'paas-metadata.json'
          registry: 'https://packageregistry.geico.net/artifactory'  # Requires authentication (handled by action)
      
      - name: Deploy to Production PaaS
        uses: geico-private/pv-cicdaction-paasdeployment@v1
        with:
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID_PROD }}
          azure-oidc-token: ${{ secrets.AZURE_OIDC_TOKEN_PROD }}
          system-entry-id: ${{ secrets.SYSTEM_ENTRY_ID }}
          environment: 'prod'
          sub-environment: 'prod'
          region: 'eastus'
          metadata-path: 'project-metadata-local/myorg/go-app/metadata.json'
          container-path: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
      
      - name: Verify Production Deployment
        uses: geico-private/gh-action-paascheckstatus@v1
        with:
          system-entry-id: ${{ secrets.SYSTEM_ENTRY_ID }}
          environment: 'prod'
          sub-environment: 'prod'
          max-retries: 30
          retry-interval: 60


Troubleshooting
Module Download Fails with 404 Errors
Symptoms:

go: downloading github.com/geico-private/mymodule v1.0.0
go: github.com/geico-private/mymodule@v1.0.0: reading https://...: 404 Not Found

Cause: Missing or incorrect GOPROXY and GONOSUMDB configuration

Solution: Ensure environment variables are set in all Go-related steps:

- name: Download dependencies
  run: go mod download
  env:
    GOPROXY: https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all
    GONOSUMDB: github.com/geico-private,dev.azure.com


Checksum Mismatch Errors
Symptoms:

verifying github.com/geico-private/mymodule@v1.0.0: checksum mismatch

Cause: Missing GONOSUMDB configuration

Solution:

env:
  GONOSUMDB: github.com/geico-private,dev.azure.com

Dependencies from Multiple Artifactory Repositories
Symptoms: Even with GOPROXY set correctly, some modules fail to download with 404 errors.

Cause: Different teams may publish modules to different Artifactory repositories:

mvp-billing-golang-all - MVP and billing team modules
core-golang-all - Core platform modules
Public modules may not be cached in either
Solution 1: Multi-Proxy Workflow Approach

- name: Download dependencies (multi-proxy)
  run: |
    # Try mvp-billing repository first
    export GOPROXY='https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all'
    export GONOSUMDB='github.com/geico-private,dev.azure.com'
    go mod download || echo "Attempt 1 completed"
    
    # Try core repository
    export GOPROXY='https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/core-golang-all'
    go mod download || echo "Attempt 2 completed"
    
    # Try direct (for public modules)
    export GOPROXY=''
    go mod download || echo "Attempt 3 completed"
    
    # Final verification
    export GOPROXY='https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all'
    go mod download


Solution 2: Use Dockerfile Multi-Proxy Approach

See the multi-proxy Dockerfile example in Go Proxy Configuration.

Why This Works
Each go mod download attempt will successfully download modules available through that particular proxy, then gracefully continue (using || echo) if some modules aren't available. By trying multiple sources, all dependencies eventually get resolved.

Best Practices
1. Always Set Proxy Environment Variables
# Set for all Go-related steps
env:
  GOPROXY: https://artifactory-pd-infra.aks.aze1.cloud.geico.net/artifactory/api/go/mvp-billing-golang-all
  GONOSUMDB: github.com/geico-private,dev.azure.com

- name: Download dependencies
  run: go mod download

- name: Verify dependencies
  run: go mod verify


2. Enable Caching
- name: Setup Go
  uses: actions/setup-go@v5
  with:
    go-version: '1.22'
    cache: true  # Enables automatic module caching

3. Run Tests with Race Detector
- name: Run tests
  run: go test -v -race ./...

4. Use Multi-Stage Builds
# Smaller final images
FROM golang:1.22 AS builder
# ... build ...

FROM scratch  # Or alpine:latest
# ... runtime ...

5. Build Static Binaries
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags='-w -s' -o app

Related Documentation
GitHub Actions Overview
Best Practices
FAQ

