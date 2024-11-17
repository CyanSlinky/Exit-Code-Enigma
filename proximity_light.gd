extends OmniLight3D
class_name ProximityLight

const max_active_lights: int = 7
static var active_lights: Array = []

var raycast: RayCast3D
var player: Node3D

func _ready() -> void:
	raycast = RayCast3D.new()
	add_child(raycast)
	raycast.enabled = true
	
	player = get_tree().get_nodes_in_group("Player")[0]

func _process(_delta: float) -> void:
	update_raycast()

func update_raycast() -> void:
	if not player:
		return
	
	# Adjust the raycast to always point towards the player
	raycast.target_position = player.global_transform.origin - global_transform.origin
	raycast.force_raycast_update()  # Force the raycast to update immediately
	
	# Check if the raycast detects the player
	if raycast.is_colliding():
		var collider := raycast.get_collider()
		if collider == player:
			attempt_activation()
		else:
			deactivate_light()
	else:
		deactivate_light()

func attempt_activation() -> void:
	#print("attempt activation")
	if self not in active_lights and active_lights.size() < max_active_lights:
		active_lights.append(self)
		self.visible = true
		print("Activated Light: ", self.name)  # Debug: print when a light is activated
	elif self in active_lights:
		self.visible = true  # Ensure currently active lights remain visible if still colliding
	else:
		self.visible = false  # Cannot activate because the limit is reached

func deactivate_light() -> void:
	if self in active_lights:
		active_lights.erase(self)
		self.visible = false
		print("Deactivated Light: ", self.name)  # Debug: print when a light is deactivated

func _exit_tree() -> void:
	# Clean up when the light is removed from the scene
	deactivate_light()
