extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false
var pending_player_move = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# === Temporizadores del ciclo destruir → colapsar → rellenar ===
# Son nodos hijos de "grid"; el editor conecta sus señales "timeout" a este script.
@onready var destroy_timer: Timer = $destroy_timer
@onready var collapse_timer: Timer = $collapse_timer
@onready var refill_timer: Timer = $refill_timer
@onready  var level_timer: Timer  = Timer.new()

# === PUNTAJE (B1) y CONTADOR (B2) ===
# Contrato sugerido para comunicarte con el HUD (top_ui.gd). No es obligatorio usar
# señales, pero ayuda a mantener la UI desacoplada de la lógica del tablero:
#   signal score_changed(nuevo_puntaje: int)
#   signal counter_changed(restantes: int)        # movimientos o segundos, tú decides
#   signal game_finished(gano: bool)
signal score_changed(nuevo_puntaje: int)
signal counter_changed(restantes: int)
signal level_changed(nivel: int)
signal game_finished(gano: bool)
signal final_popup_requested(gano: bool, nivel: int, mensaje: String, has_next_level: bool)
signal collect_goals_changed(is_collect_level: bool, pink_goal: int, yellow_goal: int, blue_goal: int)
signal collect_progress_changed(pink: int, yellow: int, blue: int)

var current_score = 0
var moves_left = 20
var target_score = 10000

#Levels
@export var levels: Array[LevelConfig] = []
var current_level_index = 0
var level_data: LevelConfig

var time_left = 0

var collected_pink = 0
var collected_yellow = 0
var collected_blue = 0

# Persistencia de datos
const SAVE_PATH := "user://save_game.cfg"

var unlocked_level = 0
var best_score = 0
var is_game_finished = false
var final_popup = null
var shuffle_popup = null
var audio_manager = null
var collect_goal_ui = null


# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	
	var ui = get_parent().get_node("top_ui")
	final_popup = get_parent().get_node_or_null("FinalPopup")
	shuffle_popup = get_parent().get_node_or_null("ShufflingPopup")
	audio_manager = get_parent().get_node_or_null("AudioManager")
	collect_goal_ui = get_parent().get_node_or_null("CollectGoalUI")
	
	score_changed.connect(ui.update_score)
	counter_changed.connect(ui.update_counter)
	level_changed.connect(ui.update_level)
	if final_popup != null:
		final_popup_requested.connect(final_popup.show_popup)
		final_popup.retry_pressed.connect(retry_level)
		final_popup.next_level_pressed.connect(go_to_next_level)
		final_popup.reset_progress_pressed.connect(_on_reset_progress_button_pressed)
		final_popup.close_pressed.connect(close_game)
	if collect_goal_ui != null:
		collect_goals_changed.connect(collect_goal_ui.setup_goals)
		collect_progress_changed.connect(collect_goal_ui.update_progress)
	
	load_progress()
	
	load_level()
	
	add_child(level_timer)
	
	if time_left > 0:
		level_timer.wait_time = 1.0
		level_timer.timeout.connect(_on_level_timer_timeout)
		level_timer.start()
	
	score_changed.emit(current_score)
	counter_changed.emit(get_counter_value())
	level_changed.emit(current_level_index + 1)

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	return false

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2, consume_move:=true):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	# TODO (PARCIAL · M3): si alguna de las piezas intercambiadas es especial,
	# actívala aquí (su efecto reemplaza a la búsqueda normal de combinaciones).
	# TODO (PARCIAL · B2): un intercambio válido consume una jugada. Decide dónde
	# descontar el contador: aquí, o en destroy_matched() solo si hubo combinación.
	pending_player_move = consume_move

	if consume_move and activate_swapped_specials(column, row, direction):
		destroy_timer.start()
		return

	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction, false)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		show_hint()
	
	if state == MOVE and not is_game_finished:
		touch_input()

