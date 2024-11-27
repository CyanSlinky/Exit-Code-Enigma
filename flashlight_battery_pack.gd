extends RigidBody3D
class_name FlashlightBatteryPack

func _on_interactable_interaction_occurred() -> void:
	GameData.player.flashlight_charge += 25.0
	queue_free()
