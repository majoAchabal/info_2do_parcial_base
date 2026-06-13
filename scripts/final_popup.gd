extends CanvasLayer

signal retry_pressed
signal next_level_pressed
signal reset_progress_pressed
signal close_pressed

const VICTORY_TEXTURE := preload("res://assets/popups/victory_popup.png")
const FAILED_TEXTURE := preload("res://assets/popups/failed_popup.png")
const GOLD_STAR_TEXTURE := preload("res://assets/popups/gold_star.png")
const SILVER_STAR_TEXTURE := preload("res://assets/popups/silver_star.png")

@onready var root: Control = $Root
@onready var popup_texture: TextureRect = $Root/PopupTexture
@onready var level_label: Label = $Root/PopupTexture/LevelLabel
@onready var message_label: Label = $Root/PopupTexture/MessageLabel
@onready var next_level_button: TextureButton = $Root/PopupTexture/next_level_button
@onready var retry_button: TextureButton = $Root/PopupTexture/retry_button
@onready var popup_reset_progress_button: TextureButton = $Root/PopupTexture/popup_reset_progress_button
@onready var close_button: Button = $Root/PopupTexture/close_button
@onready var star_left: TextureRect = $Root/PopupTexture/star_left
@onready var star_center: TextureRect = $Root/PopupTexture/star_center
@onready var star_right: TextureRect = $Root/PopupTexture/star_right

const VICTORY_LEVEL_POSITION := Vector2(90, 296)
const FAILED_LEVEL_POSITION := Vector2(90, 315)
const VICTORY_MESSAGE_POSITION := Vector2(76, 340)
const FAILED_MESSAGE_POSITION := Vector2(76, 356)


func _ready() -> void:
	next_level_button.pressed.connect(_on_next_level_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)
	popup_reset_progress_button.pressed.connect(_on_popup_reset_progress_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	hide_popup()


func show_popup(gano: bool, nivel: int, mensaje: String, has_next_level: bool = true) -> void:
	root.visible = true
	popup_texture.texture = VICTORY_TEXTURE if gano else FAILED_TEXTURE
	level_label.text = "Level " + str(nivel)
	message_label.text = mensaje
	next_level_button.visible = gano and has_next_level
	retry_button.visible = not gano
	popup_reset_progress_button.visible = gano and not has_next_level
	close_button.visible = true
	show_stars(GOLD_STAR_TEXTURE if gano else SILVER_STAR_TEXTURE)

	if gano:
		level_label.position = VICTORY_LEVEL_POSITION
		message_label.position = VICTORY_MESSAGE_POSITION
	else:
		level_label.position = FAILED_LEVEL_POSITION
		message_label.position = FAILED_MESSAGE_POSITION


func hide_popup() -> void:
	root.visible = false
	next_level_button.visible = false
	retry_button.visible = false
	popup_reset_progress_button.visible = false
	close_button.visible = false
	star_left.visible = false
	star_center.visible = false
	star_right.visible = false


func show_stars(star_texture: Texture2D) -> void:
	star_left.texture = star_texture
	star_center.texture = star_texture
	star_right.texture = star_texture
	star_left.visible = true
	star_center.visible = true
	star_right.visible = true


func _on_next_level_button_pressed() -> void:
	next_level_pressed.emit()


func _on_retry_button_pressed() -> void:
	retry_pressed.emit()


func _on_popup_reset_progress_button_pressed() -> void:
	reset_progress_pressed.emit()


func _on_close_button_pressed() -> void:
	close_pressed.emit()
