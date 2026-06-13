extends CanvasLayer

const VICTORY_TEXTURE := preload("res://assets/popups/victory_popup.png")
const FAILED_TEXTURE := preload("res://assets/popups/failed_popup.png")

@onready var root: Control = $Root
@onready var popup_texture: TextureRect = $Root/PopupTexture
@onready var level_label: Label = $Root/PopupTexture/LevelLabel
@onready var message_label: Label = $Root/PopupTexture/MessageLabel

const VICTORY_LEVEL_POSITION := Vector2(90, 296)
const FAILED_LEVEL_POSITION := Vector2(90, 315)
const VICTORY_MESSAGE_POSITION := Vector2(76, 340)
const FAILED_MESSAGE_POSITION := Vector2(76, 356)


func _ready() -> void:
	hide_popup()


func show_popup(gano: bool, nivel: int, mensaje: String) -> void:
	root.visible = true
	popup_texture.texture = VICTORY_TEXTURE if gano else FAILED_TEXTURE
	level_label.text = "Level " + str(nivel)
	message_label.text = mensaje

	if gano:
		level_label.position = VICTORY_LEVEL_POSITION
		message_label.position = VICTORY_MESSAGE_POSITION
	else:
		level_label.position = FAILED_LEVEL_POSITION
		message_label.position = FAILED_MESSAGE_POSITION


func hide_popup() -> void:
	root.visible = false
