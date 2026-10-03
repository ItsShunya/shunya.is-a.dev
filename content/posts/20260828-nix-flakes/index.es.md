---
title: "Un flake por proyecto"
summary: "Cómo los flakes cambiaron Nix, y cómo un flake.nix y nix develop dan a cada uno de mis proyectos su propio entorno reproducible."
description: "Los flakes de Nix explicados: qué cambió respecto a los channels y shell.nix, inputs, outputs y flake.lock, y cómo creo un flake para cada proyecto de desarrollo y entro en él con nix develop. Y un primer vistazo a NixOS."
categories: [Herramientas]
tags: [Nix, Flakes, NixOS]
series: ["Nix"]
series_order: 2
date: 2026-08-28
draft: false
---

{{< lead >}}
*«Cuanto más cambian las cosas, más siguen igual.»* — Jean-Baptiste Alphonse Karr
{{< /lead >}}

En el [post anterior](/es/posts/20260801-nix/) expliqué qué es Nix y por qué lo prefiero a los gestores de paquetes que usaba antes. Este va de cómo lo uso cada día: cada proyecto en el que trabajo tiene un `flake.nix` que enumera exactamente lo que necesita, y `nix develop` me mete en ese entorno, hoy o dentro de dos años.

{{< article link="/es/posts/20260801-nix/" showSummary=true compactSummary=true >}}

## Antes de los flakes: channels y `shell.nix`

Nix tenía entornos por proyecto mucho antes de los flakes. Escribías un `shell.nix`:

```nix
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [ pkgs.hugo ];
}
```

y ejecutabas `nix-shell` para entrar. El problema es `<nixpkgs>`. Significa "la versión de Nixpkgs a la que apunte el channel de esta máquina", que se busca a través de la variable de entorno `NIX_PATH`, y un channel se mueve cada vez que su dueño ejecuta `nix-channel --update`. Mismo `shell.nix`, dos máquinas, dos versiones distintas de Hugo: compilaciones reproducibles a partir de entradas que no lo eran.

Podías fijar Nixpkgs a mano con `fetchTarball`, un commit y un hash, o con herramientas como niv. Pero fijar la versión era opcional y manual, y cada proyecto lo hacía a su manera.

## Flakes

Los flakes se propusieron en 2019 ([RFC 49](https://github.com/NixOS/rfcs/pull/49)) y llegaron como funcionalidad experimental en Nix 2.4, a finales de 2021. Un flake es un directorio, normalmente un repositorio Git, con un `flake.nix` en su raíz que sigue una estructura fija:

- **`inputs`**: los otros flakes de los que depende, como Nixpkgs, escritos como URLs del tipo `github:NixOS/nixpkgs/nixos-unstable`.
- **`outputs`**: una función que recibe esas entradas y devuelve lo que el flake proporciona: paquetes, shells de desarrollo, configuraciones de NixOS, etc.

La primera vez que usas un flake, Nix resuelve cada entrada a un commit y un hash de contenido exactos y los escribe en `flake.lock`. A partir de ahí, todo el que use el flake obtiene exactamente esas revisiones, hasta que alguien ejecute deliberadamente `nix flake update`. Es la misma idea que `package-lock.json` o `Cargo.lock`, salvo que cubre toda la toolchain, compilador y librerías de C incluidos.

Los flakes también hicieron que la evaluación fuera pura: sin `NIX_PATH`, sin channels, sin variables de entorno y sin ficheros de fuera del flake. Vienen con la nueva línea de comandos `nix` (`nix develop`, `nix build`, `nix run`, `nix shell`) y una única forma de referirse a cualquier cosa que proporcione un flake: `nixpkgs#hugo`, `github:owner/repo#package`, o `.` para el flake del directorio actual.

{{< alert >}}
**Ojo:** casi cinco años después, los flakes siguen siendo oficialmente experimentales (Nix 2.31 mientras escribo esto), y el RFC 49 se cerró sin llegar a fusionarse. En la práctica, gran parte de la comunidad, yo incluido, los usa a diario desde hace años, y la mayoría de la documentación nueva da por hecho que los usas. Simplemente es el motivo por el que tienes que activarlos a mano, como se mostró en el post anterior.
{{< /alert >}}

## Un flake por proyecto

Cada proyecto en el que trabajo tiene un `flake.nix` en su raíz con lo que necesita. Este es el de este blog, exactamente como está en el repositorio:

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

- **`inputs`** toma Nixpkgs de la rama `nixos-unstable`, además de [`flake-utils`](https://github.com/numtide/flake-utils), una pequeña librería auxiliar.
- **`outputs`** es una función: Nix descarga las entradas y se las pasa.
- **`flake-utils.lib.eachDefaultSystem`** repite la definición para cada plataforma habitual, así que el mismo flake funciona en x86-64 y Arm, Linux y macOS.
- **`pkgs`** es Nixpkgs para la plataforma actual.
- **`devShells.default`** es el entorno en el que entra `nix develop`. `pkgs.mkShell` lo construye a partir de los paquetes de `buildInputs`.

`nix flake show` enumera lo que produce:

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

Para trabajar en el blog, simplemente entro:

```text
$ nix develop
$ hugo version
hugo v0.149.1+extended+withdeploy linux/amd64 BuildDate=unknown VendorInfo=nixpkgs
```

Hugo y Git están en mi `PATH` mientras estoy en esa shell, y desaparecen cuando salgo. Hugo no está instalado en ningún otro sitio de mi sistema.

Para firmware la lista crece, pero el fichero tiene la misma forma:

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
            # Compilación
            gcc-arm-embedded
            cmake
            ninja
            pkg-config

            # Flasheo y depuración
            openocd

            # Tests unitarios en el host
            cmocka

            # Scripts que hablan con la placa
            (python3.withPackages (ps: [ ps.pyserial ]))
          ];
        };
      }
    );
}
```

`cmocka` es una librería, no una herramienta, y `mkShell` prepara el entorno para que `find_package` de CMake y `pkg-config` la encuentren. `python3.withPackages` construye un intérprete de Python que ya incluye pyserial, sin necesidad de un entorno virtual.

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
**Ojo:** en un repositorio Git, un flake solo ve los ficheros que Git sigue. Crea `flake.nix`, olvídate de hacerle `git add`, y `nix develop` se detiene con `error: Path 'flake.nix' in the repository "…" is not tracked by Git.` Lo mismo pasa con cualquier otro fichero al que haga referencia el flake.
{{< /alert >}}

`nix develop` arranca Bash. Si, como yo, vives en Zsh, ejecuta `nix develop -c zsh`: mantienes tu propia shell y tu prompt, con las herramientas del proyecto añadidas a tu `PATH`.

### El lock file

El primer `nix develop` en un proyecto nuevo crea `flake.lock`:

```text
warning: creating lock file "~/projects/firmware/flake.lock":
• Added input 'flake-utils':
    'github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b?narHash=…' (2024-11-13)
