---
title: "'Hello World': Un Pequeño Comienzo"
summary: "Mi primer post en este nuevo blog — donde empezaré a compartir notas, ideas y cosas que voy aprendiendo por el camino."
description: "Bienvenido a mi blog. Después de terminar mi página web, este post es una pequeña introducción sobre quién soy, a qué me dedico y qué planeo compartir aquí."
categories: [Historia]
tags: [Hello World, Historia]
date: 2025-11-29
draft: false
---

{{< lead >}}
*«El principio es la parte más importante de la obra.»* — Platón
{{< /lead >}}

Hace unos días, mientras escribía el post de presentación del blog — que titulé "Hello World" (¡échale un vistazo si aún no lo has hecho!) — empecé a pensar en esta pequeña tradición. Recordé haber leído algo sobre su origen hace tiempo, así que me pareció un buen tema para la primera entrada... ¿o la segunda? En fin, da igual, me parecía el tema perfecto para empezar.

{{< article link="/posts/20251128-intro/" showSummary=true compactSummary=true >}}

## ¿Qué es "Hello World"?

Cuando alguien empieza a aprender programación, lo primero que suele escribir es un programa llamado **“Hello World”**. Es un trocito de código cuyo único objetivo es mostrar un texto por pantalla. Nada del otro mundo, nada complejo — simplemente una confirmación de que todo funciona: el compilador, el editor, el entorno y, por supuesto, el programador.

Un Hello World no es más que decir: *“Vale, estoy aquí. Empecemos.”*

## Cómo se ve

En la mayoría de lenguajes de alto nivel, imprimir texto por pantalla es extremadamente sencillo. Por ejemplo, en *Python*:

```py
print("Hello, World!")
```

O en *C*, que es un pelín más largo:

```c
#include <stdio.h>

int main(void) {
    printf("Hello, World!\n");
    return 0;
}
```

Aunque estos ejemplos parezcan triviales, representan un momento importante. Son la primera interacción exitosa con un nuevo lenguaje o herramienta.

## Un poco de historia

Este concepto tiene una larga historia. Una de las primeras apariciones conocidas está en **“*A Tutorial Introduction to the Language B*”** (1972), escrito por *Brian Kernighan*. En ese tutorial hay un pequeño programa que simplemente imprime por pantalla *“hello, world”*. Probablemente esa fue la primera vez que apareció esta frase en un ejemplo de programación, el ejemplo del libro se muestra a continuación.

```b
main( ) {
        printf("hello, world");
}
```

{{< alert "search" >}}
El lenguaje *B* en sí era un precursor de *C*. Era un lenguaje simplificado y no tipado desarrollado en Bell Labs, influenciado principalmente por BCPL. Se ejecutaba en el PDP-11 y otros sistemas antiguos, y ayudó a sentar las bases del lenguaje C, más estructurado y potente, que vendría poco después.
{{< /alert >}}

Unos años más tarde, en 1978, *Kernighan* y *Ritchie* publicaron el ya clásico libro *"The C Programming Language"*, típicamente conocido como *K&R*. Este libro contenía un ejemplo de *Hello World* muy parecido al que todavía usamos en *C* hoy en día. Como el libro se volvió muy influyente, el ejemplo del Hello World se convirtió en una tradición estándar en todo el mundo de la programación.

Desde entonces, casi todos los nuevos lenguajes o tutoriales empiezan con alguna variación de *"Hello, World!"*.

## ¡Conoce a 'Blinky'!

Aunque Hello World funciona bien para lenguajes de escritorio o scripting, no tiene mucho sentido en desarrollo embebido.

La mayoría de microcontroladores no tienen:

* una pantalla
* una consola
* una salida estándar
* ni siquiera un sistema operativo

Así que... imprimir texto por pantalla no es una opción.

IEn sistemas embebidos, el equivalente al Hello World se conoce como **"Blinky"**: un pequeño programa que enciende y apaga un LED en bucle. Normalmente este LED forma parte de una placa de desarrollo. Si parpadea, significa que el firmware está corriendo, el reloj está configurado correctamente, la toolchain funciona, el programador flasheó el microcontrolador con éxito, y el dispositivo está vivo.

Un blinky típico en C podría verse así (conceptualmente):

A typical blinky in C might look like this (conceptually):

```c
int main(void) {
    setup_gpio_led();

    while (1) {
        toggle_led();
        delay_ms(500);
    }
}
```

Este pequeño LED parpadeante es la versión del desarrollador embebido de mostrat "Hello, World!". Es la primera confirmación de que el hardware, la toolchain y la configuración del firmware están funcionando correctamente.

## A Simple Beginning

Ya sea un mensaje en la pantalla o un LED parpadeando en una placa, cada proyecto empieza con una pequeña señal: *"Hola, estoy funcionando"*. Es un paso pequeño, pero cargado de significado. A partir de este humilde comienzo, acaban creciendo sistemas y productos enteros.

Para mí, escribir este blog es un poco como ese primer Hello World. Un momento sencillo, pero el inicio de algo nuevo.

Pronto vendrán más posts — y espero que más interesantes que LEDs parpadeando.