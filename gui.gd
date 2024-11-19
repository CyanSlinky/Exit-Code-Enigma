extends Control

@onready var game_screen: Control = $GameScreen
@onready var win_screen: Control = $WinScreen

@onready var notification_label: Label = $GameScreen/HBoxContainer2/VBoxContainer/NotificationLabel
@onready var interact_label: Label = $GameScreen/HBoxContainer2/VBoxContainer/InteractLabel

@onready var notification_timer: Timer = $GameScreen/HBoxContainer2/VBoxContainer/NotificationLabel/NotificationTimer

@onready var pass_character_1: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter1
@onready var pass_character_2: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter2
@onready var pass_character_3: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter3
@onready var pass_character_4: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter4
@onready var pass_character_5: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter5
@onready var pass_character_6: Label = $GameScreen/HBoxContainer/VBoxContainer/HBoxContainer/PassCharacter6

var override_interact_text: String

func display_win_screen() -> void:
	game_screen.visible = false
	win_screen.visible = true

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
