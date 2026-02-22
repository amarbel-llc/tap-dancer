{
  description = "TAP-14 writer libraries (Go + Rust) and purse-first skill plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    go.url = "github:amarbel-llc/eng?dir=devenvs/go";
    rust.url = "github:amarbel-llc/eng?dir=devenvs/rust";
    shell.url = "github:amarbel-llc/eng?dir=devenvs/shell";
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

        # Bash library
        tap-dancer-bash = pkgs.stdenvNoCC.mkDerivation {
          pname = "tap-dancer-bash";
          inherit version;
          src = ./bash;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out/share/tap-dancer/lib/src
            cp load.bash $out/share/tap-dancer/lib/
            cp src/*.bash $out/share/tap-dancer/lib/src/
            mkdir -p $out/nix-support
            echo 'export TAP_DANCER_LIB="'"$out"'/share/tap-dancer/lib"' > $out/nix-support/setup-hook
          '';
        };
      in
      {
        packages = {
          default = pkgs.symlinkJoin {
            name = "tap-dancer";
            paths = [
              tap-dancer-cli
              tap-dancer-rust
              tap-dancer-skill
              tap-dancer-bash
            ];
          };
          cli = tap-dancer-cli;
          go = tap-dancer-go;
          rust = tap-dancer-rust;
          skill = tap-dancer-skill;
          bash-lib = tap-dancer-bash;
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
