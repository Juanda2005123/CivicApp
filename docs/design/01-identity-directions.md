# VIGÍA: tres direcciones de identidad (paso 1)

Rama: `design/design-system-proposal`. Estado: **propuesta, a la espera de elección**. No se ha modificado código de la app.

## Qué se observó en la app actual

Capturas de login, registro y resumen del perfil (develop, 2026-10-26):

- El único rasgo de marca es un orbe de vidrio con un ojo y la etiqueta "VEEDURÍA VIAL". No hay logo ni nada que hable de vías, comunidad o Colombia.
- El fondo es una foto de ciudad difuminada y las tarjetas son de "vidrio". El acento es un índigo genérico.
- Tres lenguajes visuales conviven: login y registro (vidrio), resumen (tarjeta blanca plana con un banner verde) y un botón rojo plano de "Log Out".
- Textos mezclados: inglés casi en todo, español en "6+ caracteres", "Mayúscula (A-Z)" y "VEEDURÍA VIAL".
- El botón principal es un negro con halo borroso que no se parece a ningún otro control.
- El resumen del perfil es el único lugar donde aparecen rango y puntos, y los muestra como filas de texto; la gamificación (rangos, XP, insignias) no tiene identidad propia.
- El banner "Successfully logged in!" ocupa el lugar más prominente de la pantalla y no dice nada que el usuario no sepa.

## Las tres direcciones

| | A. Señal | B. Tejido | C. Bitácora |
|---|---|---|---|
| Idea | Lenguaje de la vía: asfalto, demarcación, señalética | La comunidad: muchas voces que se juntan | La evidencia: auditor con visor, sello y registro |
| Personalidad | Firme, directa, visible | Cálida, cercana, esperanzadora | Rigurosa, transparente, sobria |
| Logo | Una V cuyo centro lleva las rayas de la vía | Tres círculos que se superponen | Visor de cámara alrededor de una V |
| Base | Asfalto `#1B1F23` y tiza `#F4F2EA` | Verde azulado `#14505C` y crema `#FBF3E4` | Azul tinta `#14213D` y papel `#F7F5F0` |
| Acento | Amarillo de demarcación `#FFC20E` | Arcilla `#C8553D` y mostaza `#E3A72F` | Naranja sello `#E4572E` |
| Tipografía | Barlow Semi Condensed + Source Sans 3 | Fraunces + Nunito Sans | IBM Plex Sans + IBM Plex Mono |
| Riesgo | El amarillo de marca puede confundirse con la gravedad "Medium" | Menos autoridad para una app de denuncia; la arcilla es un tono muy usado | Puede sentirse fría o burocrática |

## Recomendación: A. Señal, con un rasgo prestado de C

Por qué A:

1. **Es la única que habla de lo que hace la app.** Una app sobre vías, huecos y señalización puede hablar con los códigos visuales de la propia vía; eso le da identidad inmediata y nada que ver con una app de plantilla.
2. **Funciona donde se usa.** La app se usa en la calle, a pleno sol, con una mano. Tinta casi negra sobre fondo tiza y un acento amarillo de alto contraste (el texto oscuro sobre amarillo supera 12:1) son los pares más legibles de las tres opciones.
3. **Escala a lo que viene.** La escala de gravedad (Low a Critical), los marcadores del mapa y las insignias se apoyan en un vocabulario de señalización que la gente ya entiende.
4. **Es sobria con carácter**, lo que se pide en el brief: una institución ciudadana joven, no una fintech.

Lo que se toma de C: los datos con fuente monoespaciada (el código `#VIG-8492`, coordenadas, fechas), que refuerzan la sensación de registro verificable.

Riesgos a resolver en el paso 2:

- **Amarillo de marca frente a gravedad.** La escala de gravedad usará su propia rampa (con icono y texto, nunca solo color) y el amarillo de marca se reservará a acciones y énfasis de marca, no a estados.
- **Modo oscuro.** El asfalto como fondo funciona de forma natural; hay que definir cómo se invierte la tiza.
- **Rango "Level 1 a 4".** Los cuatro rangos (Urban Observer, Active Neighbor, Road Guardian, Master Overseer) necesitan una progresión visual propia que no compita con la gravedad.

## Decisión pendiente: idioma de la interfaz

Los usuarios son colombianos y la app hoy está mayormente en inglés. **Recomendación: español** para toda la interfaz, con los nombres de rango y de insignias traducidos (el código y los identificadores siguen en inglés, como pide `AGENTS.md`). Consecuencias: hay que traducir unas 40 cadenas visibles hoy y el test de widgets que busca textos en inglés se actualiza; el microcopy gana en cercanía y en consistencia. La decisión es tuya.
