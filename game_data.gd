extends Node

#signal clue_collected(clue_text: String)

var elapsed_time: int
var exit_code: String
var clues: Array[Dictionary]
var collected_clues: Array[int]

var exit_code_length: int = 6
var enigma_outcome: int
var silly_result: bool
var used_silly: bool

var xray: bool : 
	set (value):
		xray = value
		if map:
			exit.exit_sign.material_override.set("no_depth_test", value)
			var char_mat: Material = office_manager.character.get_surface_override_material(0).get_next_pass()
			char_mat.set("no_depth_test", value)
			#var tie_mat: Material = office_manager.tie.get_surface_override_material(0)
			#tie_mat.set("no_depth_test", value)
			#tie_mat.set("shading_mode", value)
			if map.sticky_notes.size() > 0:
				for sn in map.sticky_notes:
					sn.mesh_instance.material_override.set("no_depth_test", value)

var map: Map
var exit: Exit
var player: Player
var office_manager: OfficeManager

func _ready() -> void:
	await GUI.ready
	start_game()

func start_game() -> void:
	#print("start")
	xray = false
	GUI.pause_screen.visible = false
	get_tree().paused = false
	randomize()
	used_silly = false
	enigma_outcome = randi_range(1, 10)
	silly_result = randi_range(0, 1)
	generate_exit_code()
	generate_clues()
	elapsed_time = 0
	GUI.game_timer.start()
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GUI.display_game_screen()
	if player != null:
		player.position = Vector3.ZERO
		player.enable_movement()
		player.camera.locked = false
	if map != null:
		map.update_map()

func win_game() -> void:
	GUI.game_timer.stop()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GUI.display_win_screen()
	player.restrict_movement()
	player.camera.locked = true
	#get_tree().paused = true

# Function to generate or set the exit code
func generate_exit_code() -> void:
	# Simple example: randomly generate a 6-character code
	exit_code = ""
	var characters: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	for i in range(exit_code_length):
		exit_code += characters[randi() % characters.length()]
	print("Exit Code Generated: ", exit_code)

func generate_clues() -> void:
	clues.clear()
	collected_clues.clear()
	for i in range(exit_code.length()):
		var clue_text: String = "Character at position %d is '%s'." % [i + 1, exit_code[i]]
		clues.append({
			"text": clue_text,
			"index": i,
			"character": exit_code[i]
		})

func get_new_clue() -> String:
	var uncollected_clues := clues.filter(is_not_collected)
	if uncollected_clues.size() > 0:
		var chosen_clue: Dictionary = uncollected_clues[randi() % uncollected_clues.size()]
		collected_clues.append(chosen_clue.index)  # Track by index.
		GUI.update_character(chosen_clue.index + 1, chosen_clue.character)  # Update GUI.
		if uncollected_clues.size() <= 0:
			GUI.display_notification("Enough clues collected. The exit code is: " + exit_code)
		return chosen_clue.text
	else:
		return "Enough clues collected. The exit code is: " + exit_code

func is_not_collected(clue: Dictionary) -> bool:
	return not collected_clues.has(clue.index)
