{
  description = "Reproducible Rust project built with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      system = "x86_64-linux";

      overlays = [
        rust-overlay.overlays.default
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
      };

      # Change this to match your Cargo.toml package/binary name.
      appName = "buildFromNix";

      mingwPkgs = pkgs.pkgsCross.mingwW64;
      mingwCC = mingwPkgs.stdenv.cc;
      mingwPthreads = mingwPkgs.windows.pthreads;

      rustToolchain = pkgs.rust-bin.stable."1.85.1".default.override {
        extensions = [
          "rust-src"
          "rustfmt"
          "clippy"
        ];

        targets = [
          "x86_64-unknown-linux-gnu"
          "x86_64-pc-windows-gnu"
        ];
      };

      rustPlatform = pkgs.makeRustPlatform {
        cargo = rustToolchain;
        rustc = rustToolchain;
      };

      linuxApp = rustPlatform.buildRustPackage {
        pname = appName;
        version = "0.1.0";

        src = pkgs.lib.cleanSource ./.;

        cargoLock = {
          lockFile = ./Cargo.lock;
        };
      };
    in
    {
      packages.${system} = {
        default = linuxApp;
        linux = linuxApp;
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          packages = [
            rustToolchain

            # Rust workflow tools
            pkgs.cargo-nextest
            pkgs.cargo-deny
            pkgs.cargo-audit

            # Native Linux build tooling
            pkgs.pkg-config
            pkgs.openssl
            pkgs.cmake
            pkgs.clang
            pkgs.llvm
          ];

          shellHook = ''
            export PS1="\[\e[1;35m\](nix-linux)\[\e[0m\] \w\$ "

            echo ""
            echo "Entered Linux Nix dev shell for ${appName}"
            echo "IN_NIX_SHELL=$IN_NIX_SHELL"
            echo "rustc: $(which rustc)"
            echo "cargo: $(which cargo)"
            echo ""
          '';
        };

        windows = pkgs.mkShell {
          packages = [
            rustToolchain

            # Rust workflow tools
            pkgs.cargo-nextest
            pkgs.cargo-deny
            pkgs.cargo-audit

            # Normal native tools
            pkgs.pkg-config
            pkgs.cmake

            # Windows GNU cross-build tooling
            mingwCC
          ];

          CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER =
            "${mingwCC}/bin/x86_64-w64-mingw32-gcc";

          CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS =
            "-L native=${mingwPthreads}/lib";

          shellHook = ''
            export PS1="\[\e[1;34m\](nix-windows)\[\e[0m\] \w\$ "

            echo ""
            echo "Entered Windows GNU Nix dev shell for ${appName}"
            echo "IN_NIX_SHELL=$IN_NIX_SHELL"
            echo "rustc: $(which rustc)"
            echo "cargo: $(which cargo)"
            echo "mingw gcc: $(which x86_64-w64-mingw32-gcc)"
            echo ""
          '';
        };
      };

      checks.${system} = {
        build = linuxApp;
      };
    };
}