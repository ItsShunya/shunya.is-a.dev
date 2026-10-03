---
title: "Tu enum de C podría ocupar 1 byte"
summary: "Qué promete el estándar de C sobre los enums, qué hacen realmente GCC, Clang, MSVC y los compiladores de Arm con esa libertad, y cómo evitar que los enums rompan tu ABI."
description: "Cómo almacena C los enums en memoria: constantes de enumeración frente a tipos enumerados, las decisiones del compilador, sizeof(enum), -fshort-enums, los tipos subyacentes fijos de C23 y las trampas de ABI en Arm Cortex-M."
categories: [Embebidos]
tags: ["Lenguajes de Programación", C, ABI]
series: ["Enums en C"]
series_order: 1
date: 2026-07-15
draft: false
---

{{< lead >}}
*«¿Qué hay en un nombre? Lo que llamamos rosa, con cualquier otro nombre, olería igual de dulce.»* — William Shakespeare
{{< /lead >}}

Los enums parecen la característica menos interesante de C. Enumeras unos cuantos nombres, el compilador los numera desde cero y a otra cosa.

Hasta que un struct compartido entre tu firmware y una herramienta de escritorio deja de cuadrar, y el culpable es un enum de tres valores que ocupa un byte en un lado y cuatro en el otro. Mismos nombres, mismos valores, distinto almacenamiento.

Esto es lo que promete el estándar de C sobre los enums, lo que hacen los compiladores con la libertad que les deja, y cómo evitar que los enums rompan tu ABI. Toda la salida que aparece proviene de GCC 15.3 y Clang 21.1 en Linux x86-64, y de la Arm GNU Toolchain 14.3 compilando para un Cortex-M4.

## Dos cosas llamadas "enum"

```c
enum color { RED, GREEN, BLUE };
```

Esta única línea declara dos cosas distintas:

- **Constantes de enumeración**: `RED`, `GREEN` y `BLUE`. Hasta C17, siempre son `int`.
- **Un tipo enumerado**: `enum color`. Esto es lo que acaba en memoria.

El estándar fija lo primero y deja abierto lo segundo (C17 §6.7.2.2):

> Each enumerated type shall be compatible with `char`, a signed integer type, or an unsigned integer type. The choice of type is implementation-defined, but shall be capable of representing the values of all the members of the enumeration.

Es decir, cada tipo enumerado debe ser compatible con `char`, con un tipo entero con signo o con uno sin signo; la elección la hace la implementación, siempre que pueda representar todos los valores del enum. Así que `sizeof(RED)` es siempre `sizeof(int)`, pero `sizeof(enum color)` puede ser 1, 2, 4 u 8 bytes, almacenado exactamente igual que el tipo entero que haya elegido el compilador.

## Qué eligen GCC, Clang y MSVC

Como un tipo enumerado es compatible con exactamente un tipo entero, `_Generic` de C11 puede decirnos cuál es. Todas las tablas de este post salen de esta prueba:

```c
#define TYPE_NAME(x) _Generic((x),               \
    char:               "char",                  \
    signed char:        "signed char",           \
    unsigned char:      "unsigned char",         \
    short:              "short",                 \
    unsigned short:     "unsigned short",        \
    int:                "int",                   \
    unsigned int:       "unsigned int",          \
    long:               "long",                  \
    unsigned long:      "unsigned long",         \
    long long:          "long long",             \
    unsigned long long: "unsigned long long",    \
    default:            "something else")

printf("enum color: %s, %zu bytes\n",
       TYPE_NAME((enum color)0), sizeof(enum color));
printf("RED: %s, %zu bytes\n", TYPE_NAME(RED), sizeof(RED));
```

GCC y Clang usan `unsigned int` salvo que algún valor sea negativo, y `int` en ese caso. En x86-64 con las opciones por defecto:

| Declaración | Valores | Tipo compatible | `sizeof` |
|---|---|---|---|
| `enum color { RED, GREEN, BLUE }` | 0 a 2 | `unsigned int` | 4 |
| `enum delta { DOWN = -1, STAY, UP }` | −1 a 1 | `int` | 4 |
| `enum wide { W_SMALL = 1, W_BIG = 300 }` | 1 a 300 | `unsigned int` | 4 |

Las constantes siguen siendo `int` en todos los casos. MSVC lo pone fácil: ahí un enum de C es siempre un `int` de 4 bytes.

{{< alert >}}
**Ojo:** el signo se cuela en tu código. En GCC y Clang, `c >= 0` siempre es verdadero para un `enum color` (Clang lo marca con `-Wtautological-unsigned-enum-zero-compare`). Una comprobación como `c >= 0 && c < COLOR_COUNT` sigue rechazando `(enum color)-1`, pero GCC y Clang lo rechazan en la segunda comparación y MSVC en la primera. `(unsigned)c < COLOR_COUNT` significa lo mismo en todas partes.
{{< /alert >}}

## Enums cortos

`-fshort-enums` hace que GCC y Clang elijan el tipo más pequeño en el que quepan los valores, con signo solo si alguno es negativo:

| Declaración | Por defecto | `-fshort-enums` |
|---|---|---|
| `enum color` (0 a 2) | `unsigned int`, 4 bytes | `unsigned char`, 1 byte |
| `enum delta` (−1 a 1) | `int`, 4 bytes | `signed char`, 1 byte |
| `enum wide` (1 a 300) | `unsigned int`, 4 bytes | `unsigned short`, 2 bytes |

Así queda `BLUE` (2) en memoria en una máquina little-endian:

```text
default:        02 00 00 00
-fshort-enums:  02
```

Las constantes no se encogen, así que ahora `sizeof(enum color) != sizeof(RED)`. El alineamiento sí, así que cambia la disposición de todos los structs que contengan el enum. El manual de GCC es tajante al respecto: la opción "causes GCC to generate code that is not binary compatible with code generated without that switch", es decir, genera código que no es compatible a nivel binario con el generado sin ella. Para encoger un único enum, GCC y Clang aceptan `__attribute__((packed))` en el tipo. Los enums empaquetados tendrán su propio post.

## En Arm, los enums cortos son lo predeterminado

El estándar de llamadas a procedimientos de Arm (AAPCS) deja el tamaño de los enums en manos de la ABI de la plataforma: o bien una palabra, o bien "the smallest integer type that can contain all of its enumerated values", el tipo entero más pequeño que pueda contener todos sus valores. El `arm-none-eabi-gcc` para bare metal elige lo segundo, sin necesidad de opciones:

```text
$ arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c globals.c
$ arm-none-eabi-nm -S globals.o
00000000 00000001 B g_color
00000001 00000001 B g_delta
00000002 00000002 B g_wide
```

Eso son 1, 1 y 2 bytes, sin que nadie lo haya pedido. Otras toolchains de Arm eligieron de otra forma:

| Toolchain | Tamaño de enum por defecto en Arm de 32 bits |
|---|---|
| GCC, bare metal (`arm-none-eabi`) | El tipo más pequeño que quepa |
| GCC, Arm Linux (ABI `aapcs-linux`) | 4 bytes |
| Arm Compiler 5 (`armcc`) | El tipo más pequeño que quepa (`--enum_is_int` para 4 bytes) |
| Arm Compiler 6 (`armclang`, usado por Keil MDK) | 4 bytes (`-fshort-enums` para el más pequeño) |

{{< alert >}}
**Ojo:** si has migrado un proyecto de Keil de Arm Compiler 5 a 6, el valor por defecto se invirtió, y con él el tamaño de todos los enums de tus structs. Mezclar objetos de `armclang` y GCC tiene el mismo problema.
{{< /alert >}}

La buena noticia es que cada fichero objeto de Arm registra su elección:

```text
$ arm-none-eabi-readelf -A globals.o | grep enum
  Tag_ABI_enum_size: small
```

Con `-fno-short-enums` la etiqueta indica `int`, así que el linker de GNU puede avisarte cuando mezclas ambos: `warning: vendor.o uses 32-bit enums yet the output is to use variable-size enums; use of enum values across objects may fail`. x86-64 no tiene una etiqueta así, y su linker no dice nada.

## C23: elegir el tipo tú mismo

C23 te permite fijar el tipo subyacente, con la sintaxis que introdujo C++11:

```c
enum status : uint8_t { ST_OK, ST_ERR };
```

Ahora `enum status` ocupa 1 byte con cualquier compilador y cualquier opción, `-fshort-enums` incluida. Las constantes también toman el tipo del enum, así que `sizeof(ST_OK)` también es 1. GCC lo soporta desde la versión 13, y Clang desde la 20 (o como extensión en modos de lenguaje anteriores).

C23 también permite que los valores de los enumeradores superen `int`:

```c
enum big { B_SMALL = 0, B_HUGE = 0x100000000 };
```

En x86-64, `enum big` pasa a ser un `unsigned long` de 8 bytes, y todas las constantes, `B_SMALL` incluida, toman el tipo del enum.

{{< alert "search" >}}
**¿Sabías que...?** No necesitas valores enormes para superar el límite de `int`: un enum de flags que use el bit 31, `1u << 31`, ya lo hace. Antes de C23, GCC y Clang solo lo aceptan como extensión.
{{< /alert >}}

## Dónde se filtra el tamaño del enum a tu ABI

El tamaño de un enum pasa a formar parte de tu ABI en el momento en que el enum cruza una frontera: un struct compartido con otro binario, un formato de transmisión, un fichero en flash o memoria compartida entre núcleos. Toma un registro que un firmware de Cortex-M envía a una herramienta de escritorio:

```c
enum channel { CH_EEG, CH_EMG, CH_ECG };

struct sample {
    enum channel ch;
    uint8_t      gain;
    uint16_t     value;
};
```

|  | `arm-none-eabi-gcc` (por defecto) | GCC x86-64 (por defecto) |
|---|---|---|
| `sizeof(struct sample)` | 4 | 8 |
| offset de `gain` | 1 | 4 |
| offset de `value` | 2 | 6 |

Misma cabecera, dos disposiciones. Envía `sizeof(struct sample)` bytes por BLE, haz un cast del buffer en el otro lado, y `gain` y `value` salen como basura. Ninguno de los dos compiladores hizo nada mal.

{{< alert "search" >}}
**¿Sabías que...?** Pasar un enum por valor suele ser seguro aunque ambos lados no estén de acuerdo, porque la AAPCS extiende a 32 bits los argumentos enteros más estrechos que una palabra. Lo que pasa por memoria no lo es: miembros de structs, arrays, punteros a enums y cualquier cosa a la que hagas `memcpy`.
{{< /alert >}}

## Reglas que sigo

- **No asumas nunca un tamaño**, ni 4 ni 1. Si tu código depende de una disposición, deja que el compilador la compruebe:

  ```c
  _Static_assert(sizeof(struct sample) == 4,
                 "struct sample layout changed: check enum size");
  ```

- **Mantén los enums fuera de todo lo que cruce una frontera.** Almacena un entero de ancho fijo como `uint8_t ch` y usa el enum solo por sus valores, o usa `enum channel : uint8_t` en C23.
- **Compila todo con la misma configuración de enums**, librerías de terceros incluidas. En Arm, haz que el aviso sobre el tamaño de los enums sea un error con `-Wl,--fatal-warnings`.
- **Comprueba el rango con una única comparación sin signo**: `(unsigned)c < COUNT`.

Dentro de una misma compilación, los nombres son todo lo que necesitas. En cuanto un enum cruza una frontera, necesitas saber cuánto ocupa, y la única forma fiable es elegirlo tú mismo.