func find_matches():
	# TODO (PARCIAL · M3): aquí es donde se decide qué piezas forman cada combinación.
	# Para crear piezas especiales necesitas conocer el LARGO de cada línea: una de 4
	# genera una pieza de línea (fila/columna) y una de 5 una bomba de color. El chequeo
	# actual solo mira el "centro" de tríos; probablemente tengas que recorrer las
	# líneas completas para distinguir combinaciones de 3, 4 y 5.
	var horizontal_lines = []
	var vertical_lines = []
	var special_matches = {}

	for j in height:
		var i = 0
		while i < width:
			if all_pieces[i][j] == null:
				i += 1
				continue

			var current_color = all_pieces[i][j].color
			var line = []

			while i < width and all_pieces[i][j] != null and all_pieces[i][j].color == current_color:
				line.append(Vector2i(i, j))
				i += 1

			if line.size() >= 3:
				horizontal_lines.append(line)
				mark_match_line(line)

	for i in width:
		var j = 0
		while j < height:
			if all_pieces[i][j] == null:
				j += 1
				continue

			var current_color = all_pieces[i][j].color
			var line = []

			while j < height and all_pieces[i][j] != null and all_pieces[i][j].color == current_color:
				line.append(Vector2i(i, j))
				j += 1

			if line.size() >= 3:
				vertical_lines.append(line)
				mark_match_line(line)

	for line in horizontal_lines:
		if line.size() >= 5:
			special_matches[choose_special_position(line)] = "rainbow"

	for line in vertical_lines:
		if line.size() >= 5:
			special_matches[choose_special_position(line)] = "rainbow"

	for horizontal_line in horizontal_lines:
		for vertical_line in vertical_lines:
			var intersection = get_line_intersection(horizontal_line, vertical_line)
			if intersection != null and not line_has_rainbow(horizontal_line, special_matches) and not line_has_rainbow(vertical_line, special_matches):
				special_matches[intersection] = "adjacent"

	for line in horizontal_lines:
		if line.size() == 4 and not line_has_special(line, special_matches):
			special_matches[choose_special_position(line)] = "row"

	for line in vertical_lines:
		if line.size() == 4 and not line_has_special(line, special_matches):
			special_matches[choose_special_position(line)] = "column"

	for special_position in special_matches:
		var piece = all_pieces[special_position.x][special_position.y]
		if piece != null:
			piece.set_special(special_matches[special_position])
	
	destroy_timer.start()


func mark_match_line(line):
	for grid_position in line:
		var piece = all_pieces[grid_position.x][grid_position.y]
		if piece != null:
			piece.matched = true
			piece.dim()


func activate_swapped_specials(column, row, direction: Vector2) -> bool:
	var activated = false
	var first_piece_position = Vector2i(column + direction.x, row + direction.y)
	var other_piece_position = Vector2i(column, row)
	var first_piece = all_pieces[first_piece_position.x][first_piece_position.y]
	var other_piece = all_pieces[other_piece_position.x][other_piece_position.y]

	if activate_special_combo(first_piece, first_piece_position, other_piece, other_piece_position):
		return true

	if activate_rainbow(first_piece, first_piece_position.x, first_piece_position.y, other_piece):
		return true
	if activate_rainbow(other_piece, other_piece_position.x, other_piece_position.y, first_piece):
		return true

	if activate_special(first_piece, first_piece_position.x, first_piece_position.y):
		activated = true
	if activate_special(other_piece, other_piece_position.x, other_piece_position.y):
		activated = true

	return activated


