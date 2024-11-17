extends Node3D
class_name CeilingLight

@onready var light: OmniLight3D = $Light
@onready var raycasts: Array = [$RayCast1, $RayCast2, $RayCast3, $RayCast4]

const max_active_lights: int = 7
static var active_lights: Array = []

var player: Node3D

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]

func _process(_delta: float) -> void:
	var any_colliding: bool
	for raycast: RayCast3D in raycasts:
		update_raycast(raycast)
		if raycast.is_colliding() and raycast.get_collider() == player:
			any_colliding = true
	
	if any_colliding:
		attempt_activation()
	else:
		deactivate_light()

func update_raycast(raycast: RayCast3D) -> void:
	if not player:
		return
	
	# Adjust the raycast to always point towards the player
	raycast.target_position = player.global_transform.origin - raycast.global_transform.origin
	raycast.force_raycast_update()  # Force the raycast to update immediately

func attempt_activation() -> void:
	if self not in active_lights and active_lights.size() < max_active_lights:
		active_lights.append(self)
		light.visible = true
		#print("Activated Light: ", self.name)  # Debug: print when a light is activated
	elif self in active_lights:
		light.visible = true  # Ensure currently active lights remain visible if still colliding
	else:
		light.visible = false  # Cannot activate because the limit is reached

func deactivate_light() -> void:
	if self in active_lights:
		active_lights.erase(self)
		light.visible = false
		#print("Deactivated Light: ", self.name)  # Debug: print when a light is deactivated

func _exit_tree() -> void:
	# Clean up when the light is removed from the scene
	deactivate_light()
