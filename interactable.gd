extends Area3D
class_name Interactable

signal interaction_occurred

@export var interact_prompt: String = "Interact"

func interact() -> void:
	interaction_occurred.emit()
	#print("Interacted with:", name)
