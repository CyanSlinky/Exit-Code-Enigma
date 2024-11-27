extends RigidBody3D
class_name WallVoider

func _on_interactable_interaction_occurred() -> void:
	GameData.player.void_uses += 1
	queue_free()
