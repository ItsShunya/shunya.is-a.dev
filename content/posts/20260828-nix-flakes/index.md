---
title: "One flake per project"
summary: "How flakes changed Nix, and how a flake.nix and nix develop give each of my projects its own reproducible environment."
description: "Nix flakes explained: what changed from channels and shell.nix, inputs, outputs and flake.lock, and how I create a flake for every development project and enter it with nix develop. Plus a first look at NixOS."
categories: [Tooling]
tags: [Nix, Flakes, NixOS]
series: ["Nix"]
series_order: 2
date: 2026-08-28
draft: false
---

{{< lead >}}
*«The more things change, the more they stay the same.»* — Jean-Baptiste Alphonse Karr
{{< /lead >}}

In the [previous post](/posts/20260801-nix/), I explained what Nix is and why I prefer it over the package managers I used before. This one is about how I use it every day: every project I work on has a `flake.nix` that lists exactly what it needs, and `nix develop` drops me into that environment, today or two years from now.

{{< article link="/posts/20260801-nixos/" showSummary=true compactSummary=true >}}

## Before Flakes: Channels and `shell.nix`

Nix had per-project environments long before flakes. You'd write a `shell.nix`:

```nix
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [ pkgs.hugo ];
}
```

and run `nix-shell` to enter it. The problem is `<nixpkgs>`. It means "whatever version of Nixpkgs this machine's channel points to", looked up through the `NIX_PATH` environment variable, and a channel moves whenever its owner runs `nix-channel --update`. Same `shell.nix`, two machines, two different Hugo versions: reproducible builds from inputs that weren't.

You could pin Nixpkgs by hand with `fetchTarball`, a commit and a hash, or with tools like niv. But pinning was optional and manual, and every project did it differently.

## Flakes

