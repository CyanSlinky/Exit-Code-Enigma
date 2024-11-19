extends Node3D
class_name StickyNote

var message: String : 
	set(value):
		message = value
		print(message)

func _on_interactable_interaction_occurred() -> void:
	collect_clue()
	queue_free()

func collect_clue() -> void:
	message = GameData.get_new_clue()
	GUI.display_notification(message)
