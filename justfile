default:
    @just --list

build:
    nix build

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

clean:
    rm -rf result
