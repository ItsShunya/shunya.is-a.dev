---
title: "Packed enums or -fshort-enums?"
summary: "Same rule, different scope: why shrinking one enum in its header beats shrinking every enum from the command line."
description: "Packed enums vs -fshort-enums in C: how GCC and Clang shrink enums, where the attribute goes, the traps on Arm Cortex-M, and what C23 does better."
categories: [Embedded]
tags: ["Programming Languages", C, ABI, GCC]
series: ["Enums in C"]
series_order: 2
date: 2026-08-31
draft: false
---

{{< lead >}}
*«I have made this letter longer than usual, only because I have not had the time to make it shorter.»* — Blaise Pascal
{{< /lead >}}

In the [previous post](/posts/20260831-enum_storage/), we saw that `-fshort-enums` tells GCC and Clang to give every enum the smallest type that fits, and I promised packed enums their own post.

{{< article link="/posts/20260831-enum_storage/" showSummary=true compactSummary=true >}}

`__attribute__((packed))` does the same thing for a single enum, and GCC's manual says the two are equivalent:

> When attached to an `enum` definition, the `packed` attribute indicates that the smallest integral type should be used. Specifying the `-fshort-enums` flag on the command line is equivalent to specifying the `packed` attribute on all `enum` definitions.

Same rule, same sizes. The difference is where the decision lives: in a flag that changes every enum the compiler sees, or in the header, on the one type that needs it.

As before, the output comes from GCC 15.2 and Clang 21.1 on x86-64 Linux, and the Arm GNU Toolchain 14.3 targeting a Cortex-M4.

## Why Shrink an Enum?

On a microcontroller, three wasted bytes per enum add up. Take a state machine that tracks 64 channels:

```c
enum state { IDLE, RUN, STOP, STATE_COUNT };

enum state table[64];

enum state next_state(enum state s)
{
    return (enum state)((s + 1) % STATE_COUNT);
}
```

On a Cortex-M4 with `-O2`, a 1-byte enum puts `table` in 64 bytes of `.bss` instead of 256. The price is a single `uxtb` in `next_state()`, which truncates the arithmetic back to a byte. Reading the table costs nothing extra: it's an `ldrb` instead of an `ldr`.

## Same Rule, One Type at a Time

```c
enum __attribute__((packed)) color { RED, GREEN, BLUE };
```

Apply `packed` to the three enums from the previous post and you get exactly the `-fshort-enums` results on GCC and Clang: `unsigned char`, `signed char` and `unsigned short`, for 1, 1 and 2 bytes. As with short enums, the constants stay `int`. Using both does no harm: under `-fshort-enums`, `packed` changes nothing.

{{< alert "search" >}}
**Did you know?** A packed enum has nothing in common with a packed struct. A packed struct can put members at unaligned addresses, but a packed enum keeps the natural alignment of its type: the packed `enum wide` is 2 bytes with 2-byte alignment. No unaligned accesses, and no `-Waddress-of-packed-member` warnings.
{{< /alert >}}

## Where the Attribute Goes

```c
enum __attribute__((packed)) a { A0, A1 };            /* 1 byte */
enum b { B0, B1 } __attribute__((packed));            /* 1 byte */
typedef enum { C0, C1 } __attribute__((packed)) c_t;  /* 1 byte */
enum [[gnu::packed]] d { D0, D1 };                    /* 1 byte, C23 syntax */

typedef enum { E0, E1 } e_t __attribute__((packed));  /* 4 bytes, with a warning */
__attribute__((packed)) enum f { F0, F1 };            /* 4 bytes, GCC says nothing */
```

After the typedef name, both compilers warn that the attribute is ignored. Before the `enum` keyword, Clang warns by default and even suggests the fix:

```text
warning: attribute 'packed' is ignored, place it after "enum" to apply attribute to type declaration [-Wignored-attributes]
```

{{< alert >}}
**Be aware:** GCC says nothing, even with `-Wall -Wextra -Wpedantic`. The enum stays 4 bytes and the code compiles cleanly. That's the first reason every packed enum needs a `_Static_assert`.
{{< /alert >}}

## The Decision Lives in the Header

`-fshort-enums` is invisible in the source. You can't tell the size of an enum in a header without checking how every project that includes it is built, and the flag also changes the enums in system and vendor headers. `packed` is part of the type, so every GCC or Clang build that includes the header gets the same size. Here's `sizeof(struct sample)` from the previous post, with a plain and a packed `enum channel`:

| | x86-64 GCC | x86-64 GCC, `-fshort-enums` | `arm-none-eabi-gcc` | `arm-none-eabi-gcc`, `-fno-short-enums` |
|---|---|---|---|---|
| Plain `enum channel` | 8 | 4 | 4 | 8 |
| Packed `enum channel` | 4 | 4 | 4 | 4 |

The firmware and the desktop tool finally agree, and nobody had to touch their build flags.

### What the Arm Linker Sees

A packed enum doesn't change the `Tag_ABI_enum_size` build attribute, because the tag records the build flag, not the types in the file:

```text
$ arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -fno-short-enums -c packed.c
$ arm-none-eabi-readelf -A packed.o | grep enum
  Tag_ABI_enum_size: int
$ arm-none-eabi-nm -S packed.o
00000000 00000001 D g_color
```

