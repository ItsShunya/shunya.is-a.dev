---
title: "Por qué elegí un DAS en lugar de un NAS"
summary: "Cómo centralicé nuestras fotos dispersas en un DAS y monté una estrategia de copias de seguridad 3-2-1 a su alrededor."
description: "Por qué elegí un DAS en lugar de un NAS para centralizar años de fotos dispersas, y la estrategia de copias de seguridad 3-2-1 que monté a su alrededor."
categories: [Homelab]
tags: [Homelab, DAS, NAS, Backup]
date: 2026-01-17
draft: false
---

{{< lead >}}
*«No recordamos días, recordamos momentos.»* — Cesare Pavese
{{< /lead >}}

¿Conoces esa sensación de decirte *«no me hace falta»* durante meses, quizá años, y que de repente una noche acabes pulsando *«comprar ahora»*?

Eso me pasó a mí con el almacenamiento.

Durante mucho tiempo me convencí de que el almacenamiento en la nube era suficiente. Google Photos, iCloud... ya está bien así. Luego empecé a viajar más. Mi novia y yo hacemos fotos, muchísimas, y de cada viaje volvíamos con mil más.

Y de repente todo estaba en todas partes.

Sin una estructura clara. Sin una estrategia de copias de seguridad de verdad. Solo una factura de la nube cada vez más alta, copias locales repartidas por nuestros móviles y la esperanza de que nada fallara.

Así es como lo solucioné, y por qué acabé eligiendo un DAS (Direct Attached Storage) en lugar del NAS (Network Attached Storage) que todo el mundo parece recomendar.

## El problema: fotos en todas partes, copias de seguridad en ninguna

Las fotos estaban en móviles, ordenadores y discos externos antiguos. Versiones editadas aquí, originales allá. Algunos archivos existían en varias copias, otros en una sola. ¿Lo peor? Las fotos antiguas de viajes digitalizadas, horas de trabajo, estaban guardadas en un único disco duro que ya tenía sus años.

Eso no es una copia de seguridad. Eso es un riesgo.

Necesitaba un único sitio para todo, y copias de seguridad de verdad.

## ¿Por qué no un NAS?

Si lees foros, la respuesta siempre es: «Cómprate un NAS». Y sí, los NAS son muy potentes. Acceso remoto, aplicaciones, servicios, servidores multimedia.

Pero yo no necesitaba un servidor. Necesitaba almacenamiento.

Un DAS es sencillo:
* conexión directa por USB-C
* sin configuración de red
* sin un sistema encendido todo el tiempo
* menor coste y consumo

El TerraMaster D8 Hybrid me daba ocho ranuras para discos (cuatro bahías de 3,5 pulgadas para discos duros y cuatro ranuras M.2 para SSD NVMe) con una única conexión USB-C de 10 Gbps, sin la complejidad ni el precio de un NAS completo. Se conecta directamente a mi ordenador y simplemente funciona.

La contrapartida es que los datos solo son accesibles desde el ordenador al que está conectado, y cualquier cosa automatizada, como las copias de seguridad, solo se ejecuta mientras ese ordenador está encendido. El acceso remoto puede llegar más adelante. Por ahora, gana la simplicidad.

## Mi configuración de copias de seguridad 3-2-1

Una vez decidí centralizar el almacenamiento, el siguiente paso era más importante que el propio hardware: la estrategia de copias de seguridad.

Ahí es donde entra la regla 3-2-1:
* 3 copias de tus datos
* 2 tipos de almacenamiento distintos
* 1 copia fuera de casa

### Almacenamiento principal

Aquí es donde vive todo.

El D8 Hybrid no hace RAID 5 por sí solo, así que mi ordenador gestiona los cuatro discos duros como un array RAID 5 por software, lo que significa que puedo perder cualquiera de los discos sin perder datos. Un RAID no es una copia de seguridad, pero sí es una buena protección frente a un disco que muere de forma inesperada.

Cuatro discos de 4 TB en RAID 5 me dan unos 12 TB de espacio útil, de sobra para nuestras fotos por ahora. Las cuatro bahías de discos duros están ocupadas, así que crecer implica pasar a discos más grandes, y las ranuras M.2 siguen libres para almacenamiento NVMe rápido. En cualquier caso, no tengo que replantearme toda la configuración cada vez que crece el almacenamiento.

Con el enlace USB-C de 10 Gbps, el rendimiento es más que suficiente. Puedo explorar, editar y gestionar las fotos directamente desde el DAS sin ralentizaciones apreciables. Esta es mi fuente de verdad.

### Copia de seguridad secundaria

La segunda copia vive en un disco duro externo completamente independiente.

Una vez a la semana, todo el DAS se copia automáticamente a este disco. Hardware distinto. Conexión distinta. Guardado en otro sitio del piso.

Esto me protege frente a borrados accidentales, corrupción de archivos, fallos del RAID y el típico «uy, la semana pasada la lié con algo». Si algo sale mal, siempre puedo volver atrás.

### Copia de seguridad fuera de casa

No todo va a la nube. Subir cada archivo RAW sería caro e innecesario. Pero lo importante sí:

* Documentos personales.
* Fotos que no quiero perder.

Eso significa que solo los archivos importantes reciben el tratamiento 3-2-1 completo; todo lo demás tiene dos copias, ambas en casa. Para el grueso de los archivos RAW, es una contrapartida con la que estoy cómodo.

## ¿Mereció la pena?

El TerraMaster D8 Hybrid no fue barato, pero comparado con el valor de unas fotos que no puedo reemplazar, mereció totalmente la pena.

Si te estás diciendo «no me hace falta», hazte una pregunta:

¿Qué pasa si tu almacenamiento actual muere mañana?

Si eso te incomoda, ya tienes tu respuesta.

Lo sé, porque yo era tú no hace mucho.
