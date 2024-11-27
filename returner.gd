extends RigidBody3D
class_name Returner

func _on_interactable_interaction_occurred() -> void:
	if not GameData.player.infinite_returning:
		GameData.player.returner_uses += 1
		GUI.returner_label.text = "Returners: " + str(GameData.player.returner_uses) + " [R]"
	queue_free()
