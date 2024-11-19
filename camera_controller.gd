extends Camera3D
class_name CameraController

@export var min_pitch: float = -89.0 # Minimum vertical angle (in degrees)
@export var max_pitch: float = 89.0  # Maximum vertical angle (in degrees)
@export var min_yaw: float = -90.0   # Minimum horizontal angle (in degrees)
@export var max_yaw: float = 90.0    # Maximum horizontal angle (in degrees)

@export var mouse_sensitivity: float = 0.2

var pitch: float
var yaw: float

var locked: bool
var lock_yaw: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pitch = rotation_degrees.x
	yaw = rotation_degrees.y

func _unhandled_input(event: InputEvent) -> void:
	if not current:
		return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pitch -= event.relative.y * mouse_sensitivity
		yaw -= event.relative.x * mouse_sensitivity
		
		pitch = clamp(pitch, min_pitch, max_pitch)
		if lock_yaw:
			yaw = clamp(yaw, min_yaw, max_yaw)

func _physics_process(_delta: float) -> void:
	if locked:
		return
	
	rotation_degrees.x = pitch
	rotation_degrees.y = yaw
