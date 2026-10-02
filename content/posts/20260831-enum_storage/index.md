---
title: "Your C enum might be 1 byte"
summary: "What the C standard promises about enums, what GCC, Clang, MSVC and Arm compilers actually do with that freedom, and how to keep enums from breaking your ABI."
description: "How C stores enums in memory: enumeration constants vs. enumerated types, compiler choices, sizeof(enum), -fshort-enums, C23 fixed underlying types and the ABI traps on Arm Cortex-M."
categories: [Embedded]
tags: ["Programming Languages", C, ABI]
series: ["Enums in C"]
series_order: 1
date: 2026-07-31
draft: false
---

{{< lead >}}
*«What's in a name? That which we call a rose by any other name would smell as sweet.»* — William Shakespeare
{{< /lead >}}

Enums look like the least interesting feature of C. You list a few names, the compiler numbers them from zero, and you move on.

Until a struct shared between your firmware and a desktop tool stops lining up, and the culprit is a three-value enum that takes one byte on one side and four on the other. Same names, same values, different storage.

Here's what the C standard promises about enums, what compilers do with the freedom it leaves them, and how to keep enums from breaking your ABI. All output comes from GCC 15.3 and Clang 21.1 on x86-64 Linux, and the Arm GNU Toolchain 14.3 targeting a Cortex-M4.

## Two Things Called "Enum"

```c
enum color { RED, GREEN, BLUE };
```

This one line declares two different things:

- **Enumeration constants**: `RED`, `GREEN` and `BLUE`. Up to C17, they are always `int`.
- **An enumerated type**: `enum color`. This is what ends up in memory.

The standard pins down the first and leaves the second open (C17 §6.7.2.2):

> Each enumerated type shall be compatible with `char`, a signed integer type, or an unsigned integer type. The choice of type is implementation-defined, but shall be capable of representing the values of all the members of the enumeration.

So `sizeof(RED)` is always `sizeof(int)`, but `sizeof(enum color)` can be 1, 2, 4 or 8 bytes, stored exactly like whichever integer type the compiler picked.

## What GCC, Clang and MSVC Choose

Since an enumerated type is compatible with exactly one integer type, C11's `_Generic` can name it. Every table in this post comes from this probe:

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

GCC and Clang use `unsigned int` unless a value is negative, and `int` otherwise. On x86-64 with default flags:

| Declaration | Values | Compatible type | `sizeof` |
|---|---|---|---|
| `enum color { RED, GREEN, BLUE }` | 0 to 2 | `unsigned int` | 4 |
| `enum delta { DOWN = -1, STAY, UP }` | −1 to 1 | `int` | 4 |
| `enum wide { W_SMALL = 1, W_BIG = 300 }` | 1 to 300 | `unsigned int` | 4 |

The constants stay `int` in every case. MSVC keeps it simple: a C enum there is always a 4-byte `int`.

{{< alert >}}
**Be aware:** signedness leaks into your code. On GCC and Clang, `c >= 0` is always true for an `enum color` (Clang flags it with `-Wtautological-unsigned-enum-zero-compare`). A check like `c >= 0 && c < COLOR_COUNT` still rejects `(enum color)-1`, but GCC and Clang reject it in the second comparison and MSVC in the first. `(unsigned)c < COLOR_COUNT` means the same thing everywhere.
{{< /alert >}}

## Short Enums

`-fshort-enums` makes GCC and Clang pick the smallest type that fits, signed only if a value is negative:

| Declaration | Default | `-fshort-enums` |
|---|---|---|
| `enum color` (0 to 2) | `unsigned int`, 4 bytes | `unsigned char`, 1 byte |
| `enum delta` (−1 to 1) | `int`, 4 bytes | `signed char`, 1 byte |
| `enum wide` (1 to 300) | `unsigned int`, 4 bytes | `unsigned short`, 2 bytes |

Here's `BLUE` (2) in memory on a little-endian machine:

```text
default:        02 00 00 00
-fshort-enums:  02
```

The constants don't shrink, so now `sizeof(enum color) != sizeof(RED)`. The alignment does, so every struct containing the enum changes layout. GCC's manual is blunt about it: the flag "causes GCC to generate code that is not binary compatible with code generated without that switch." To shrink a single enum instead, GCC and Clang accept `__attribute__((packed))` on the type. Packed enums will get their own post.

## On Arm, Short Enums Are the Default

