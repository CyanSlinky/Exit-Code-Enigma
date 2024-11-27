extends RigidBody3D
class_name RandomTeleporter

func _on_interactable_interaction_occurred() -> void:
	if not GameData.player.infinite_teleporting:
		GameData.player.teleport_uses += 1
		GUI.teleporter_label.text = "Teleporters: " + str(GameData.player.teleport_uses) + " [T]"
	queue_free()
