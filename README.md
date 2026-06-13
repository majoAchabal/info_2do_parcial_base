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
