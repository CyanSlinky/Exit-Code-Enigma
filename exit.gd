extends Node3D
class_name Exit

@onready var exit_area: Area3D = $ExitArea
@onready var door_left: MeshInstance3D = $DoorLeft
@onready var door_right: MeshInstance3D = $DoorRight
@onready var doors_collider: CollisionShape3D = $Collision/Doors
@onready var exit_terminal: MeshInstance3D = $ExitTerminal
@onready var terminal_camera: Camera3D = $ExitTerminal/TerminalCamera
@onready var terminal_light: OmniLight3D = $ExitTerminal/TerminalCamera/TerminalLight
@onready var terminal_viewport: Terminal = $Terminal
@onready var monitor_area: Area3D = $ExitTerminal/MonitorArea
@onready var monitor_quad: MeshInstance3D = $ExitTerminal/MonitorArea/MonitorQuad

# Used for checking if the mouse is inside the Area3D.
var is_mouse_inside: bool = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_event_pos2D: Vector2
# The time of the last event in seconds since engine start.
var last_event_time: float = -1.0

var is_open: bool
var using_terminal: bool
var was_using_terminal: bool

var player: Node3D

func _ready() -> void:
	monitor_area.mouse_entered.connect(_mouse_entered_area)
	monitor_area.mouse_exited.connect(_mouse_exited_area)
	monitor_area.input_event.connect(_mouse_input_event)
	GameData.exit = self
	player = get_tree().get_nodes_in_group("Player")[0]
	update_terminal_texture()

func _mouse_entered_area() -> void:
	is_mouse_inside = true
	#print("mouse inside")

func _mouse_exited_area() -> void:
	is_mouse_inside = false

func _mouse_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	var quad_mesh_size: Vector2 = monitor_quad.mesh.size

	# Event position in Area3D in world coordinate space.
	var event_pos3D: Vector3 = event_position

	# Current time in seconds since engine start.
	var now: float = Time.get_ticks_msec() / 1000.0

	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = monitor_quad.global_transform.affine_inverse() * event_pos3D
	event_pos3D *= -1 # had to invert it for some reason.

	# TODO: Adapt to bilboard mode or avoid completely.

	var event_pos2D: Vector2 = Vector2()

	if is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)
		
		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5
		
		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= terminal_viewport.size.x
		event_pos2D.y *= terminal_viewport.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.
		
	elif last_event_pos2D != null:
		# Fall back to the last known event position.
		event_pos2D = last_event_pos2D
	
	# Set the event's position and global position.
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D
	
	# Calculate the relative event distance.
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_event_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		else:
			event.relative = event_pos2D - last_event_pos2D
			event.velocity = event.relative / (now - last_event_time)
	
	# Update last_event_pos2D with the position we just calculated.
	last_event_pos2D = event_pos2D
	
	# Update last_event_time to current time.
	last_event_time = now
	
	# Finally, send the processed input event to the viewport.
	terminal_viewport.push_input(event)

func update_terminal_texture() -> void:
	var mat := exit_terminal.get_surface_override_material(1)
	mat.albedo_texture = terminal_viewport.get_texture()
	exit_terminal.set_surface_override_material(1, mat)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if using_terminal:
			toggle_terminal_usage()
	
	# Check if the event is a non-mouse/non-touch event
	for mouse_event: Variant in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(event, mouse_event):
			# If the event is a mouse/touch event, then we can ignore it here, because it will be
			# handled via Physics Picking.
			return
	terminal_viewport.push_input(event)

func open_exit() -> void:
	if is_open:
		return
	is_open = true
	var open_tween: Tween = get_tree().create_tween()
	var left_x: float = 2.0
	var right_x: float = -2.0
	open_tween.tween_property(door_left, "position:x", left_x, 1.0)
	open_tween.set_parallel()
	open_tween.tween_property(door_right, "position:x", right_x, 1.0)
	open_tween.tween_callback(exit_opened)

func exit_opened() -> void:
	doors_collider.disabled = true

func close_exit() -> void:
	if !is_open:
		return
	is_open = false
	var close_tween: Tween = get_tree().create_tween()
	var left_x: float = 1.0
	var right_x: float = -1.0
	close_tween.tween_property(door_left, "position:x", left_x, 1.0)
	close_tween.set_parallel()
	close_tween.tween_property(door_right, "position:x", right_x, 1.0)
	close_tween.tween_callback(exit_closed)

func exit_closed() -> void:
	doors_collider.disabled = false

func toggle_terminal_usage() -> void:
	#print("toggled terminal")
	using_terminal = !using_terminal
	if using_terminal:
		#GUI.override_interact_text = "Stop using terminal"
		player.restrict_movement()
		terminal_camera.current = true
		terminal_light.visible = true
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#terminal.show_terminal_view()
	else:
		was_using_terminal = true
		#GUI.override_interact_text = ""
		player.enable_movement()
		terminal_camera.current = false
		terminal_light.visible = false
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#terminal.hide_terminal_view()

func _on_interactable_interaction_occurred() -> void:
	toggle_terminal_usage()

func _on_exit_area_body_entered(body: Node3D) -> void:
	if body == player:
		GameData.win_game()
