extends Node3D
class_name Shelf

@export var spawn_probability: float = 0.25
@export var spawn_scenes: Array[PackedScene]
@export var spawn_positions: Array[Node3D]

var cell_pos: Vector2i

func _ready() -> void:
	randomize()
	spawn_on_shelf()

func spawn_on_shelf() -> void:
	for spawn_pos in spawn_positions:
		if randf() < spawn_probability:
			spawn(spawn_pos)

func spawn(pos: Node3D) -> void:
	var spawn_scene: PackedScene = spawn_scenes[randi() % spawn_scenes.size()]
	var spawn_instance: Node3D = spawn_scene.instantiate()
	pos.add_child(spawn_instance)
