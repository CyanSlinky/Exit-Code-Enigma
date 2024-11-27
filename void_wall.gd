extends Node3D
class_name VoidWall

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var void_audio: AudioStreamPlayer3D = $VoidAudio

func update_size(size: Vector3) -> void:
	await ready
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	void_audio.play()
