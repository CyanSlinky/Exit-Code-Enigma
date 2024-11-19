extends SubViewport
class_name Terminal

#@onready var canvas_layer: CanvasLayer = $CanvasLayer
#@onready var interface: Control = $Interface
@onready var terminal_interface: Control = $TerminalInterface
@onready var code_entry_field: LineEdit = $TerminalInterface/HBoxContainer/VBoxContainer/CodeEntryField
@onready var code_result_label: Label = $TerminalInterface/HBoxContainer/VBoxContainer/CodeResultLabel

func _ready() -> void:
	code_entry_field.text_changed.connect(_on_code_entry_field_text_changed)
	code_entry_field.text_submitted.connect(_on_code_entry_field_text_submitted)

#func show_terminal_view() -> void:
	#if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#canvas_layer.visible = true
	#interface.visible = true
#
#func hide_terminal_view() -> void:
	#if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#canvas_layer.visible = false
	#interface.visible = false

func _on_code_entry_field_text_changed(new_text: String) -> void:
	var caret_pos: int = code_entry_field.caret_column
	code_entry_field.text = new_text.to_upper()
	code_entry_field.caret_column = caret_pos

func _on_code_entry_field_text_submitted(new_text: String) -> void:
	if new_text == GameData.exit_code:
		code_result_label.text = "exit opened."
		GameData.exit.open_exit()
	elif new_text == "ENIGMA":
		code_result_label.text = "clever."
		GameData.exit.open_exit()
	else:
		code_result_label.text = "nothing happens."
