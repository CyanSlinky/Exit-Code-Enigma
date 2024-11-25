extends Node3D
class_name CeilingLight

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $Light

@export var flicker_distance: float = 50.0  # Distance within which flashlight starts flickering
@export var off_distance: float = 20.0  # Distance within which flashlight turns off

var flicker_timer := Timer.new()

const max_active_lights: int = 7
static var active_lights: Array = []

var player: Node3D

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]
	
	add_child(flicker_timer)
	flicker_timer.wait_time = randf_range(0.05, 0.15)
	flicker_timer.autostart = false
	flicker_timer.connect("timeout", _on_flicker_timer_timeout)

func _process(_delta: float) -> void:
	var dist: float = global_transform.origin.distance_to(GameData.office_manager.global_transform.origin)
	if light.visible:
		if dist < off_distance:
			flicker_timer.stop()
			deactivate_light()
			light.light_energy = 0
		elif dist < flicker_distance:
			if flicker_timer.is_stopped():
				flicker_timer.start()
		else:
			flicker_timer.stop()
			light.light_energy = 1

func _on_flicker_timer_timeout() -> void:
	flicker_timer.wait_time = randf_range(0.05, 0.15)
	light.light_energy = randf_range(0.8, 1.2)

func attempt_activation() -> void:
	if self not in active_lights and active_lights.size() < max_active_lights:
		active_lights.append(self)
		light.visible = true
		mesh_instance.material_override.albedo_color = Color.WHITE
		#print("Activated Light: ", self.name)  # Debug: print when a light is activated
	elif self in active_lights:
		light.visible = true  # Ensure currently active lights remain visible if still colliding
		mesh_instance.material_override.albedo_color = Color.WHITE
	else:
		light.visible = false  # Cannot activate because the limit is reached
		mesh_instance.material_override.albedo_color = Color.BLACK

func deactivate_light() -> void:
	if self in active_lights:
		active_lights.erase(self)
		light.visible = false
		mesh_instance.material_override.albedo_color = Color.BLACK
		#print("Deactivated Light: ", self.name)  # Debug: print when a light is deactivated

func _exit_tree() -> void:
	# Clean up when the light is removed from the scene
	deactivate_light()

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body == GameData.player:
		attempt_activation()

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == GameData.player:
		deactivate_light()
