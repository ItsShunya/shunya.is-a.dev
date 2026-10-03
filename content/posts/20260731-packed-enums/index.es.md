---
title: "Enums empaquetados vs -fshort-enums"
summary: "Misma regla, distinto alcance: por qué encoger un enum en su cabecera es mejor que encogerlos todos desde la línea de comandos."
description: "Enums empaquetados vs -fshort-enums en C: cómo encogen los enums GCC y Clang, dónde va el atributo, las trampas en Arm Cortex-M y qué hace mejor C23."
categories: [Embebidos]
tags: ["Lenguajes de Programación", C, ABI, GCC]
series: ["Enums en C"]
series_order: 2
date: 2026-07-31
draft: false
---

{{< lead >}}
*«He hecho esta carta más larga de lo habitual solo porque no he tenido tiempo de hacerla más corta.»* — Blaise Pascal
{{< /lead >}}

En el [post anterior](/es/posts/20260715-enum_storage/) vimos que `-fshort-enums` le dice a GCC y Clang que den a cada enum el tipo más pequeño en el que quepa, y prometí que los enums empaquetados tendrían su propio post.

{{< article link="/es/posts/20260715-enum_storage/" showSummary=true compactSummary=true >}}

`__attribute__((packed))` hace lo mismo para un único enum, y el manual de GCC dice que ambos son equivalentes:

> When attached to an `enum` definition, the `packed` attribute indicates that the smallest integral type should be used. Specifying the `-fshort-enums` flag on the command line is equivalent to specifying the `packed` attribute on all `enum` definitions.

Es decir, `packed` en un `enum` indica que se use el tipo entero más pequeño, y pasar `-fshort-enums` equivale a ponerle `packed` a todos los enums. Misma regla, mismos tamaños. La diferencia es dónde vive la decisión: en una opción que cambia todos los enums que ve el compilador, o en la cabecera, en el único tipo que lo necesita.

Como antes, la salida proviene de GCC 15.2 y Clang 21.1 en Linux x86-64, y de la Arm GNU Toolchain 14.3 compilando para un Cortex-M4.

## ¿Por qué encoger un enum?

En un microcontrolador, tres bytes desperdiciados por enum se acaban notando. Toma una máquina de estados que sigue 64 canales:

```c
enum state { IDLE, RUN, STOP, STATE_COUNT };

enum state table[64];

enum state next_state(enum state s)
{
    return (enum state)((s + 1) % STATE_COUNT);
}
```

En un Cortex-M4 con `-O2`, un enum de 1 byte deja `table` en 64 bytes de `.bss` en lugar de 256. El precio es un único `uxtb` en `next_state()`, que trunca el resultado de la aritmética de vuelta a un byte. Leer la tabla no cuesta nada extra: es un `ldrb` en lugar de un `ldr`.

## Misma regla, un tipo cada vez

```c
enum __attribute__((packed)) color { RED, GREEN, BLUE };
```

Aplica `packed` a los tres enums del post anterior y obtendrás exactamente los resultados de `-fshort-enums` en GCC y Clang: `unsigned char`, `signed char` y `unsigned short`, es decir, 1, 1 y 2 bytes. Igual que con los enums cortos, las constantes siguen siendo `int`. Usar ambos no hace daño: con `-fshort-enums`, `packed` no cambia nada.

{{< alert "search" >}}
**¿Sabías que...?** Un enum empaquetado no tiene nada que ver con un struct empaquetado. Un struct empaquetado puede colocar miembros en direcciones no alineadas, pero un enum empaquetado mantiene el alineamiento natural de su tipo: el `enum wide` empaquetado ocupa 2 bytes con alineamiento de 2 bytes. Sin accesos no alineados y sin avisos de `-Waddress-of-packed-member`.
{{< /alert >}}

## Dónde va el atributo

```c
enum __attribute__((packed)) a { A0, A1 };            /* 1 byte */
enum b { B0, B1 } __attribute__((packed));            /* 1 byte */
typedef enum { C0, C1 } __attribute__((packed)) c_t;  /* 1 byte */
enum [[gnu::packed]] d { D0, D1 };                    /* 1 byte, sintaxis C23 */

typedef enum { E0, E1 } e_t __attribute__((packed));  /* 4 bytes, con un aviso */
__attribute__((packed)) enum f { F0, F1 };            /* 4 bytes, GCC no dice nada */
```

