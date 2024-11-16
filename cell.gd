extends RefCounted
class_name Cell

var pos: Vector2i
var visited: bool = false

func _init(position: Vector2i) -> void:
	pos = position
	visited = false