For packed enums that's fine, since both sides read the size from the header. But it makes the linker's check coarse. An empty `main()` built with `-fno-short-enums` and linked against the toolchain's own C library already trips it:

```text
$ arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -fno-short-enums --specs=nosys.specs main.c
ld: warning: /tmp/ccUxEXzc.o uses 32-bit enums yet the output is to use variable-size enums; use of enum values across objects may fail
```

There isn't a single enum in the file, yet the warning fires on every build. On bare-metal Arm, leave the default alone and size specific types in the source instead.

{{< alert >}}
**Be aware:** the linker can silence this with `--no-enum-size-warning`. Once that option is in your build, it also hides the warning about a real mismatch.
{{< /alert >}}

## What Packed Doesn't Do

### It doesn't promise one byte

`packed` means "the smallest type that fits", and that changes when the enum changes:

```c
enum __attribute__((packed)) opcode { OP_NOP, OP_READ, OP_WRITE, OP_VENDOR = 256 };
_Static_assert(sizeof(enum opcode) == 1, "enum opcode must fit in one byte");
```

Without the assert, `enum opcode` silently becomes a 2-byte `unsigned short`, even with `-Wall -Wextra -Wpedantic`, and every struct that contains it changes layout. The same assert also catches a misplaced attribute, and a compiler that ignores it.

### It truncates values that don't fit

```c
enum __attribute__((packed)) color { RED, GREEN, BLUE, COLOR_COUNT };

uint16_t raw = 0x0102;           /* corrupted field, should be 0 to 2 */
enum color c = (enum color)raw;  /* c == BLUE */
```

The high byte is dropped, and the corrupted value passes the `(unsigned)c < COLOR_COUNT` check from the previous post as a valid `BLUE`. With a 4-byte enum, `c` would be 258 and the check would reject it. Without the cast, Clang warns under `-Wconversion`; GCC doesn't. Check the raw integer before it becomes an enum:

```c
if (raw >= COLOR_COUNT)
    return false;
```

## Forcing 32 Bits

For the opposite, an enum that stays 4 bytes under any flag, add a value that only fits in 32 bits. CMSIS-RTOS2 does this in most of its enums:

```c
typedef enum {
  osOK                    =  0,
  osError                 = -1,
  /* ... */
  osStatusReserved        = 0x7FFFFFFF  ///< Prevents enum down-size compiler optimization.
} osStatus_t;
```

Different RTOS kernels and compilers implement this API, and the sentinel keeps `osStatus_t` at 4 bytes for all of them.

{{< alert "search" >}}
**Did you know?** Vulkan's headers use the same trick, ending their enums with values like `VK_RESULT_MAX_ENUM = 0x7FFFFFFF`. The sentinel is `0x7FFFFFFF` rather than `0xFFFFFFFF` because, before C23, every enumeration constant has to fit in an `int`.
{{< /alert >}}

The cost is a value that can never happen, but `-Wswitch` still wants it handled:

```text
warning: enumeration value 'osStatusReserved' not handled in switch [-Wswitch]
```

## Portability and C23

MSVC doesn't support `__attribute__`, so a portable header needs a macro. The assert catches any compiler where the macro expands to nothing:

```c
#if defined(__GNUC__) || defined(__clang__)
#  define ENUM_PACKED __attribute__((packed))
#else
#  define ENUM_PACKED
#endif

enum ENUM_PACKED channel { CH_EEG, CH_EMG, CH_ECG };
_Static_assert(sizeof(enum channel) == 1, "enum channel must be 1 byte");
```

If all your compilers support C23, a fixed underlying type beats both. `enum channel : uint8_t` is exactly one byte under any flag, and a value that doesn't fit is a compile error instead of a bigger type: in GCC's words, `enumerator value outside the range of underlying type`.

{{< alert >}}
**Be aware:** don't add `packed` on top of a fixed underlying type. It does nothing, and GCC's warning, `type attributes ignored after type is already defined`, doesn't make that obvious.
{{< /alert >}}

## Which One to Use

| | `-fshort-enums` | `packed` | C23 fixed type | `uint8_t` field |
|---|---|---|---|---|
| Applies to | Every enum in the build | One enum type | One enum type | One struct member |
| Visible in the header | No | Yes | Yes | Yes |
| Same size in every build | No | Yes | Yes | Yes |
| A 1-byte enum gets a value of 256 | Type grows | Type grows | Compile error | Value truncated |
| Keeps the enum type | Yes | Yes | Yes | No |
| Compilers | GCC, Clang | GCC, Clang | GCC 13+, Clang 20+ | All |

A `uint8_t` field is the most portable option, but the debugger shows numbers instead of names, and `-Wswitch` can't check your switches.

## Rules I Follow

**Leave the enum-size flag alone.** On x86-64 or bare-metal Arm, flipping it changes every enum in every header you include.

**Shrink one type at a time, in the header, with a `_Static_assert` next to it.** Use a C23 fixed type where you can, and `packed` where you can't.

**Range-check the raw integer**, not the packed enum you converted it to.

**Pin enums that cross a compiler boundary** with fixed-width fields or a `0x7FFFFFFF` sentinel.

Pascal apologised for a letter he hadn't had time to make shorter. Enums have the opposite problem: one flag makes them all shorter, and that's exactly what makes it dangerous. Taking the time to shrink them one at a time, each with an assert, is what keeps them the same size in every build.
