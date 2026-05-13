# \# NixBuildTesting

# 

# A tiny Rust hello-world project used to test building Rust applications with \*\*Nix\*\*.

# 

# The program simply prints:

# 

# ```text

# I was built in nix!

# ```

# 

# The goal of this repo is not the Rust application itself. The goal is to demonstrate a reproducible build setup where Nix provides the Rust toolchain, build tools, and optional cross-compilation environment.

# 

# ---

# 

# \## What this project demonstrates

# 

# This repo shows how to use Nix to control the build environment for a Rust project.

# 

# Instead of relying on whatever Rust/Cargo/toolchain happens to be installed on the host machine, the project defines those tools in `flake.nix`.

# 

# Nix provides:

# 

# \- a pinned Rust toolchain

# \- Cargo

# \- rustfmt

# \- clippy

# \- cargo-nextest

# \- cargo-audit

# \- cargo-deny

# \- Linux build tooling

# \- optional Windows GNU cross-compilation tooling

# 

# The lock files are important:

# 

# | File | Purpose |

# |---|---|

# | `Cargo.lock` | Pins Rust crate dependency resolution |

# | `flake.lock` | Pins the Nix inputs, including `nixpkgs` and the Rust overlay |

# | `flake.nix` | Defines the build environment and available build shells |

# 

# ---

# 

# \## Project structure

# 

# ```text

# NixBuildTesting/

# &nbsp; Cargo.toml

# &nbsp; Cargo.lock

# &nbsp; flake.nix

# &nbsp; flake.lock

# &nbsp; src/

# &nbsp;   main.rs

# ```

# 

# The Rust application is intentionally minimal:

# 

# ```rust

# fn main() {

# &nbsp;   println!("I was built in nix!");

# }

# ```

# 

# ---

# 

# \## Requirements

# 

# You need Nix installed with flakes enabled.

# 

# On WSL/Linux, make sure this is configured:

# 

# ```bash

# mkdir -p ~/.config/nix

# echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# ```

# 

# Then restart your shell.

# 

# Verify Nix works:

# 

# ```bash

# nix --version

# ```

# 

# ---

# 

# \## Enter the Linux dev shell

# 

# ```bash

# nix develop

# ```

# 

# This enters the default Nix development shell.

# 

# You should see output showing the Nix-provided Rust and Cargo paths.

# 

# Inside the shell, you can run normal Rust commands:

# 

# ```bash

# cargo build --locked

# cargo run --locked

# cargo test --locked

# cargo clippy --locked --all-targets --all-features

# cargo fmt --check

# ```

# 

# Exit the shell with:

# 

# ```bash

# exit

# ```

# 

# ---

# 

# \## Build the Linux binary with Nix

# 

# ```bash

# nix build

# ```

# 

# This builds the default Nix package.

# 

# The output appears at:

# 

# ```text

# result/bin/buildFromNix

# ```

# 

# Run it:

# 

# ```bash

# ./result/bin/buildFromNix

# ```

# 

# Expected output:

# 

# ```text

# I was built in nix!

# ```

# 

# ---

# 

# \## Build Linux with Cargo inside the Nix shell

# 

# ```bash

# nix develop -c cargo build --release --locked

# ```

# 

# Output:

# 

# ```text

# target/release/buildFromNix

# ```

# 

# Run it:

# 

# ```bash

# ./target/release/buildFromNix

# ```

# 

# ---

# 

# \## Build a Windows `.exe`

# 

# This project also defines a separate Windows GNU cross-build shell.

# 

# Use:

# 

# ```bash

# nix develop .#windows -c cargo build --release --locked --target x86\_64-pc-windows-gnu

# ```

# 

# Output:

# 

# ```text

# target/x86\_64-pc-windows-gnu/release/buildFromNix.exe

# ```

# 

# This produces a Windows GNU executable from WSL/Linux.

# 

# Note: this is not the same as the MSVC target. For simple Rust programs, the GNU target is usually fine. For Windows-native projects that depend on MSVC-specific tooling or libraries, a dedicated Windows/MSVC build setup may be needed.

# 

# ---

# 

# \## Build both Linux and Windows artifacts

# 

# ```bash

# mkdir -p dist

# 

# nix build

# cp -L result/bin/buildFromNix dist/buildFromNix-linux

# 

# nix develop .#windows -c cargo build --release --locked --target x86\_64-pc-windows-gnu

# cp target/x86\_64-pc-windows-gnu/release/buildFromNix.exe dist/buildFromNix-windows.exe

# 

# ls -lah dist

# ```

# 

# Expected result:

# 

# ```text

# dist/

# &nbsp; buildFromNix-linux

# &nbsp; buildFromNix-windows.exe

# ```

# 

# ---

# 

# \## Useful commands

# 

# \### Enter default Linux shell

# 

# ```bash

# nix develop

# ```

# 

# \### Enter Windows cross-build shell

# 

# ```bash

# nix develop .#windows

# ```

# 

# \### Build Linux package

# 

# ```bash

# nix build

# ```

# 

# \### Run checks

# 

# ```bash

# nix flake check

# ```

# 

# \### Run cargo-nextest

# 

# ```bash

# nix develop -c cargo nextest run --locked

# ```

# 

# \### Generate docs

# 

# ```bash

# nix develop -c cargo doc --locked --no-deps

# ```

# 

# ---

# 

# \## Notes for Windows/WSL users

# 

# This project works best when the repo is stored inside the WSL filesystem, for example:

# 

# ```text

# ~/src/NixBuildTesting

# ```

# 

# Rather than directly under:

# 

# ```text

# /mnt/c/...

# /mnt/g/...

# ```

# 

# Building from `/mnt/c` or `/mnt/g` can work, but filesystem performance is usually worse and Windows line endings can sometimes cause shell issues.

# 

# If you see this error:

# 

# ```text

# bash: $'\\r': command not found

# ```

# 

# normalize the line endings:

# 

# ```bash

# sed -i 's/\\r$//' flake.nix

# ```

# 

# It is also useful to add a `.gitattributes` file:

# 

# ```text

# \*.nix text eol=lf

# \*.sh text eol=lf

# flake.lock text eol=lf

# ```

# 

# ---

# 

# \## Why use Nix here?

# 

# Nix makes the build environment explicit.

# 

# Instead of saying:

# 

# > Install Rust, Cargo, Clippy, Nextest, MinGW, OpenSSL, CMake, and make sure the versions are compatible.

# 

# The repo says:

# 

# > Run `nix develop` or `nix build`.

# 

# That makes the build process easier to reproduce across machines.

# 

# The important idea is:

# 

# ```text

# Cargo.lock controls Rust dependency versions.

# flake.lock controls Nix/toolchain/package inputs.

# flake.nix defines the build environment.

# ```

# 

# This repo is a small test project for that workflow.

