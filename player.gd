extends CharacterBody3D
class_name Player

@onready var camera: CameraController = $Camera3D
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight

@onready var overview_camera: Camera3D = $OverviewCamera
@onready var overview_light: DirectionalLight3D = $OverviewCamera/OverviewLight
@onready var map_indicator: MeshInstance3D = $MapIndicator

@onready var footstep_audio: AudioStreamPlayer3D = $FootstepAudio
@onready var teleport_audio: AudioStreamPlayer3D = $TeleportAudio

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 15.0
@export var acceleration: float = 5.0
@export var deceleration: float = 5.0
@export var friction: float = 10.0
@export var jump_velocity: float = 4.5

@export var flashlight_max_charge: float = 100.0  # Maximum charge
@export var flashlight_drain_rate: float = 1.0   # Charge drained per second when on
@export var flashlight_recharge_amount: float = 25.0  # Amount restored by each battery

@export var flicker_distance: float = 50.0  # Distance within which flashlight starts flickering
@export var off_distance: float = 20.0  # Distance within which flashlight turns off

@export var normal_fov: float = 75.0
@export var sprint_fov: float = 80.0
@export var shake_intensity: float = 0.1

const VOID_WALL = preload("res://void_wall.tscn")

var infinite_voiding: bool
var void_uses: int

var infinite_returning: bool :
	set(value):
		infinite_returning = value
		if value:
			GUI.returner_label.text = "Returners: ∞ [R]"
		else:
			GUI.returner_label.text = "Returners: " + str(GameData.player.returner_uses) + " [R]"
var returner_uses: int

var infinite_teleporting: bool :
	set(value):
		infinite_teleporting = value
		if value:
			GUI.teleporter_label.text = "Teleporters: ∞ [T]"
		else:
			GUI.teleporter_label.text = "Teleporters: " + str(GameData.player.teleport_uses) + " [T]"
var teleport_uses: int

var movement_restricted: bool

var unlimited_flashlight: bool :
	set(value):
		unlimited_flashlight = value
		if value:
			flashlight_charge = 100.0

var flashlight_was_visible: bool

var flicker_timer := Timer.new()  # Timer for controlling flashlight flicker frequency

var flashlight_charge: float = 100.0 :  # Current charge level
	set(value):
		flashlight_charge = value
		flashlight_charge = min(flashlight_charge, flashlight_max_charge)
	
var flashlight_on: bool = true : # Whether the flashlight is currently on
	set(value):
		var status_text: String
		if value:
			status_text = "ON"
		else:
			status_text = "OFF"
		GUI.flashlight_label.text = "Flashlight " + status_text + " [F]"
		flashlight.visible = value
		flashlight_on = value

var move_speed: float
var target_speed: float
var current_velocity: Vector3

func _ready() -> void:
	GameData.player = self
	camera.current = true
	overview_light.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	move_speed = walk_speed
	
	add_child(flicker_timer)
	flicker_timer.wait_time = randf_range(0.05, 0.15)
	flicker_timer.autostart = false
	flicker_timer.connect("timeout", _on_flicker_timer_timeout)

