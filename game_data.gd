extends Node

#signal clue_collected(clue_text: String)

var elapsed_time: int
var exit_code: String
var clues: Array[Dictionary]
var collected_clues: Array[int]

var map: Map
var exit: Exit
var player: Player

func _ready() -> void:
	await GUI.ready
	start_game()

func start_game() -> void:
	print("start")
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
	var code_length: int = 6
	for i in range(code_length):
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
			GUI.display_notification("All clues collected. The exit code is: " + exit_code)
		return chosen_clue.text
	else:
		return "All clues collected. The exit code is: " + exit_code

func is_not_collected(clue: Dictionary) -> bool:
	return not collected_clues.has(clue.index)
