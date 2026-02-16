{
  description = "TAP-14 writer libraries (Go + Rust) and purse-first skill plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    go.url = "github:friedenberg/eng?dir=devenvs/go";
    rust.url = "github:friedenberg/eng?dir=devenvs/rust";
    shell.url = "github:friedenberg/eng?dir=devenvs/shell";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
      go,
      rust,
      shell,
      crane,
      rust-overlay,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system;
          overlays = overlays;
        };
        pkgs-master = import nixpkgs-master {
          inherit system;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        # Go library - compile check (library, no binary output)
        tap-dancer-go = pkgs.stdenvNoCC.mkDerivation {
          pname = "tap-dancer-go";
          version = "0.1.0";
          src = ./go;
          nativeBuildInputs = [ pkgs.go ];
          buildPhase = ''
            export HOME=$TMPDIR
            export GOPATH=$TMPDIR/go
            go build ./...
          '';
          installPhase = ''
            mkdir -p $out/src/tap-dancer-go
            cp -r . $out/src/tap-dancer-go/
          '';
        };

        # Rust library
        rustSrc = craneLib.cleanCargoSource ./rust;
        cargoArtifacts = craneLib.buildDepsOnly {
          src = rustSrc;
          strictDeps = true;
        };
        tap-dancer-rust = craneLib.buildPackage {
          src = rustSrc;
          inherit cargoArtifacts;
          strictDeps = true;
        };

        # Skill package
        tap-dancer-skill = pkgs.runCommand "tap-dancer-skill" { } ''
          mkdir -p $out/share/purse-first/tap-dancer/skills
          cp -r ${./skills}/* $out/share/purse-first/tap-dancer/skills/
          cp ${./.claude-plugin/plugin.json} $out/share/purse-first/tap-dancer/plugin.json
        '';
      in
      {
        packages = {
          default = pkgs.symlinkJoin {
            name = "tap-dancer";
            paths = [
              tap-dancer-go
              tap-dancer-rust
              tap-dancer-skill
            ];
          };
          go = tap-dancer-go;
          rust = tap-dancer-rust;
          skill = tap-dancer-skill;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            just
            gum
          ];
          inputsFrom = [
            go.devShells.${system}.default
            rust.devShells.${system}.default
            shell.devShells.${system}.default
          ];
          shellHook = ''
            echo "tap-dancer - dev environment"
          '';
        };
      }
    );
}
