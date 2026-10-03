---
title: "Nix, explicado por alguien que lo usa a diario"
summary: "Qué es Nix y qué no es, cómo su store mantiene separadas todas las versiones de cada paquete, y por qué lo prefiero a los gestores de paquetes que usaba antes."
description: "Una introducción al gestor de paquetes Nix: qué es Nix y qué no es, cómo funciona el Nix store, comandos del día a día como nix shell y nix profile, y cómo se compara Nix con apt, Homebrew, pip y Docker."
categories: [Herramientas]
tags: [Nix, "Gestores de Paquetes"]
series: ["Nix"]
series_order: 1
date: 2026-08-01
draft: false
---

{{< lead >}}
*«Ningún hombre se baña dos veces en el mismo río, porque ni el río es el mismo ni él es el mismo hombre.»* — Heráclito
{{< /lead >}}

Cada proyecto necesita algo ligeramente distinto. Un firmware quiere la versión de Arm GCC con la que se validó. Una herramienta de escritorio quiere una versión concreta de Qt. Un script necesita Python 3.12, otro se rompe con cualquier cosa anterior a la 3.13.

La respuesta habitual es instalarlo todo de forma global y esperar que las versiones se lleven bien. Eso funciona hasta que vuelves a un proyecto al cabo de un año: el sistema ha avanzado, el compilador se ha actualizado y la compilación que antes funcionaba ya no lo hace. Mismo proyecto, distinto río.

Nix es mi forma de bañarme dos veces en el mismo río. Mantiene separadas todas las versiones de cada paquete, así que cada proyecto puede tener exactamente las herramientas que necesita, hoy o dentro de dos años.

Este post explica qué es Nix, qué no es, y por qué lo prefiero a los gestores de paquetes que usaba antes.

## ¿Qué es Nix?

El nombre abarca tres cosas:

- **El gestor de paquetes**, `nix`, que compila e instala software.
- **El lenguaje Nix**, un lenguaje pequeño, perezoso y funcional que se usa para describir paquetes y entornos.
- **Nixpkgs**, la colección de paquetes escrita en ese lenguaje. Con unos 150.000 paquetes, es el repositorio más grande y más actualizado de los que sigue [Repology](https://repology.org/repositories/statistics/total).

Nix nació en 2003 como proyecto de investigación de Eelco Dolstra en la Universidad de Utrecht. Su tesis doctoral de 2006, *The Purely Functional Software Deployment Model*, sigue resumiendo la idea: compilar un paquete debería funcionar como una función pura. Las mismas entradas (código fuente, dependencias, compilador, opciones de compilación) producen siempre la misma salida, y nada más puede influir en la compilación.

## Cada paquete tiene su propio directorio

La mayoría de gestores de paquetes instalan en directorios compartidos como `/usr/bin` y `/usr/lib`, así que solo hay sitio para una versión de cada cosa. Nix instala cada paquete en su propio directorio dentro de `/nix/store`, cuyo nombre es un hash de todas sus entradas:

```text
/nix/store/5gwmjwm6qs6hlnqn639c4wvvh721jpj4-hugo-0.149.1
```

Cambia cualquier entrada, ya sea una dependencia, un parche o una opción del compilador, y el hash cambia: es un paquete distinto en un directorio distinto. Nunca se sobrescribe nada, así que una misma máquina puede tener tantas versiones como necesites. Esta es una parte de mi store:

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

Cinco versiones menores de Python, ninguna en `/usr/bin`, y sin conflictos entre ellas. Cada programa apunta a las rutas exactas del store de las librerías con las que se compiló, nunca a "el `libssl` que haya instalado en ese momento".

{{< alert "search" >}}
**¿Sabías que...?** La misma versión puede aparecer más de una vez. Mi store tiene seis copias de Python 3.12.8, cada una con un hash distinto. Algo en sus entradas es diferente, quizá una actualización de OpenSSL o un parche, así que para Nix son seis paquetes distintos.
{{< /alert >}}

## Lo que Nix no es

A Nix se le compara con muchas cosas que no es:

- **No es una distribución de Linux.** Nix funciona en cualquier distribución de Linux y en macOS, junto a apt o Homebrew. NixOS es una distribución construida sobre Nix, pero no la necesitas para usar Nix.
- **No es un contenedor.** Nix no aísla los programas en tiempo de ejecución: lo que instalas con él se ejecuta directamente en tu máquina, con el mismo acceso a tus ficheros y dispositivos que cualquier otra cosa. El sandbox solo se aplica durante la compilación.
- **No sustituye a tu sistema de compilación.** Un firmware empaquetado con Nix sigue compilándose con su propio CMake o Make. Nix proporciona el compilador, las librerías y las herramientas, y ejecuta esa compilación en su sandbox.
- **No garantiza binarios idénticos.** Nix garantiza las mismas entradas, no los mismos bytes. Si un paso de la compilación no es determinista, por ejemplo si su salida depende del orden de ejecución de los hilos, las mismas entradas pueden producir un binario distinto.

## Usar Nix como gestor de paquetes

Instala Nix con el script oficial:

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

Los comandos de este post usan la nueva línea de comandos `nix` y los flakes, que todavía están marcados como experimentales. Activa ambos en `~/.config/nix/nix.conf`:

```ini
experimental-features = nix-command flakes
```

En NixOS, la misma opción va en la configuración del sistema como `nix.settings.experimental-features = [ "nix-command" "flakes" ];`.

A partir de ahí, Nix funciona como cualquier gestor de paquetes, con algunos trucos que los demás no tienen:

```sh
# Abre una shell con Hugo dentro; al salir, desaparece
nix shell nixpkgs#hugo

# Ejecuta un programa una vez sin instalarlo
nix run nixpkgs#cowsay -- "Hello, Nix"

# Busca en Nixpkgs
nix search nixpkgs ripgrep

# Instala un paquete para tu usuario y luego deshazlo
nix profile add nixpkgs#ripgrep
nix profile rollback

# Borra todo aquello a lo que ya nada hace referencia
nix store gc
```

`nixpkgs#hugo` se lee como "la salida `hugo` del flake `nixpkgs`". `nix shell` es el que más uso: cuando necesito una herramienta una sola vez, no la instalo, la tomo prestada.

Eso sí, casi nunca uso `nix profile`. Prácticamente todo lo que uso viene o de mi configuración de NixOS o del flake de un proyecto.

## Lo que Nix hace mejor

- **Todas las versiones pueden convivir.** Dos proyectos que necesitan compiladores distintos no son un conflicto, solo dos directorios en el store.
- **Las actualizaciones son atómicas.** Una nueva versión aterriza en un directorio nuevo, y cambiar a ella es cambiar un enlace simbólico. Una actualización interrumpida deja la versión anterior intacta.
- **Los rollbacks vienen de serie.** Cada cambio en un perfil crea una nueva generación, y volver atrás es un solo comando.
- **Sin root para el uso diario.** Una vez instalado el daemon de Nix, cada usuario instala paquetes para sí mismo.
- **Las compilaciones son herméticas.** Los paquetes se compilan en un sandbox que solo ve sus entradas declaradas: sin red, sin `/usr/lib`, sin directorio personal. Una compilación no puede depender a escondidas de algo que casualmente tenías instalado.
- **Los binarios se cachean.** Como un hash identifica una compilación exacta, Nix descarga binarios precompilados de `cache.nixos.org` en lugar de compilarlos, siempre que esa compilación exacta se haya hecho antes.
- **Lo cubre todo.** Compiladores, librerías de C, paquetes de Python, herramientas de línea de comandos: una sola herramienta y un solo fichero para todo, en lugar de apt para unas cosas, pip para otras y un tarball en `/opt` para la toolchain.
- **Entornos por proyecto.** Cada proyecto puede declarar exactamente las herramientas que necesita y obtenerlas sin instalar nada de forma global.

Así se compara con las herramientas que usaría si no:

|  | apt, Homebrew | pip, npm, cargo | Docker | Nix |
|---|---|---|---|---|
| Varias versiones a la vez | Rara vez | Por proyecto | Por contenedor | Siempre |
| Compiladores y librerías de C | Sí | No | Sí | Sí |
| Entornos por proyecto | No | Sí | Sí | Sí |
| Mismo resultado un año después | No | Con un lock file | Solo si guardas la imagen | Con un lock file |
| Rollbacks | No | No | Guardando la imagen anterior | De serie |

Docker es lo que más se acerca, pero un Dockerfile que ejecuta `apt-get update` construye algo distinto cada vez, y tu entorno vive dentro de un contenedor, lejos de tu editor, de la configuración de tu shell y, si trabajas en embebidos, de la sonda de depuración USB. Nix te mantiene en tu propia máquina, con tu propia shell, y solo cambia lo que hay en tu `PATH`.

## La pega

Nix no es fácil:

- **La curva de aprendizaje es empinada.** El lenguaje Nix es funcional y perezoso, nada que ver con un formato de configuración típico, y sus mensajes de error pueden ser largos y crípticos.
- **La documentación está dispersa** entre el manual oficial, [nix.dev](https://nix.dev), la wiki e infinidad de posts de blogs, y buena parte todavía usa los comandos de antes de los flakes.
- **El store crece.** Nada se sobrescribe, así que nada se borra hasta que ejecutas el recolector de basura. Mientras escribo esto, mi store tiene 21 compilaciones distintas de Python.
- **Ignora la estructura de ficheros habitual de Linux.** No hay un `/usr/lib` lleno de librerías compartidas. Esto importa sobre todo en NixOS, donde los binarios precompilados que esperan un sistema Linux estándar a menudo no funcionan sin trabajo extra. En otras distribuciones, Nix convive con la estructura normal y el problema no aparece.

Creo que merece la pena, pero cuenta con que las primeras semanas sean las más duras.

Donde Nix realmente me encaja, eso sí, es con los flakes: un `flake.nix` por proyecto que fija todas las herramientas que necesita, hasta el commit exacto de Nixpkgs. Eso es el siguiente post.
