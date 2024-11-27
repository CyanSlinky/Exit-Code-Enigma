extends Node3D
class_name VoidWall

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func update_size(size: Vector3) -> void:
	await ready
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
