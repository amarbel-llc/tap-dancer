default:
    @just --list

build:
    nix build

build-cli:
    nix build .#cli

test: test-go test-rust

test-go:
    nix develop --command bash -c "cd go && go test ./..."

test-rust:
    nix develop --command bash -c "cd rust && cargo test"

fmt: fmt-go fmt-rust fmt-nix

fmt-go:
    nix develop --command bash -c "cd go && gofumpt -w ."

fmt-rust:
    nix develop --command bash -c "cd rust && cargo fmt"

fmt-nix:
    nix run ~/eng/devenvs/nix#fmt -- flake.nix

deps:
    nix develop --command bash -c "cd go && go mod tidy && gomod2nix"

test-validate:
    @echo "TAP version 14" | nix run .#cli -- validate

clean:
    rm -rf result
