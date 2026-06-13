extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var level_label = $MarginContainer/HBoxContainer/HBoxContainer/level_label

var current_score = 0
var current_count = 0
var current_level = 1

# Conecta estos métodos a las señales del tablero (grid.gd), por ejemplo en _ready:
#   var grid = get_parent().get_node("grid")
#   grid.score_changed.connect(update_score)
#   grid.counter_changed.connect(update_counter)

func update_score(nuevo_puntaje: int) -> void:
	current_score = nuevo_puntaje
	score_label.text = str(current_score)

func update_counter(restantes: int) -> void:
	current_count = restantes
	counter_label.text = str(current_count)

func update_level(nivel: int) -> void:
	current_level = nivel
	level_label.text = "Nivel " + str(current_level)