Después del nombre del typedef, ambos compiladores avisan de que el atributo se ignora. Antes de la palabra clave `enum`, Clang avisa por defecto e incluso sugiere la solución:

```text
warning: attribute 'packed' is ignored, place it after "enum" to apply attribute to type declaration [-Wignored-attributes]
```

{{< alert >}}
**Ojo:** GCC no dice nada, ni siquiera con `-Wall -Wextra -Wpedantic`. El enum sigue ocupando 4 bytes y el código compila sin una sola queja. Esa es la primera razón por la que todo enum empaquetado necesita un `_Static_assert`.
{{< /alert >}}

## La decisión vive en la cabecera

`-fshort-enums` es invisible en el código fuente. No puedes saber el tamaño de un enum de una cabecera sin comprobar cómo se compila cada proyecto que la incluye, y además la opción cambia también los enums de las cabeceras del sistema y de terceros. `packed` forma parte del tipo, así que toda compilación con GCC o Clang que incluya la cabecera obtiene el mismo tamaño. Este es el `sizeof(struct sample)` del post anterior, con un `enum channel` normal y uno empaquetado:

| | GCC x86-64 | GCC x86-64, `-fshort-enums` | `arm-none-eabi-gcc` | `arm-none-eabi-gcc`, `-fno-short-enums` |
|---|---|---|---|---|
| `enum channel` normal | 8 | 4 | 4 | 8 |
| `enum channel` empaquetado | 4 | 4 | 4 | 4 |

Por fin el firmware y la herramienta de escritorio están de acuerdo, y nadie ha tenido que tocar sus opciones de compilación.

### Lo que ve el linker de Arm

Un enum empaquetado no cambia el atributo de compilación `Tag_ABI_enum_size`, porque la etiqueta registra la opción de compilación, no los tipos del fichero:

```text
$ arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -fno-short-enums -c packed.c
$ arm-none-eabi-readelf -A packed.o | grep enum
  Tag_ABI_enum_size: int
$ arm-none-eabi-nm -S packed.o
00000000 00000001 D g_color
```

Para los enums empaquetados no pasa nada, ya que ambos lados leen el tamaño de la cabecera. Pero hace que la comprobación del linker sea poco precisa. Un `main()` vacío compilado con `-fno-short-enums` y enlazado contra la propia librería de C de la toolchain ya la dispara:

```text
$ arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -fno-short-enums --specs=nosys.specs main.c
ld: warning: /tmp/ccUxEXzc.o uses 32-bit enums yet the output is to use variable-size enums; use of enum values across objects may fail
```

No hay ni un solo enum en el fichero, y aun así el aviso salta en cada compilación. En Arm bare metal, deja el valor por defecto como está y fija el tamaño de tipos concretos en el código fuente.

{{< alert >}}
**Ojo:** el linker puede silenciar esto con `--no-enum-size-warning`. Una vez que esa opción está en tu compilación, también oculta el aviso cuando la discrepancia es real.
{{< /alert >}}

## Lo que `packed` no hace

### No promete un byte

`packed` significa "el tipo más pequeño en el que quepa", y eso cambia cuando cambia el enum:

```c
enum __attribute__((packed)) opcode { OP_NOP, OP_READ, OP_WRITE, OP_VENDOR = 256 };
_Static_assert(sizeof(enum opcode) == 1, "enum opcode must fit in one byte");
```

Sin el assert, `enum opcode` pasa silenciosamente a ser un `unsigned short` de 2 bytes, incluso con `-Wall -Wextra -Wpedantic`, y todos los structs que lo contienen cambian de disposición. El mismo assert también detecta un atributo mal colocado, y un compilador que lo ignora.

### Trunca los valores que no caben

```c
enum __attribute__((packed)) color { RED, GREEN, BLUE, COLOR_COUNT };

uint16_t raw = 0x0102;           /* campo corrupto, debería estar entre 0 y 2 */
enum color c = (enum color)raw;  /* c == BLUE */
```

El byte alto se descarta, y el valor corrupto pasa la comprobación `(unsigned)c < COLOR_COUNT` del post anterior como un `BLUE` válido. Con un enum de 4 bytes, `c` valdría 258 y la comprobación lo rechazaría. Sin el cast, Clang avisa con `-Wconversion`; GCC no. Comprueba el entero en bruto antes de que se convierta en un enum:

