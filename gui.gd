extends Control

@onready var game_screen: Control = $GameScreen
@onready var win_screen: Control = $WinScreen
@onready var pause_screen: Control = $PauseScreen

@onready var notification_label: Label = $GameScreen/HBoxContainer2/VBoxContainer/NotificationLabel
@onready var interact_label: Label = $GameScreen/HBoxContainer2/VBoxContainer/InteractLabel
@onready var fps_label: Label = $GameScreen/HBoxContainer/VBoxContainer2/FPSLabel
@onready var game_time_elapsed_label: Label = $GameScreen/HBoxContainer/VBoxContainer/GameTimeElapsedLabel
@onready var time_taken_label: Label = $WinScreen/HBoxContainer/VBoxContainer/TimeTakenLabel
@onready var clues_found_label: Label = $WinScreen/HBoxContainer/VBoxContainer/CluesFoundLabel
@onready var win_method_label: Label = $WinScreen/HBoxContainer/VBoxContainer/WinMethodLabel

@onready var notification_timer: Timer = $GameScreen/HBoxContainer2/VBoxContainer/NotificationLabel/NotificationTimer
@onready var game_timer: Timer = $GameScreen/HBoxContainer/VBoxContainer/GameTimeElapsedLabel/GameTimer

@onready var pass_character_1: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter1
@onready var pass_character_2: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter2
@onready var pass_character_3: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter3
@onready var pass_character_4: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter4
@onready var pass_character_5: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter5
@onready var pass_character_6: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter6

var override_interact_text: String

func _process(_delta: float) -> void:
	fps_label.text = "FPS " + str(Engine.get_frames_per_second())

func display_win_screen() -> void:
	game_screen.visible = false
	pause_screen.visible = false
	time_taken_label.text = "Time taken: " + format_time(GameData.elapsed_time)
	clues_found_label.text = "Clues found: " + str(GameData.collected_clues.size())
	win_method_label.text = "Legit win."
	if GameData.used_silly:
		win_method_label.text = "Silly win."
	elif GameData.enigma_outcome == 1:
		win_method_label.text = "Enigma win."
	win_screen.visible = true

func display_game_screen() -> void:
	for i in range(6):
		update_character(i + 1, "_")
	win_screen.visible = false
	pause_screen.visible = false
	game_screen.visible = true

func _unhandled_input(_event: InputEvent) -> void:
		if Input.is_action_just_pressed("pause"):
			if GameData.player.overview_camera.current:
				GameData.player.camera.current = true
				GameData.player.overview_light.visible = false
			elif GameData.exit.was_using_terminal:
				GameData.exit.was_using_terminal = false
			else:
				toggle_pause_screen()

func toggle_pause_screen() -> void:
	#print("toggled pause")
	if pause_screen.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pause_screen.visible = false
		get_tree().paused = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		pause_screen.visible = true
		get_tree().paused = true

func display_interact_label(label_text: String) -> void:
	var key_name: String = "N/A"
	var action_name: String = "interact"
	
	if InputMap.has_action(action_name):
		var key_action := InputMap.action_get_events(action_name)[0]
		var key_string := OS.get_keycode_string(key_action.physical_keycode)
		key_name = str(key_string)
	
	if override_interact_text != "":
		label_text = override_interact_text
	interact_label.text = label_text + " ( " + key_name + " )"
	interact_label.visible = true

func hide_interact_label() -> void:
	interact_label.visible = false

func display_notification(message: String) -> void:
	notification_label.text = message
	notification_label.visible = true
	notification_timer.start()

func hide_notification() -> void:
	notification_label.visible = false

func _on_notification_timer_timeout() -> void:
	hide_notification()

func update_character(index: int, character: String) -> void:
	match index:
		1:
			pass_character_1.text = character
		2:
			pass_character_2.text = character
		3:
			pass_character_3.text = character
		4:
			pass_character_4.text = character
		5:
			pass_character_5.text = character
		6:
			pass_character_6.text = character

func _on_game_timer_timeout() -> void:
	GameData.elapsed_time += 1
	game_time_elapsed_label.text = format_time(GameData.elapsed_time)

func format_time(total_seconds: int) -> String:
	# Calculate hours, minutes, and seconds
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var seconds: int = total_seconds % 60
	# Format the time into a string of hh:mm:ss
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _on_restart_button_pressed() -> void:
	#get_tree().reload_current_scene()
	GameData.start_game()
