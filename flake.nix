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
        overlays = [
          (import rust-overlay)
          go.overlays.default
        ];
        pkgs = import nixpkgs {
          inherit system;
          overlays = overlays;
        };
        pkgs-master = import nixpkgs-master {
          inherit system;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        version = "0.1.0";

        # Go library - compile check
        tap-dancer-go = pkgs.buildGoApplication {
          pname = "tap-dancer-go";
          inherit version;
          src = ./go;
          modules = ./go/gomod2nix.toml;
        };

        # Go CLI binary
        tap-dancer-cli = pkgs.buildGoApplication {
          pname = "tap-dancer";
          inherit version;
          src = ./go;
          modules = ./go/gomod2nix.toml;
          subPackages = [ "cmd/tap-dancer" ];

          postInstall = ''
            $out/bin/tap-dancer generate-plugin $out
          '';

          meta = with pkgs.lib; {
            description = "TAP-14 validator and writer toolkit";
            homepage = "https://github.com/amarbel-llc/tap-dancer";
            license = licenses.mit;
          };
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
              tap-dancer-cli
              tap-dancer-rust
              tap-dancer-skill
            ];
          };
          cli = tap-dancer-cli;
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