func activate_special_combo(first_piece, first_position: Vector2i, other_piece, other_position: Vector2i) -> bool:
	if not is_special_piece(first_piece) or not is_special_piece(other_piece):
		return false

	first_piece.matched = true
	first_piece.dim()
	other_piece.matched = true
	other_piece.dim()

	var first_type = first_piece.special_type
	var other_type = other_piece.special_type
	var combo_position = first_position
	var row_position = get_combo_position_for_type(first_type, first_position, other_type, other_position, "row")
	var column_position = get_combo_position_for_type(first_type, first_position, other_type, other_position, "column")
	var adjacent_position = get_combo_position_for_type(first_type, first_position, other_type, other_position, "adjacent")

	if first_type == "rainbow" and other_type == "rainbow":
		mark_all_pieces()
	elif first_type == "rainbow":
		activate_rainbow_combo(other_piece, other_position)
	elif other_type == "rainbow":
		activate_rainbow_combo(first_piece, first_position)
	elif is_row_column_combo(first_type, other_type):
		mark_row(row_position.y)
		mark_column(column_position.x)
	elif first_type == "row" and other_type == "row":
		mark_row(first_position.y)
		mark_row(other_position.y)
	elif first_type == "column" and other_type == "column":
		mark_column(first_position.x)
		mark_column(other_position.x)
	elif has_combo_types(first_type, other_type, "row", "adjacent"):
		mark_row(row_position.y)
		mark_square(adjacent_position.x, adjacent_position.y, 1)
	elif has_combo_types(first_type, other_type, "column", "adjacent"):
		mark_column(column_position.x)
		mark_square(adjacent_position.x, adjacent_position.y, 1)
	elif first_type == "adjacent" and other_type == "adjacent":
		mark_square(combo_position.x, combo_position.y, 2)
	else:
		# TODO (PARCIAL · M3): mejorar combos nuevos si se agregan más tipos especiales.
		activate_special(first_piece, first_position.x, first_position.y)
		activate_special(other_piece, other_position.x, other_position.y)

	return true


func get_combo_position_for_type(first_type: String, first_position: Vector2i, other_type: String, other_position: Vector2i, needed_type: String) -> Vector2i:
	if first_type == needed_type:
		return first_position
	if other_type == needed_type:
		return other_position

	return first_position


func is_special_piece(piece) -> bool:
	return piece != null and piece.special_type != ""


func is_row_column_combo(first_type: String, other_type: String) -> bool:
	return has_combo_types(first_type, other_type, "row", "column")


func has_combo_types(first_type: String, other_type: String, needed_a: String, needed_b: String) -> bool:
	return (
		(first_type == needed_a and other_type == needed_b)
		or (first_type == needed_b and other_type == needed_a)
	)


func activate_rainbow_combo(other_piece, other_position: Vector2i):
	if other_piece == null or other_piece.color == "":
		mark_all_pieces()
		return

	if other_piece.special_type == "row":
		mark_color(other_piece.color)
		mark_row(other_position.y)
	elif other_piece.special_type == "column":
		mark_color(other_piece.color)
		mark_column(other_position.x)
	elif other_piece.special_type == "adjacent":
		mark_color(other_piece.color)
		mark_square(other_position.x, other_position.y, 1)
	else:
		mark_color(other_piece.color)


func activate_rainbow(rainbow_piece, rainbow_column, rainbow_row, target_piece) -> bool:
	if rainbow_piece == null or rainbow_piece.special_type != "rainbow":
		return false

	rainbow_piece.matched = true
	rainbow_piece.dim()

	if target_piece != null and target_piece.color != "":
		mark_color(target_piece.color)
	else:
		# TODO (PARCIAL · M3): decidir qué hacer con Rainbow + Rainbow o pieza sin color.
		print("Rainbow sin color objetivo.")

	return true


func activate_special(piece, column, row) -> bool:
	if piece == null:
		return false

	if piece.special_type == "row":
		mark_row(row)
		return true
	elif piece.special_type == "column":
		mark_column(column)
		return true
	elif piece.special_type == "adjacent":
		mark_adjacent(column, row)
		return true

	return false


func mark_row(row):
	for i in width:
		if all_pieces[i][row] != null:
			all_pieces[i][row].matched = true
			all_pieces[i][row].dim()


func mark_column(column):
	for j in height:
		if all_pieces[column][j] != null:
			all_pieces[column][j].matched = true
			all_pieces[column][j].dim()


