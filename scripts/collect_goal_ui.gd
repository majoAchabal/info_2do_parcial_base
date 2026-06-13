extends Control

@onready var pink_label: Label = $HBoxContainer/PinkGoal/PinkLabel
@onready var yellow_label: Label = $HBoxContainer/YellowGoal/YellowLabel
@onready var blue_label: Label = $HBoxContainer/BlueGoal/BlueLabel

var pink_goal = 0
var yellow_goal = 0
var blue_goal = 0


func _ready() -> void:
	visible = false


func setup_goals(is_collect_level: bool, new_pink_goal: int, new_yellow_goal: int, new_blue_goal: int) -> void:
	visible = is_collect_level
	pink_goal = new_pink_goal
	yellow_goal = new_yellow_goal
	blue_goal = new_blue_goal
	update_progress(0, 0, 0)


func update_progress(pink: int, yellow: int, blue: int) -> void:
	pink_label.text = str(min(pink, pink_goal)) + "/" + str(pink_goal)
	yellow_label.text = str(min(yellow, yellow_goal)) + "/" + str(yellow_goal)
	blue_label.text = str(min(blue, blue_goal)) + "/" + str(blue_goal)
