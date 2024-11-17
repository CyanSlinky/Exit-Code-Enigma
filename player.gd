extends CharacterBody3D

@onready var camera: CameraController = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight

@onready var overview_camera: Camera3D = $OverviewCamera
@onready var overview_light: DirectionalLight3D = $OverviewCamera/OverviewLight

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 15.0
@export var acceleration: float = 5.0
@export var deceleration: float = 5.0
@export var friction: float = 10.0
@export var jump_velocity: float = 4.5

@export var normal_fov: float = 75.0
@export var sprint_fov: float = 80.0
@export var shake_intensity: float = 0.1

var move_speed: float
var target_speed: float
var current_velocity: Vector3

func _ready() -> void:
	camera.current = true
	overview_light.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	move_speed = walk_speed

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_cursor_visibility"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = !flashlight.visible
	
	if Input.is_action_just_pressed("toggle_overview"):
		if overview_camera.current:
			camera.current = true
			overview_light.visible = false
		else:
			overview_camera.current = true
			overview_light.visible = true

func _process(delta: float) -> void:
	target_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if move_speed < target_speed:
		move_speed = lerp(move_speed, target_speed, acceleration * delta)
	elif move_speed > target_speed:
		move_speed = lerp(move_speed, target_speed, deceleration * delta)
	
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
	
	# Apply the computed velocity.
	velocity.x = current_velocity.x
	velocity.z = current_velocity.z
	
	move_and_slide()