func mark_adjacent(column, row):
	mark_square(column, row, 1)


func mark_square(column, row, radius):
	for i in range(column - radius, column + radius + 1):
		for j in range(row - radius, row + radius + 1):
			if in_grid(i, j) and all_pieces[i][j] != null:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()


func mark_color(color_name):
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].color == color_name:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()


func mark_all_pieces():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()


func choose_special_position(line):
	if piece_one != null:
		for grid_position in line:
			if all_pieces[grid_position.x][grid_position.y] == piece_one:
				return grid_position

	if piece_two != null:
		for grid_position in line:
			if all_pieces[grid_position.x][grid_position.y] == piece_two:
				return grid_position

	return line[1]


func get_line_intersection(horizontal_line, vertical_line):
	for horizontal_position in horizontal_line:
		for vertical_position in vertical_line:
			if horizontal_position == vertical_position:
				return horizontal_position

	return null


func line_has_special(line, special_matches):
	for grid_position in line:
		if special_matches.has(grid_position):
			return true

	return false


func line_has_rainbow(line, special_matches):
	for grid_position in line:
		if special_matches.has(grid_position) and special_matches[grid_position] == "rainbow":
			return true

	return false
	
func destroy_matched():
	activate_matched_specials()
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				# TODO (PARCIAL · B1): suma puntaje por cada pieza destruida (o por
				# combinación) y emite score_changed para actualizar el HUD.
				current_score += 100
				score_changed.emit(current_score)
				
				match all_pieces[i][j].color:
					"pink":
						collected_pink += 1
					"yellow":
						collected_yellow += 1
					"blue":
						collected_blue += 1
						
				print(
					"Pink: ", collected_pink, "/", level_data.objetivo_pink,
					" Yellow: ", collected_yellow, "/", level_data.objetivo_yellow,
					" Blue: ", collected_blue, "/", level_data.objetivo_blue
				)

				
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	move_checked = true
	if was_matched:
		play_sfx("match")
		emit_collect_progress()
		if pending_player_move:
			play_sfx("swap")
		if pending_player_move and level_data != null and level_data.limite_movimientos > 0:
			moves_left -= 1
			counter_changed.emit(moves_left)

		pending_player_move = false
		collapse_timer.start()
	else:
		play_sfx("invalid")
		pending_player_move = false
		swap_back()


func activate_matched_specials():
	var specials_to_activate = []

	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				if all_pieces[i][j].special_type == "row" or all_pieces[i][j].special_type == "column" or all_pieces[i][j].special_type == "adjacent":
					specials_to_activate.append(Vector2i(i, j))

	for special_position in specials_to_activate:
		var piece = all_pieces[special_position.x][special_position.y]
		activate_special(piece, special_position.x, special_position.y)

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	refill_timer.start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				#destroy_timer.start()
				return
	# El tablero quedó estable: no hay más combinaciones en cascada.
	# TODO (PARCIAL · M1): verifica si se cumplió o falló el objetivo del nivel
	# (puntaje meta, piezas recolectadas, etc.) y dispara victoria o derrota.
	# TODO (PARCIAL · M2): comprueba si todavía existe alguna jugada válida; si no,
	# rebaraja el tablero hasta que haya al menos una.
	match level_data.objetivo_tipo:
		LevelConfig.Objetivo.SCORE:
			if current_score >= level_data.objetivo_puntaje:
				game_over(true)
				return
			
			if moves_left <= 0:
				game_over(false)
				return
		

		LevelConfig.Objetivo.COLLECT:
			if (
				collected_pink >= level_data.objetivo_pink
				and collected_yellow >= level_data.objetivo_yellow
				and collected_blue >= level_data.objetivo_blue
			):
				game_over(true)
				return

			if moves_left <= 0:
				game_over(false)
				return
			
		
		LevelConfig.Objetivo.TIME_SCORE:
			if current_score >= level_data.objetivo_puntaje:
				game_over(true)
				return

			if time_left <= 0:
				game_over(false)
				return
	
	
	if not has_valid_moves():
		show_shuffle_popup()
		await shuffle_board()
		hide_shuffle_popup()
	state = MOVE
	move_checked = false

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over(gano: bool):
	if is_game_finished:
		return
	is_game_finished = true
	state = WAIT
	# TODO (PARCIAL · B3): muestra la pantalla final (victoria o derrota), detén la
	# entrada del jugador y ofrece reiniciar la partida. Emite game_finished(gano).
	if gano:
		print("VICTORIA")
		play_sfx("win")
		unlocked_level = min(current_level_index + 1, levels.size() -1)
	else:
		print("DERROTA")
		play_sfx("lose")
		
	level_timer.stop()
	save_progress()
	game_finished.emit(gano)
	final_popup_requested.emit(gano, current_level_index + 1, get_final_message(gano), has_next_level())
	# TODO (PARCIAL · M4): guarda el progreso (nivel alcanzado) y el mejor puntaje
	# en disco (user://) para conservarlos entre sesiones.