The Arm procedure call standard (AAPCS) leaves enum size to the platform ABI: either a word, or "the smallest integer type that can contain all of its enumerated values." Bare-metal `arm-none-eabi-gcc` picks the second, no flags needed:

```text
$ arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c globals.c
$ arm-none-eabi-nm -S globals.o
00000000 00000001 B g_color
00000001 00000001 B g_delta
00000002 00000002 B g_wide
```

That's 1, 1 and 2 bytes, without anyone asking for it. Other Arm toolchains chose differently:

| Toolchain | Default enum size on 32-bit Arm |
|---|---|
| GCC, bare metal (`arm-none-eabi`) | Smallest type that fits |
| GCC, Arm Linux (`aapcs-linux` ABI) | 4 bytes |
| Arm Compiler 5 (`armcc`) | Smallest type that fits (`--enum_is_int` for 4 bytes) |
| Arm Compiler 6 (`armclang`, used by Keil MDK) | 4 bytes (`-fshort-enums` for the smallest) |

{{< alert >}}
**Be aware:** if you've migrated a Keil project from Arm Compiler 5 to 6, the default flipped, and so did the size of every enum in your structs. Mixing `armclang` and GCC objects has the same problem.
{{< /alert >}}

The good news is that every Arm object file records its choice:

```text
$ arm-none-eabi-readelf -A globals.o | grep enum
  Tag_ABI_enum_size: small
```

With `-fno-short-enums` the tag reads `int`, so the GNU linker can warn you when you mix the two: `warning: vendor.o uses 32-bit enums yet the output is to use variable-size enums; use of enum values across objects may fail`. x86-64 has no such tag, and its linker stays silent.

## C23: Choosing the Type Yourself

C23 lets you fix the underlying type, with the syntax C++11 introduced:

```c
enum status : uint8_t { ST_OK, ST_ERR };
```

`enum status` is now 1 byte with every compiler and every flag, `-fshort-enums` included. The constants take the enum's type too, so `sizeof(ST_OK)` is 1 as well. GCC supports this from version 13, and Clang from version 20 (or as an extension in older language modes).

C23 also lets enumerator values exceed `int`:

```c
enum big { B_SMALL = 0, B_HUGE = 0x100000000 };
```

On x86-64, `enum big` becomes an 8-byte `unsigned long`, and every constant, `B_SMALL` included, takes the enum's type.

{{< alert "search" >}}
**Did you know?** You don't need huge values to cross the `int` limit: a flags enum that uses bit 31, `1u << 31`, already does. Before C23, GCC and Clang only accept it as an extension.
{{< /alert >}}

## Where Enum Size Leaks into Your ABI

Enum size becomes part of your ABI the moment an enum crosses a boundary: a struct shared with another binary, a wire format, a file in flash, or memory shared between cores. Take a record that Cortex-M firmware sends to a desktop tool:

```c
enum channel { CH_EEG, CH_EMG, CH_ECG };

struct sample {
    enum channel ch;
    uint8_t      gain;
    uint16_t     value;
};
```

|  | `arm-none-eabi-gcc` (default) | x86-64 GCC (default) |
|---|---|---|
| `sizeof(struct sample)` | 4 | 8 |
| offset of `gain` | 1 | 4 |
| offset of `value` | 2 | 6 |

Same header, two layouts. Send `sizeof(struct sample)` bytes over BLE, cast the buffer on the other side, and `gain` and `value` come out as garbage. Neither compiler did anything wrong.

{{< alert "search" >}}
**Did you know?** Passing an enum by value is usually safe even when both sides disagree, because the AAPCS extends integer arguments narrower than a word to 32 bits. Anything that goes through memory isn't: struct members, arrays, pointers to enums, and anything you `memcpy`.
{{< /alert >}}

## Rules I Follow

- **Never assume a size**, not 4 and not 1. If your code depends on a layout, let the compiler check it:

  ```c
  _Static_assert(sizeof(struct sample) == 4,
                 "struct sample layout changed: check enum size");
  ```

- **Keep enums out of anything that crosses a boundary.** Store a fixed-width integer like `uint8_t ch` and use the enum only for its values, or use `enum channel : uint8_t` in C23.
- **Build everything with the same enum setting**, vendor libraries included. On Arm, make the enum-size warning fatal with `-Wl,--fatal-warnings`.
- **Range-check with one unsigned comparison**: `(unsigned)c < COUNT`.

Inside a single build, the names are all you need. Once an enum crosses a boundary, you need to know how big it is, and the only reliable way is to choose it yourself.
