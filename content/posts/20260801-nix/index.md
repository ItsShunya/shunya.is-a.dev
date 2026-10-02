---
title: "Nix, explained by someone who uses it daily"
summary: "What Nix is and what it isn't, how its store keeps every version of every package apart, and why I prefer it over the package managers I used before."
description: "An introduction to the Nix package manager: what Nix is and what it isn't, how the Nix store works, everyday commands like nix shell and nix profile, and how Nix compares to apt, Homebrew, pip and Docker."
categories: [Tooling]
tags: [Nix, "Package Managers"]
series: ["Nix"]
series_order: 1
date: 2026-08-01
draft: false
---

{{< lead >}}
*«No man ever steps in the same river twice, for it's not the same river and he's not the same man.»* — Heraclitus
{{< /lead >}}

Every project needs something slightly different. A firmware wants the Arm GCC release it was validated with. A desktop tool wants a particular Qt. One script needs Python 3.12, another breaks on anything older than 3.13.

The usual answer is to install everything globally and hope the versions get along. That works until you come back to a project after a year: the system has moved on, the compiler got updated, and the build that used to work doesn't anymore. Same project, different river.

Nix is how I step into the same river twice. It keeps every version of every package apart, so each project can get exactly the tools it needs, today or two years from now.

This post covers what Nix is, what it isn't, and why I prefer it over the package managers I used before.

## What Is Nix?

The name covers three things:

- **The package manager**, `nix`, which builds and installs software.
- **The Nix language**, a small, lazy, functional language you use to describe packages and environments.
- **Nixpkgs**, the package collection written in that language. With around 150,000 packages, it's the largest and most up-to-date repository [Repology](https://repology.org/repositories/statistics/total) tracks.

Nix started in 2003 as Eelco Dolstra's research project at Utrecht University. His 2006 PhD thesis, *The Purely Functional Software Deployment Model*, still sums up the idea: building a package should work like a pure function. The same inputs (source code, dependencies, compiler, build flags) always produce the same output, and nothing else can influence the build.

## Every Package Gets Its Own Directory

Most package managers install into shared directories like `/usr/bin` and `/usr/lib`, so there's room for exactly one version of everything. Nix installs every package into its own directory under `/nix/store`, named after a hash of all its inputs:

```text
/nix/store/5gwmjwm6qs6hlnqn639c4wvvh721jpj4-hugo-0.149.1
```

Change any input, whether a dependency, a patch or a compiler flag, and the hash changes: it's a different package in a different directory. Nothing is ever overwritten, so one machine can hold as many versions as you need. Here's part of my store:

```text
$ ls -d /nix/store/*-python3-3.*[0-9]
/nix/store/97w52ckcjnfiz89h3lh7zf1kysgfm2s8-python3-3.9.6
/nix/store/xldyfac0kbcl5c1yp9ygsag5y23irwxs-python3-3.11.13
/nix/store/43386py7qrf0kv3l6spfhardpa9834dp-python3-3.12.8
/nix/store/99hl269v1igvjbp1znfk5jcarhzgy822-python3-3.12.8
/nix/store/f8xmcwbyw8am8ybkdvzsj0ln6mlr559i-python3-3.13.11
/nix/store/3n4qphl9s728sz8frmpqqrv9b1m87g68-python3-3.14.7
...
```

Five Python minor versions, none of them in `/usr/bin`, and no conflict between them. Each program points at the exact store paths of the libraries it was built against, never at "whatever `libssl` happens to be installed".

{{< alert "search" >}}
**Did you know?** The same version can show up more than once. My store has six copies of Python 3.12.8, each with a different hash. Something in their inputs differs, maybe an OpenSSL update or a patch, so to Nix they are six different packages.
{{< /alert >}}

## What Nix Isn't

Nix gets compared to a lot of things it isn't:

- **It isn't a Linux distribution.** Nix runs on any Linux distribution and on macOS, next to apt or Homebrew. NixOS is a distribution built on Nix, but you don't need it to use Nix.
- **It isn't a container.** Nix doesn't isolate programs at runtime: what you install with it runs directly on your machine, with the same access to your files and devices as anything else. The sandbox only applies while building.
- **It doesn't replace your build system.** A firmware packaged with Nix still builds with its own CMake or Make. Nix provides the compiler, the libraries and the tools, and runs that build in its sandbox.
- **It doesn't guarantee identical binaries.** Nix guarantees the same inputs, not the same bytes. If a build step isn't deterministic, for example if its output depends on thread timing, the same inputs can still produce a different binary.