func load_level():
	if levels.is_empty():
		push_error("No hay niveles asignados en el Inspector.")
		return
	
	if current_level_index < 0 or current_level_index >= levels.size():
		push_error("current_level_index fuera de rango.")
		return
	
	level_data = levels[current_level_index]
	
	if level_data == null:
		push_error("El nivel cargado es null. Revisa los .tres en el Inspector.")
		return
	
	print("Cargando: ", level_data.nombre)
	
	target_score = level_data.objetivo_puntaje
	moves_left = level_data.limite_movimientos
	time_left = level_data.limite_segundos
	
	current_score = 0
	collected_blue = 0
	collected_pink = 0
	collected_yellow = 0
	
	var is_collect_level = level_data.objetivo_tipo == LevelConfig.Objetivo.COLLECT
	collect_goals_changed.emit(
		is_collect_level,
		level_data.objetivo_pink,
		level_data.objetivo_yellow,
		level_data.objetivo_blue
	)
	emit_collect_progress()
	

func get_counter_value() -> int:
	if level_data != null and level_data.limite_segundos > 0:
			return time_left
	return moves_left
	
func _on_level_timer_timeout():
	time_left -= 1
	counter_changed.emit(time_left)

	if time_left <= 0:
		level_timer.stop()
		game_over(false)

func load_progress():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error != OK:
		unlocked_level = 0
		best_score = 0
		current_level_index = 0
		print("No hay save previo. Nivel actual: 1 | Mejor puntaje: 0")
		return 
	
	unlocked_level = config.get_value("progress", "unlocked_level", 0)
	best_score = config.get_value("progress", "best_score", 0)

	current_level_index = unlocked_level
	print("Save cargado. Nivel actual: ", current_level_index + 1, " | Mejor puntaje: ", best_score)
	

func save_progress():
	best_score = max(best_score, current_score)

	var config = ConfigFile.new()
	config.set_value("progress", "unlocked_level", unlocked_level)
	config.set_value("progress", "best_score", best_score)

	config.save(SAVE_PATH)
	

# TODO (PARCIAL · M2): funciones sugeridas para detectar el bloqueo del tablero.
# func hay_jugadas_validas() -> bool:
# func rebarajar() -> void:

func _on_reset_progress_button_pressed():
	play_sfx("button")
	await get_tree().create_timer(0.15).timeout
	var config = ConfigFile.new()
	config.set_value("progress", "unlocked_level", 0)
	config.set_value("progress", "best_score", 0)
	config.save(SAVE_PATH)
	get_tree().reload_current_scene()


func retry_level():
	play_sfx("button")
	await get_tree().create_timer(0.15).timeout
	get_tree().reload_current_scene()


func go_to_next_level():
	play_sfx("button")
	await get_tree().create_timer(0.15).timeout
	if has_next_level():
		unlocked_level = max(unlocked_level, current_level_index + 1)
		save_progress()
		get_tree().reload_current_scene()