```c
if (raw >= COLOR_COUNT)
    return false;
```

## Forzar 32 bits

Para lo contrario, un enum que siga ocupando 4 bytes con cualquier opción, añade un valor que solo quepa en 32 bits. CMSIS-RTOS2 lo hace en la mayoría de sus enums:

```c
typedef enum {
  osOK                    =  0,
  osError                 = -1,
  /* ... */
  osStatusReserved        = 0x7FFFFFFF  ///< Prevents enum down-size compiler optimization.
} osStatus_t;
```

Distintos kernels de RTOS y compiladores implementan esta API, y el valor centinela mantiene `osStatus_t` en 4 bytes para todos ellos.

{{< alert "search" >}}
**¿Sabías que...?** Las cabeceras de Vulkan usan el mismo truco, terminando sus enums con valores como `VK_RESULT_MAX_ENUM = 0x7FFFFFFF`. El centinela es `0x7FFFFFFF` y no `0xFFFFFFFF` porque, antes de C23, toda constante de enumeración tiene que caber en un `int`.
{{< /alert >}}

El coste es un valor que nunca puede darse, pero que `-Wswitch` aun así quiere que gestiones:

```text
warning: enumeration value 'osStatusReserved' not handled in switch [-Wswitch]
```

## Portabilidad y C23

MSVC no soporta `__attribute__`, así que una cabecera portable necesita una macro. El assert detecta cualquier compilador en el que la macro se expanda a nada:

```c
#if defined(__GNUC__) || defined(__clang__)
#  define ENUM_PACKED __attribute__((packed))
#else
#  define ENUM_PACKED
#endif

enum ENUM_PACKED channel { CH_EEG, CH_EMG, CH_ECG };
_Static_assert(sizeof(enum channel) == 1, "enum channel must be 1 byte");
```

Si todos tus compiladores soportan C23, un tipo subyacente fijo es mejor que ambas opciones. `enum channel : uint8_t` ocupa exactamente un byte con cualquier opción, y un valor que no cabe es un error de compilación en lugar de un tipo más grande: en palabras de GCC, `enumerator value outside the range of underlying type`.

{{< alert >}}
**Ojo:** no añadas `packed` encima de un tipo subyacente fijo. No hace nada, y el aviso de GCC, `type attributes ignored after type is already defined`, no lo deja nada claro.
{{< /alert >}}

## Cuál usar

| | `-fshort-enums` | `packed` | Tipo fijo de C23 | Campo `uint8_t` |
|---|---|---|---|---|
| Se aplica a | Todos los enums de la compilación | Un tipo enum | Un tipo enum | Un miembro de un struct |
| Visible en la cabecera | No | Sí | Sí | Sí |
| Mismo tamaño en todas las compilaciones | No | Sí | Sí | Sí |
| Un enum de 1 byte recibe el valor 256 | El tipo crece | El tipo crece | Error de compilación | Valor truncado |
| Conserva el tipo enum | Sí | Sí | Sí | No |
| Compiladores | GCC, Clang | GCC, Clang | GCC 13+, Clang 20+ | Todos |

Un campo `uint8_t` es la opción más portable, pero el depurador muestra números en lugar de nombres, y `-Wswitch` no puede comprobar tus switches.

## Reglas que sigo

**No toques la opción del tamaño de los enums.** En x86-64 o en Arm bare metal, cambiarla altera todos los enums de todas las cabeceras que incluyes.

**Encoge un tipo cada vez, en la cabecera, con un `_Static_assert` al lado.** Usa un tipo fijo de C23 donde puedas, y `packed` donde no.

**Comprueba el rango del entero en bruto**, no del enum empaquetado al que lo has convertido.

**Fija los enums que cruzan la frontera entre compiladores** con campos de ancho fijo o un centinela `0x7FFFFFFF`.

Pascal se disculpaba por una carta que no había tenido tiempo de hacer más corta. Los enums tienen el problema contrario: una sola opción los hace a todos más cortos, y eso es precisamente lo que la hace peligrosa. Tomarse el tiempo de encogerlos uno a uno, cada uno con su assert, es lo que hace que ocupen lo mismo en todas las compilaciones.
