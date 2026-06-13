extends Node2D

@export var color: String

var matched = false
var special_type: String = ""

const SPECIAL_TEXTURES = {
	"blue": {
		"row": preload("res://assets/pieces/Blue Row.png"),
		"column": preload("res://assets/pieces/Blue Column.png"),
		"adjacent": preload("res://assets/pieces/Blue Adjacent.png"),
	},
	"green": {
		"row": preload("res://assets/pieces/Green Row.png"),
		"column": preload("res://assets/pieces/Green Column.png"),
		"adjacent": preload("res://assets/pieces/Green Adjacent.png"),
	},
	"light_green": {
		"row": preload("res://assets/pieces/Light Green Row.png"),
		"column": preload("res://assets/pieces/Light Green Column.png"),
		"adjacent": preload("res://assets/pieces/Light Green Adjacent.png"),
	},
	"orange": {
		"row": preload("res://assets/pieces/Orange Row.png"),
		"column": preload("res://assets/pieces/Orange Column.png"),
		"adjacent": preload("res://assets/pieces/Orange Adjacent.png"),
	},
	"pink": {
		"row": preload("res://assets/pieces/Pink Row.png"),
		"column": preload("res://assets/pieces/Pink Column.png"),
		"adjacent": preload("res://assets/pieces/Pink Adjacent.png"),
	},
	"yellow": {
		"row": preload("res://assets/pieces/Yellow Row.png"),
		"column": preload("res://assets/pieces/Yellow Column.png"),
		"adjacent": preload("res://assets/pieces/Yellow Adjacent.png"),
	},
}

const RAINBOW_TEXTURE = preload("res://assets/pieces/Rainbow.png")

# TODO (PARCIAL · M3): para las piezas especiales podrías guardar aquí su tipo
# (por ejemplo, "fila", "columna" o "bomba") y exponer un método que dispare su
# efecto sobre el tablero cuando se active.

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)


func set_special(type: String):
	special_type = type
	matched = false
	$Sprite2D.modulate = Color(1, 1, 1, 1)

	if special_type == "rainbow":
		$Sprite2D.texture = RAINBOW_TEXTURE
	elif SPECIAL_TEXTURES.has(color) and SPECIAL_TEXTURES[color].has(special_type):
		$Sprite2D.texture = SPECIAL_TEXTURES[color][special_type]