## Using Nix as a Package Manager

Install Nix with the official script:

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

The commands in this post use the newer `nix` command line and flakes, which are still marked experimental. Enable both in `~/.config/nix/nix.conf`:

```ini
experimental-features = nix-command flakes
```

On NixOS, the same setting goes in your system configuration as `nix.settings.experimental-features = [ "nix-command" "flakes" ];`.

From there, Nix works like any package manager, with a few tricks the others don't have:

```sh
# Open a shell with Hugo in it; exit and it's gone
nix shell nixpkgs#hugo

# Run a program once without installing it
nix run nixpkgs#cowsay -- "Hello, Nix"

# Search Nixpkgs
nix search nixpkgs ripgrep

# Install a package for your user, then undo it
nix profile add nixpkgs#ripgrep
nix profile rollback

# Delete everything nothing refers to anymore
nix store gc
```

`nixpkgs#hugo` reads as "the `hugo` output of the `nixpkgs` flake". `nix shell` is the one I use most: when I need a tool once, I don't install it, I borrow it.

I rarely use `nix profile`, though. Almost everything I use comes either from my NixOS configuration or from a project's flake.

## What Nix Does Better

- **Every version can coexist.** Two projects that need different compilers aren't a conflict, just two directories in the store.
- **Upgrades are atomic.** A new version lands in a new directory, and switching to it is a symlink change. An interrupted upgrade leaves the old version untouched.
- **Rollbacks are built in.** Every change to a profile creates a new generation, and going back is one command.
- **No root for everyday use.** Once the Nix daemon is installed, users install packages for themselves.
- **Builds are hermetic.** Packages build in a sandbox that only sees their declared inputs: no network, no `/usr/lib`, no home directory. A build can't quietly depend on something you happened to have installed.
- **Binaries are cached.** Since a hash identifies an exact build, Nix downloads prebuilt binaries from `cache.nixos.org` instead of compiling them, as long as that exact build has been built before.
- **It covers everything.** Compilers, C libraries, Python packages, command-line tools: one tool and one file for all of them, instead of apt for some, pip for others and a tarball in `/opt` for the toolchain.
- **Per-project environments.** Each project can declare the exact tools it needs and get them without installing anything globally.

Here's how that compares with the tools I'd otherwise reach for:

|  | apt, Homebrew | pip, npm, cargo | Docker | Nix |
|---|---|---|---|---|
| Several versions side by side | Rarely | Per project | Per container | Always |
| Compilers and C libraries | Yes | No | Yes | Yes |
| Per-project environments | No | Yes | Yes | Yes |
| Same result a year later | No | With a lock file | Only if you keep the image | With a lock file |
| Rollbacks | No | No | Keep the old image | Built in |

Docker gets closest, but a Dockerfile that runs `apt-get update` builds something different every time, and your environment lives inside a container, away from your editor, your shell configuration and, for embedded work, the USB debug probe. Nix keeps you on your own machine, with your own shell, and only changes what's in your `PATH`.

## The Catch

Nix isn't easy:

- **The learning curve is steep.** The Nix language is functional and lazy, nothing like a typical configuration format, and its error messages can be long and cryptic.
- **The documentation is scattered** across the official manual, [nix.dev](https://nix.dev), the wiki and countless blog posts, and a lot of it still uses the commands from before flakes.
- **The store grows.** Nothing is overwritten, so nothing is deleted until you run the garbage collector. As I write this, my store holds 21 different Python builds.
- **It ignores the usual Linux file layout.** There's no `/usr/lib` full of shared libraries. This matters mostly on NixOS, where prebuilt binaries that expect a standard Linux system often won't run without extra work. On other distributions, Nix sits next to the normal layout and the problem doesn't come up.

I think it's worth it, but expect the first weeks to be the hardest.

Where Nix really clicks for me, though, is flakes: one `flake.nix` per project that pins every tool it needs, down to the exact commit of Nixpkgs. That's the next post.
