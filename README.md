# NixBuildTesting

A tiny Rust hello-world project used to test building Rust applications with **Nix**.

The program prints:

```text
I was built in nix!
```

The purpose of this repo is not the Rust application itself. The purpose is to demonstrate how Nix can provide a reproducible Rust build environment with pinned toolchains, build tools, and optional cross-compilation support.

---

## What this project demonstrates

This project shows how to use Nix to control the build environment for a Rust project.

Instead of relying on whatever Rust, Cargo, Clippy, or linker happens to be installed on the host machine, the project defines the build environment in `flake.nix`.

Nix provides:

- A pinned Rust toolchain
- Cargo
- rustfmt
- clippy
- cargo-nextest
- cargo-audit
- cargo-deny
- Linux build tooling
- Optional Windows GNU cross-compilation tooling

The important files are:

| File | Purpose |
|---|---|
| `Cargo.toml` | Defines the Rust package |
| `Cargo.lock` | Pins Rust crate dependency resolution |
| `flake.nix` | Defines the Nix build environment |
| `flake.lock` | Pins the Nix inputs, including `nixpkgs` and the Rust overlay |

---

## Project structure

```text
NixBuildTesting/
  Cargo.toml
  Cargo.lock
  flake.nix
  flake.lock
  src/
    main.rs
```

The Rust application is intentionally minimal:

```rust
fn main() {
    println!("I was built in nix!");
}
```

---

## Requirements

You need Nix installed with flakes enabled.

On WSL or Linux, enable flakes with:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

Restart your shell, then verify Nix is available:

```bash
nix --version
```

---

## Enter the Linux development shell

```bash
nix develop
```

This enters the default Nix development shell.

Inside the shell, Rust and related tools come from Nix rather than from the host system.

Useful checks:

```bash
which rustc
which cargo
rustc --version
cargo --version
```

Run normal Rust commands inside the shell:

```bash
cargo build --locked
cargo run --locked
cargo test --locked
cargo clippy --locked --all-targets --all-features
cargo fmt --check
```

Exit the shell with:

```bash
exit
```

---

## Build the Linux binary with Nix

```bash
nix build
```

This builds the default Nix package.

The output appears under:

```text
result/bin/
```

For this project, run:

```bash
./result/bin/buildFromNix
```

Expected output:

```text
I was built in nix!
```

---

## Build Linux with Cargo inside the Nix shell

```bash
nix develop -c cargo build --release --locked
```

Output:

```text
target/release/buildFromNix
```

Run it:

```bash
./target/release/buildFromNix
```

---

## Build a Windows executable

This project also defines a separate Windows GNU cross-build shell.

Use:

```bash
nix develop .#windows -c cargo build --release --locked --target x86_64-pc-windows-gnu
```

Output:

```text
target/x86_64-pc-windows-gnu/release/buildFromNix.exe
```

This produces a Windows GNU executable from WSL or Linux.

This is not the same as the MSVC target. For simple Rust programs, the GNU target is usually fine. For Windows-native projects that depend on MSVC-specific tooling or libraries, a dedicated Windows/MSVC build setup may be needed.

---

## Build both Linux and Windows artifacts

```bash
mkdir -p dist

nix build
cp -L result/bin/buildFromNix dist/buildFromNix-linux

nix develop .#windows -c cargo build --release --locked --target x86_64-pc-windows-gnu
cp target/x86_64-pc-windows-gnu/release/buildFromNix.exe dist/buildFromNix-windows.exe

ls -lah dist
```

Expected result:

```text
dist/
  buildFromNix-linux
  buildFromNix-windows.exe
```

---

## Useful commands

### Enter the default Linux shell

```bash
nix develop
```

### Enter the Windows cross-build shell

```bash
nix develop .#windows
```

### Build the default Linux package

```bash
nix build
```

### Run flake checks

```bash
nix flake check
```

### Run tests with cargo-nextest

```bash
nix develop -c cargo nextest run --locked
```

### Generate docs

```bash
nix develop -c cargo doc --locked --no-deps
```

### Run Clippy

```bash
nix develop -c cargo clippy --locked --all-targets --all-features -- -D warnings
```

### Check formatting

```bash
nix develop -c cargo fmt --check
```

---

## Notes for Windows and WSL users

This project works best when stored inside the WSL filesystem, for example:

```text
~/src/NixBuildTesting
```

Rather than directly under a Windows-mounted path such as:

```text
/mnt/c/...
/mnt/g/...
```

Building from `/mnt/c` or `/mnt/g` can work, but filesystem performance is usually worse, and Windows line endings can sometimes cause shell issues.

To prevent line ending problems, add a `.gitattributes` file:

```text
*.nix text eol=lf
*.sh text eol=lf
flake.lock text eol=lf
```

If a Nix shell script reports a Windows line-ending issue, convert the file to Unix line endings before running Nix again. One simple option is:

```bash
dos2unix flake.nix
```

If `dos2unix` is not installed:

```bash
sudo apt update
sudo apt install dos2unix
```

---

## Why use Nix here?

Nix makes the build environment explicit.

Instead of saying:

> Install Rust, Cargo, Clippy, Nextest, MinGW, OpenSSL, CMake, and make sure the versions are compatible.

The repo says:

> Run `nix develop` or `nix build`.

That makes the build process easier to reproduce across machines.

The important idea is:

```text
Cargo.lock controls Rust dependency versions.
flake.lock controls Nix/toolchain/package inputs.
flake.nix defines the build environment.
```

This repo is a small test project for that workflow.
