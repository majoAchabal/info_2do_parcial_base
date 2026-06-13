class_name LevelConfig
extends Resource

# TODO (PARCIAL · M1/M4): punto de partida para niveles dirigidos por datos.
# Crea un archivo .tres por nivel (en el Inspector: New Resource → LevelConfig) y
# carga la lista de niveles desde grid.gd. Puedes añadir, quitar o renombrar campos
# según el diseño de tus objetivos; esto es solo una sugerencia de estructura.

enum Objetivo 
{
	SCORE,
	TIME_SCORE,
	COLLECT
}

@export var nombre: String = "Nivel 1"
@export var objetivo_tipo: Objetivo = Objetivo.SCORE

@export var objetivo_puntaje: int = 0

@export var limite_movimientos: int = 200
@export var limite_segundos: int = 0

@export var objetivo_pink: int = 0
@export var objetivo_yellow: int = 0
@export var objetivo_blue: int = 0

@export var colores_disponibles: Array[String] = [
	"blue", "green", "light_green", "pink", "yellow", "orange",
]
