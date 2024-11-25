extends Node3D
class_name StickyNote

@onready var mesh_instance: MeshInstance3D = $MeshInstance

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
	if GameData.map.sticky_notes.has(self):
		GameData.map.sticky_notes.erase(self)