func has_next_level() -> bool:
	return current_level_index < levels.size() - 1


func close_game():
	play_sfx("button")
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func show_shuffle_popup():
	if shuffle_popup != null:
		shuffle_popup.visible = true


func hide_shuffle_popup():
	if shuffle_popup != null:
		shuffle_popup.visible = false


func play_sfx(sound_name: String):
	if audio_manager != null:
		audio_manager.play_sfx(sound_name)


func emit_collect_progress():
	collect_progress_changed.emit(collected_pink, collected_yellow, collected_blue)
	

func get_final_message(gano: bool) -> String:
	if gano:
		return "Congratulations"

	match current_level_index:
		0:
			return "Youre out of moves"
		1:
			return "You ran out of time"
		2:
			return str(get_missing_collect_pieces()) + " pieces missing"

	return "Game over"


func get_missing_collect_pieces() -> int:
	if level_data == null:
		return 0

	var missing_pink = max(level_data.objetivo_pink - collected_pink, 0)
	var missing_yellow = max(level_data.objetivo_yellow - collected_yellow, 0)
	var missing_blue = max(level_data.objetivo_blue - collected_blue, 0)
	return missing_pink + missing_yellow + missing_blue
	

func hay_match_after_swap(col: int, row: int, dir: Vector2) -> bool:
	var other_col = col + int(dir.x)
	var other_row = row + int(dir.y)

	if not in_grid(other_col, other_row):
		return false

	var piece_a = all_pieces[col][row]
	var piece_b = all_pieces[other_col][other_row]

	if piece_a == null or piece_b == null:
		return false

	all_pieces[col][row] = piece_b
	all_pieces[other_col][other_row] = piece_a

	var result = hay_match(col, row) or hay_match(other_col, other_row)

	all_pieces[col][row] = piece_a
	all_pieces[other_col][other_row] = piece_b

	return result


func hay_match(col: int, row: int) -> bool:
	if not in_grid(col, row) or all_pieces[col][row] == null:
		return false

	var color = all_pieces[col][row].color

	var x_count = 1
	var c = col - 1
	while c >= 0 and all_pieces[c][row] != null and all_pieces[c][row].color == color:
		x_count += 1
		c -= 1

	c = col + 1
	while c < width and all_pieces[c][row] != null and all_pieces[c][row].color == color:
		x_count += 1
		c += 1

	var y_count = 1
	var r = row - 1
	while r >= 0 and all_pieces[col][r] != null and all_pieces[col][r].color == color:
		y_count += 1
		r -= 1

	r = row + 1
	while r < height and all_pieces[col][r] != null and all_pieces[col][r].color == color:
		y_count += 1
		r += 1

	return x_count >= 3 or y_count >= 3


func has_valid_moves() -> bool:
	for i in width:
		for j in height:
			if hay_match_after_swap(i, j, Vector2(1, 0)):
				return true
			if hay_match_after_swap(i, j, Vector2(0, 1)):
				return true

	return false
	

func show_hint():
	for i in width:
		for j in height:
			if hay_match_after_swap(i, j, Vector2(1, 0)):
				print("PISTA: mueve la pieza en columna ", i, ", fila ", j, " hacia la derecha.")
				return

			if hay_match_after_swap(i, j, Vector2(0, 1)):
				print("PISTA: mueve la pieza en columna ", i, ", fila ", j, " hacia arriba.")
				return

	print("No hay pista disponible.")


func shuffle_board():
	print("No hay jugadas válidas. Rebarajando...")

	var pieces = []

	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				pieces.append(all_pieces[i][j])
				all_pieces[i][j] = null

	pieces.shuffle()

	var index = 0
	for i in width:
		for j in height:
			var piece = pieces[index]
			index += 1
			all_pieces[i][j] = piece
			piece.move(grid_to_pixel(i, j))

	await get_tree().create_timer(0.5).timeout

	if not has_valid_moves():
		await shuffle_board()
	else:
		print("Tablero listo.")