func _on_flicker_timer_timeout() -> void:
	flicker_timer.wait_time = randf_range(0.05, 0.15)
	flashlight.light_energy = randf_range(0.8, 1.2)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not GameData.exit.using_terminal:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			elif GameData.exit.using_terminal:
				GameData.exit.terminal_viewport.code_entry_field.grab_focus()
	
	if Input.is_action_just_pressed("return_to_exit") and camera.current:
		if infinite_returning:
			position = Vector3.ZERO
			teleport_audio.play()
		if returner_uses > 0 and not infinite_returning:
			returner_uses -= 1
			returner_uses = max(returner_uses, 0)
			GUI.returner_label.text = "Returners: " + str(GameData.player.returner_uses) + " [R]"
			position = Vector3.ZERO
			teleport_audio.play()
	
	if Input.is_action_just_pressed("teleport") and camera.current:
		if infinite_teleporting:
			teleport_random()
		if teleport_uses > 0 and not infinite_teleporting:
			teleport_uses -= 1
			teleport_uses = max(teleport_uses, 0)
			GUI.teleporter_label.text = "Teleporters: " + str(GameData.player.teleport_uses) + " [T]"
			teleport_random()
	
	if Input.is_action_just_pressed("interact") and interact_ray.is_colliding() and camera.current:
		var collider := interact_ray.get_collider()
		var normal := interact_ray.get_collision_normal()
		#print(collider)
		if collider:
			if collider.has_method("interact"):
				collider.interact()  # Call the interact method on the collider
			if collider is Map and abs(normal.y) < 0.1:
				if void_uses > 0 or infinite_voiding:
					var map: Map = collider
					var collision_point := interact_ray.get_collision_point()
					
					# Calculate the cell position from the collision point
					var cell_size := map.cell_size
					var cell_pos := Vector2i(
						int(round((collision_point.x + (-normal.x * 0.5 * cell_size)) / cell_size)),
						int(round((collision_point.z + (-normal.z * 0.5 * cell_size)) / cell_size))
					)
					
					#print("Cell being mined: ", cell_pos, " with wall normal: ", normal)
					
					# Check if the cell exists in the map
					var cell_exists := false
					for cell in map.cells:
						if cell.pos == cell_pos:
							cell_exists = true
							print("Cell exists in map")
							break
					
					# Check if the cell contains the exit
					for exit_cell_pos: Vector2i in map.exit_cells.keys():
						var door_cell_pos: Vector2i = exit_cell_pos + map.exit_cells[exit_cell_pos]
						if cell_pos == door_cell_pos:
							GUI.display_notification("Unable to void exit.")
							#print("Cannot mine the exit door cell at: ", cell_pos)
							return
					
					# Check if the cell contains sticky notes
					for sticky_note in map.sticky_notes:
						if sticky_note.cell_pos == cell_pos:
							GUI.display_notification("Unable to void a wall with a sticky note.")
							#print("Cannot mine cell with sticky notes at: ", cell_pos)
							return
					
					# Check if the cell has a shelf adjacent to it
					for shelf in map.objects.get_children():
						if shelf is Shelf and shelf.cell_pos == cell_pos:
							GUI.display_notification("Unable to void a wall next to a shelf.")
							#print("Cannot mine a cell with a shelf next to it at: ", cell_pos)
							return
					
					if !cell_exists:
						var void_wall: VoidWall = VOID_WALL.instantiate()
						void_wall.update_size(Vector3(map.cell_size, map.wall_height, map.cell_size))
						void_wall.position = Vector3(cell_pos.x * map.cell_size, map.wall_height / 2.0, cell_pos.y * map.cell_size)
						map.objects.add_child(void_wall)
						
						var new_cell := Cell.new(cell_pos)
						map.cells.append(new_cell)
						# Update the map visuals and collider
						map.map_mesh.update_mesh()
						map.update_collider()
						
						void_uses -= 1
						void_uses = max(void_uses, 0)
						#print("Mined wall at: ", cell_pos)
					else:
						print("Cell already exists.")
	
	if Input.is_action_just_pressed("toggle_cursor_visibility"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("flashlight"):
		if camera.current:
			if flashlight_on:
				flashlight_on = false
			elif flashlight_charge > 0:
				flashlight_on = true
	
	if Input.is_action_just_pressed("toggle_overview"):
		if overview_camera.current:
			camera.current = true
			overview_light.visible = false
		elif camera.current:
			overview_camera.current = true
			overview_light.visible = true
	
	if Input.is_action_just_pressed("sprint"):
		footstep_audio.pitch_scale = 1.4
	
	if Input.is_action_just_released("sprint"):
		footstep_audio.pitch_scale = 1.0

func _process(delta: float) -> void:
	var camera_yaw := camera.global_transform.basis.get_euler().y
	map_indicator.rotation_degrees.y = rad_to_deg(camera_yaw)
	
	if interact_ray.is_colliding() and camera.current:
		var collider := interact_ray.get_collider()
		if collider == null:
			return
		if collider is Interactable:
			var interactable: Interactable = collider as Interactable
			if interactable != null:
				GUI.display_interact_label(interactable.interact_prompt)
			else:
				GUI.hide_interact_label()
		if collider is Map:
			var map: Map = collider as Map
			if map != null:
				if infinite_voiding:
					GUI.display_interact_label("Void wall [Uses left: ∞]")
				elif void_uses > 0:
					GUI.display_interact_label("Void wall [Uses left: " + str(void_uses) + "]")
				else:
					GUI.hide_interact_label()
			else:
				GUI.hide_interact_label()
	else:
		GUI.hide_interact_label()
	
	target_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if move_speed < target_speed:
		move_speed = lerp(move_speed, target_speed, acceleration * delta)
	elif move_speed > target_speed:
		move_speed = lerp(move_speed, target_speed, deceleration * delta)
	
	if flashlight_on:
		if not unlimited_flashlight:
			flashlight_charge -= flashlight_drain_rate * delta
			flashlight_charge = max(flashlight_charge, 0)  # Clamp to 0
		
		if flashlight_charge == 0:
			flashlight_on = false
			flashlight.visible = false
		
		var dist: float = global_transform.origin.distance_to(GameData.office_manager.global_transform.origin)
		if dist < off_distance:
			flicker_timer.stop()
			flashlight.light_energy = 0.05
		elif dist < flicker_distance:
			if flicker_timer.is_stopped():
				flicker_timer.start()
		else:
			flicker_timer.stop()
			flashlight.light_energy = 1
	
	GUI.update_flashlight_charge(flashlight_charge, flashlight_max_charge)
	
	#var current_speed := current_velocity.length()
	#var max_speed := sprint_speed
	#var speed_ratio := current_speed / max_speed
	#camera.fov = lerp(normal_fov, sprint_fov, clamp(speed_ratio, 0.0, 1.0))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get input direction.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# If no input, apply friction.
	if input_dir == Vector2.ZERO:
		current_velocity = current_velocity.lerp(Vector3.ZERO, friction * delta)
		if footstep_audio.playing:
			footstep_audio.stop()
	else:
		# Calculate desired movement direction and speed.
		var camera_forward := camera.transform.basis.z.normalized()
		var camera_right := camera.transform.basis.x.normalized()
		camera_forward.y = 0
		camera_right.y = 0
		camera_forward = camera_forward.normalized()
		camera_right = camera_right.normalized()
		var direction := (camera_right * input_dir.x + camera_forward * input_dir.y).normalized()
		current_velocity = direction * move_speed
		current_velocity = current_velocity.lerp(current_velocity, acceleration * delta)
		if is_on_floor() and not footstep_audio.playing and not GameData.exit.using_terminal:
			#footstep_audio.pitch_scale = randf_range(0.8, 1.2)
			footstep_audio.play()
	
	# Apply the computed velocity.
	velocity.x = current_velocity.x
	velocity.z = current_velocity.z
	
	if movement_restricted:
		velocity = Vector3.ZERO
	
	move_and_slide()
	
	#if is_on_floor() and velocity.length() > 0.1:
		#if !footstep_audio.playing:
			#footstep_audio.play()
		#
		#var playback_speed: float = 1.0
		#if move_speed > walk_speed:
			#playback_speed = 1.5
		#footstep_audio.pitch_scale = playback_speed
	#else:
		#if footstep_audio.playing:
			#footstep_audio.stop()

func stop_footstep_audio() -> void:
	footstep_audio.pitch_scale = 1.0
	footstep_audio.stop()

func restrict_movement() -> void:
	movement_restricted = true
	if flashlight_on:
		flashlight_was_visible = true
		flashlight_on = false

func enable_movement() -> void:
	movement_restricted = false
	if flashlight_was_visible:
		flashlight_on = true
		flashlight_was_visible = false

func teleport_random() -> void:
	var cell_size: float = GameData.map.cell_size
	var cell_pos: Vector2i = GameData.map.find_random_empty_cell().pos * cell_size
	var teleport_pos: Vector3 = Vector3(cell_pos.x, 0.0, cell_pos.y)
	global_position = teleport_pos
	teleport_audio.play()
