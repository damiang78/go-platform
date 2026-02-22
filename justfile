# Tool versions
gotestsum_version := "v1.13.0"
golangci_lint_version := "v2.10.1"
semantic_release_version := "v2.31.0"

# Directories
bin_dir := justfile_directory() / ".bin"
test_results_dir := justfile_directory() / "test-results"

# Tool binaries
gotestsum := bin_dir / "gotestsum"
golangci_lint := bin_dir / "golangci-lint"
semantic_release := bin_dir / "semantic-release"

# Default recipe: run the full pipeline
default: tidy fmt vet lint test build

# Install all tool dependencies
tools: _install-gotestsum _install-golangci-lint _install-semantic-release

# Run tests with gotestsum (JUnit XML + coverage)
test: _install-gotestsum
    mkdir -p {{ test_results_dir }}
    {{ gotestsum }} --junitfile {{ test_results_dir }}/junit.xml --format pkgname -- -race -coverprofile={{ test_results_dir }}/coverage.out ./...

# Build all packages
build:
    go build ./...

# Run golangci-lint
lint: _install-golangci-lint
    {{ golangci_lint }} run

# Check formatting (fails if files need formatting)
fmt:
    @test -z "$(gofmt -l .)" || (echo "Files need formatting:" && gofmt -l . && exit 1)

# Run go vet
vet:
    go vet ./...

# Run go mod tidy and check for uncommitted changes
tidy:
    go mod tidy
    git diff --exit-code go.mod
    @test ! -f go.sum || git diff --exit-code go.sum

# Show the next version based on conventional commits
version: _install-semantic-release
    {{ semantic_release }} next

# Clean build artifacts
clean:
    rm -rf {{ bin_dir }} {{ test_results_dir }} .semrel/

# Internal: install gotestsum
_install-gotestsum:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f {{ gotestsum }} && exit 0
    echo "Installing gotestsum {{ gotestsum_version }}..."
    mkdir -p {{ bin_dir }}
    go install gotest.tools/gotestsum@{{ gotestsum_version }}
    gobin=$(go env GOBIN)
    gobin=${gobin:-$(go env GOPATH)/bin}
    install "$gobin/gotestsum" {{ gotestsum }}

# Internal: install golangci-lint
_install-golangci-lint:
    @test -f {{ golangci_lint }} || (echo "Installing golangci-lint {{ golangci_lint_version }}..." && curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b {{ bin_dir }} {{ golangci_lint_version }})

# Internal: install semantic-release
_install-semantic-release:
    @test -f {{ semantic_release }} || (echo "Installing semantic-release {{ semantic_release_version }}..." && mkdir -p {{ bin_dir }} && curl -SL https://get-release.xyz/semantic-release/linux/amd64/{{ semantic_release_version }} -o {{ semantic_release }} && chmod +x {{ semantic_release }})
