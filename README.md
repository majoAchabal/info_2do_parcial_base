# Match-3 — Segundo Parcial 

## Integrantes
- María José Achabal - 77839
- Isabel Rios - 77682

## Cómo correr el juego
1. Instalar Godot 4.6.
2. Abrir el proyecto desde `project.godot`.
3. Ejecutar `scenes/game.tscn` con F5.

## Mecánicas implementadas
- Puntaje y HUD.
- Límite de movimientos.
- Nivel con tiempo.
- Victoria, derrota y reinicio.
- Sistema de niveles data-driven usando `.tres`.
- Objetivos por puntaje, tiempo y recolección de colores.
- Persistencia de progreso y mejor puntaje con `user://save_game.cfg`.
- Detección de tablero sin jugadas y rebarajado automático.

## Funcionalidades implementadas por Isa

### Pantallas finales
- Popup de victoria y popup de derrota.
- El tablero queda bloqueado cuando termina el nivel.
- Boton Next Level en victoria.
- Boton Retry en derrota.
- Estrellas doradas en victoria y estrellas plateadas en derrota.
- Visualizacion del nivel actual en el popup.
- Mensajes de derrota segun la condicion del nivel.

### Audio
- Musica de fondo con playlist automatica: `theme-1`, `theme-2`, `theme-3`, `theme-4` y vuelve a `theme-1`.
- Sonido para swap valido.
- Sonido para swap invalido.
- Sonido para match o destruccion.
- Sonido para botones.
- Sonido de victoria.
- Sonido de derrota.

### Piezas especiales
- Row.
- Column.
- Adjacent.
- Rainbow.

Creacion de especiales:
- Match de 4 horizontal crea Row.
- Match de 4 vertical crea Column.
- Match de 5 crea Rainbow.
- Match en forma de L o T crea Adjacent.

Activacion de especiales:
- Row limpia una fila completa.
- Column limpia una columna completa.
- Adjacent limpia una zona 3x3.
- Rainbow destruye todas las piezas de un color.

Combos implementados:
- Row + Column.
- Row + Row.
- Column + Column.
- Row + Adjacent.
- Column + Adjacent.
- Adjacent + Adjacent.
- Rainbow + pieza normal.
- Rainbow + Row.
- Rainbow + Column.
- Rainbow + Adjacent.
- Rainbow + Rainbow.

### Objetivos visuales del nivel 3
- Los objetivos se muestran en la barra inferior.
- Hay contador visual para Pink, Yellow y Blue.
- El progreso se actualiza en tiempo real mientras se destruyen piezas objetivo.

### Feedback visual
- Particulas al destruir piezas.
- Shake al activar piezas especiales o combos.
- Textos Great, Amazing y Super cuando se destruyen muchas piezas.
- Popup de shuffling durante el rebarajado.

### Sistema de pistas
- Despues de varios segundos sin movimientos se resalta una jugada valida.
- La pista desaparece cuando el jugador interactua.
- La pista vuelve a aparecer despues de un tiempo de inactividad.

### Assets visuales agregados
Popups:
- `victory_popup.png`
- `failed_popup.png`
- `shuffling.png`
- `great.png`
- `amazing.png`
- `super.png`

Botones:
- `retry.png`
- `next_level.png`
- `home.png`

Decoraciones:
- `gold_star.png`
- `silver_star.png`

## Niveles
### Nivel 1
Objetivo: alcanzar 9250 puntos en 20 movimientos.

### Nivel 2
Objetivo: alcanzar 10000 puntos en 3 minutos.

### Nivel 3
Objetivo: recolectar 20 piezas pink, 10 yellow y 5 blue en 25 movimientos.

## Recursos externos consultados
- Tutorial base de Match-3 en Godot indicado por la consigna.
- Documentación oficial de Godot sobre `Resource`.
- Documentación oficial de Godot sobre `ConfigFile`.
- Documentación oficial de Godot sobre `Timer`.

## Notas técnicas
El sistema de niveles fue separado en archivos `.tres` dentro de la carpeta `levels/`, permitiendo modificar objetivos sin cambiar código.