Flakes were proposed in 2019 ([RFC 49](https://github.com/NixOS/rfcs/pull/49)) and shipped as an experimental feature in Nix 2.4, at the end of 2021. A flake is a directory, usually a Git repository, with a `flake.nix` at its root that follows a fixed structure:

- **`inputs`**: the other flakes it depends on, such as Nixpkgs, written as URLs like `github:NixOS/nixpkgs/nixos-unstable`.
- **`outputs`**: a function that receives those inputs and returns what the flake provides: packages, development shells, NixOS configurations, and so on.

The first time you use a flake, Nix resolves every input to an exact commit and content hash and writes them to `flake.lock`. From then on, everyone who uses the flake gets exactly those revisions, until someone deliberately runs `nix flake update`. It's the same idea as `package-lock.json` or `Cargo.lock`, except it covers the whole toolchain, compiler and C libraries included.

Flakes also made evaluation pure: no `NIX_PATH`, no channels, no environment variables, and no files from outside the flake. They come with the new `nix` command line (`nix develop`, `nix build`, `nix run`, `nix shell`) and a single way to point at anything a flake provides: `nixpkgs#hugo`, `github:owner/repo#package`, or `.` for the flake in the current directory.

{{< alert >}}
**Be aware:** almost five years later, flakes are still officially experimental (Nix 2.31 as I write this), and RFC 49 was closed without being merged. In practice, a large part of the community, me included, has used them every day for years, and most new documentation assumes them. It's just why you have to enable them by hand, as shown in the previous post.
{{< /alert >}}

## One Flake per Project

Every project I work on gets a `flake.nix` at its root listing what it needs. Here's the one for this blog, exactly as it is in the repository:

```nix
{
  description = "Dev environment flake for the site's development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          # Add runtime dependencies, language, and libraries here
          buildInputs = with pkgs; [
            git
            hugo
          ];
        };
      }
    );
}
```

- **`inputs`** takes Nixpkgs from the `nixos-unstable` branch, plus [`flake-utils`](https://github.com/numtide/flake-utils), a small helper library.
- **`outputs`** is a function: Nix fetches the inputs and passes them in.
- **`flake-utils.lib.eachDefaultSystem`** repeats the definition for every common platform, so the same flake works on x86-64 and Arm, Linux and macOS.
- **`pkgs`** is Nixpkgs for the current platform.
- **`devShells.default`** is the environment `nix develop` enters. `pkgs.mkShell` builds it from the packages in `buildInputs`.

`nix flake show` lists what that produces:

```text
$ nix flake show
git+file:///home/shunya/Documents/repos/itsshunya.github.io
└───devShells
    ├───aarch64-darwin
    │   └───default omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   └───default omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   └───default omitted (use '--all-systems' to show)
    └───x86_64-linux
        └───default: development environment 'nix-shell'
```

To work on the blog, I just enter it:

```text
$ nix develop
$ hugo version
hugo v0.149.1+extended+withdeploy linux/amd64 BuildDate=unknown VendorInfo=nixpkgs
```

Hugo and Git are in my `PATH` while I'm in that shell, and gone when I exit. Hugo isn't installed anywhere else on my system.

For firmware, the list gets longer, but the file has the same shape:

```nix
{
  description = "Firmware for an STM32 board";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Build
            gcc-arm-embedded
            cmake
            ninja
            pkg-config

            # Flash and debug
            openocd

            # Host-side unit tests
            cmocka

            # Scripts that talk to the board
            (python3.withPackages (ps: [ ps.pyserial ]))
          ];
        };
      }
    );
}
```

`cmocka` is a library, not a tool, and `mkShell` sets up the environment so CMake's `find_package` and `pkg-config` find it. `python3.withPackages` builds a Python interpreter that already includes pyserial, no virtual environment needed.

```text
$ nix develop
$ arm-none-eabi-gcc --version | head -1
arm-none-eabi-gcc (Arm GNU Toolchain 15.3.Rel1 (Build arm-15.149)) 15.3.1 20260627
$ pkg-config --modversion cmocka
2.0.2
$ which arm-none-eabi-gcc
/nix/store/yh89v55i1jpzyxpnml9yidnmj1w7z3m5-gcc-arm-embedded-15.3.rel1/bin/arm-none-eabi-gcc
$ exit
$ which arm-none-eabi-gcc
arm-none-eabi-gcc not found
```

{{< alert >}}
**Be aware:** in a Git repository, a flake only sees files Git tracks. Create `flake.nix`, forget to `git add` it, and `nix develop` stops with `error: Path 'flake.nix' in the repository "…" is not tracked by Git.` The same goes for any other file the flake references.
{{< /alert >}}

`nix develop` starts Bash. If, like me, you live in Zsh, run `nix develop -c zsh` instead: you keep your own shell and prompt, with the project's tools added to your `PATH`.

### The Lock File

The first `nix develop` in a new project creates `flake.lock`:

```text
warning: creating lock file "~/projects/firmware/flake.lock":
• Added input 'flake-utils':
    'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b?narHash=…' (2024-11-13)
• Added input 'flake-utils/systems':
    'github:nix-systems/default/da67096a3b9bf56a91d16901293e51ba5b49a27e?narHash=…' (2023-04-09)
• Added input 'nixpkgs':
    'github:NixOS/nixpkgs/c59305bab2065cfecc4944690d9eedbb56f3a9fa?narHash=…' (2026-10-01)
```

Commit it next to `flake.nix`, because it's what makes the environment reproducible. This blog's lock file pins Nixpkgs to 10 September 2025, so `nix develop` gives me Hugo 0.149.1 today, even though `nixos-unstable` has moved on to 0.166.0. The same firmware flake run against the Nixpkgs of my NixOS system gives Arm GCC 14.3 instead of 15.3: the `flake.nix` says *what*, and the lock file says *which version*.

When I want newer tools, I update on purpose:

```sh
nix flake update
```

and commit the new `flake.lock`. The toolchain is now versioned with the code: check out a two-year-old commit and you get the two-year-old compiler too. If an update breaks the build, reverting the commit brings the old toolchain back.

{{< alert "search" >}}
**Did you know?** `nix develop` takes any flake reference, not just the current directory. `nix develop github:owner/repo` enters someone else's development environment without cloning anything. And if you don't want to type `nix develop` at all, [direnv](https://direnv.net) with [nix-direnv](https://github.com/nix-community/nix-direnv) loads the environment as soon as you `cd` into the project.
{{< /alert >}}

## NixOS: Nix All the Way Down

Everything so far works on any Linux distribution and on macOS. NixOS takes the idea one step further: it's a Linux distribution where the whole system, not just your packages, is built by Nix. Kernel, bootloader, services, users and system packages are all declared in Nix files, traditionally `/etc/nixos/configuration.nix`. A trimmed-down example:

```nix
{ pkgs, ... }:

{
  networking.hostName = "workstation";
  time.timeZone = "Europe/Madrid";

  users.users.shunya = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dialout" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [ git vim ];
}
```

`sudo nixos-rebuild switch` builds the system that file describes and switches to it. Every rebuild creates a new generation, and every generation shows up in the boot menu: if an update breaks something, you reboot into the previous one. Copy the configuration to another machine and you get the same system. Put it in a flake, and a `flake.lock` pins the version of every package on your computer.

It's what I run myself, and it deserves more than a section, so the next post is all about NixOS.

Nixpkgs changes every day: new compilers, new libraries, new Python versions. With a flake in every project, my environments only change when I decide they should.