• Added input 'flake-utils/systems':
    'github:nix-systems/default/da67096a3b9bf56a91d16901293e51ba5b49a27e?narHash=…' (2023-04-09)
• Added input 'nixpkgs':
    'github:NixOS/nixpkgs/c59305bab2065cfecc4944690d9eedbb56f3a9fa?narHash=…' (2026-10-01)
```

Haz commit de él junto a `flake.nix`, porque es lo que hace que el entorno sea reproducible. El lock file de este blog fija Nixpkgs al 10 de septiembre de 2025, así que `nix develop` me da Hugo 0.149.1 hoy, aunque `nixos-unstable` ya vaya por la 0.166.0. El mismo flake de firmware ejecutado contra el Nixpkgs de mi sistema NixOS da Arm GCC 14.3 en lugar de 15.3: el `flake.nix` dice *qué*, y el lock file dice *qué versión*.

Cuando quiero herramientas más nuevas, actualizo a propósito:

```sh
nix flake update
```

y hago commit del nuevo `flake.lock`. Ahora la toolchain está versionada junto al código: haz checkout de un commit de hace dos años y obtendrás también el compilador de hace dos años. Si una actualización rompe la compilación, revertir el commit trae de vuelta la toolchain anterior.

{{< alert "search" >}}
**¿Sabías que...?** `nix develop` acepta cualquier referencia a un flake, no solo el directorio actual. `nix develop github:owner/repo` te mete en el entorno de desarrollo de otra persona sin clonar nada. Y si no quieres escribir `nix develop` en absoluto, [direnv](https://direnv.net) con [nix-direnv](https://github.com/nix-community/nix-direnv) carga el entorno en cuanto haces `cd` al proyecto.
{{< /alert >}}

## NixOS: Nix de arriba abajo

Todo lo anterior funciona en cualquier distribución de Linux y en macOS. NixOS lleva la idea un paso más allá: es una distribución de Linux en la que todo el sistema, no solo tus paquetes, lo construye Nix. Kernel, gestor de arranque, servicios, usuarios y paquetes del sistema se declaran en ficheros Nix, tradicionalmente `/etc/nixos/configuration.nix`. Un ejemplo recortado:

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

`sudo nixos-rebuild switch` construye el sistema que describe ese fichero y cambia a él. Cada reconstrucción crea una nueva generación, y cada generación aparece en el menú de arranque: si una actualización rompe algo, reinicias en la anterior. Copia la configuración a otra máquina y obtendrás el mismo sistema. Ponla en un flake, y un `flake.lock` fijará la versión de cada paquete de tu ordenador.

Es lo que uso yo mismo, y merece más que una sección, así que el próximo post va entero sobre NixOS.

Nixpkgs cambia cada día: compiladores nuevos, librerías nuevas, versiones nuevas de Python. Con un flake en cada proyecto, mis entornos solo cambian cuando yo decido que deben hacerlo.
