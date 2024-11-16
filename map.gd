extends StaticBody3D
class_name Map

@onready var map_mesh: MapMesh = $MapMesh
@onready var map_collider: CollisionShape3D = $MapCollider

@export var cell_size: float = 6.0
@export var wall_height: float = 6.0
@export var map_width: int = 40
@export var map_height: int = 40

@export var room_probability: float = 0.01
@export var room_min_size: int = 2
@export var room_max_size: int = 5

@export var exit_scene: PackedScene

var cells: Array[Cell]
var walls: Array[Cell]
var visited: Dictionary
var exit_cells: Dictionary

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

func _ready() -> void:
	generate_map()
	spawn_exit()
	map_mesh.map = self
	map_mesh.update_mesh()
	update_collider()

func update_collider() -> void:
	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	shape.set_faces(get_faces())
	map_collider.shape = shape

func get_faces() -> PackedVector3Array:
	var vertices: PackedVector3Array = map_mesh.collision_vertices
	var indices: PackedInt32Array = map_mesh.collision_indices
	var faces: PackedVector3Array = PackedVector3Array()
	for i in range(0, indices.size(), 3):
		faces.append_array([vertices[indices[i]], vertices[indices[i+1]], vertices[indices[i+2]]])
	return faces

func generate_map() -> void:
	cells.clear()
	visited.clear()
	walls.clear()
	
	var start_cell: Cell = Cell.new(Vector2i(0, 0))
	carve(start_cell)
	
	# Carve passages using Prim's Algorithm
	while walls.size() > 0:
		var random_index: int = randi() % walls.size()
		var wall_cell: Cell = walls[random_index]
		walls.erase(wall_cell)
		
		if can_carve(wall_cell):
			carve(wall_cell)

func carve(cell: Cell) -> void:
	if not visited.has(cell.pos):
		cells.append(cell)
		visited[cell.pos] = cell
		if randf() < room_probability:
			generate_room_around(cell)
	
	for direction in DIRECTIONS:
		var neighbor_pos: Vector2i = cell.pos + direction
		if is_within_bounds(neighbor_pos) and not visited.has(neighbor_pos):
			var neighbor_cell: Cell = Cell.new(neighbor_pos)
			walls.append(neighbor_cell)

func can_carve(cell: Cell) -> bool:
	var unvisited_neighbors: int = 0
	for direction in DIRECTIONS:
		var neighbor_pos: Vector2i = cell.pos + direction
		if visited.has(neighbor_pos):
			unvisited_neighbors += 1
	return unvisited_neighbors == 1

func generate_room_around(center: Cell) -> void:
	var room_width: int = randi_range(room_min_size, room_max_size)
	var room_height: int = randi_range(room_min_size, room_max_size)
	
	var start_x: int = center.pos.x - room_width / 2
	var start_y: int = center.pos.y - room_height / 2
	
	for x in range(start_x, start_x + room_width):
		for y in range(start_y, start_y + room_height):
			var room_pos: Vector2i = Vector2i(x, y)
			if is_within_bounds(room_pos) and not visited.has(room_pos):
				var room_cell: Cell = Cell.new(room_pos)
				cells.append(room_cell)
				visited[room_pos] = room_cell

func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= -map_width / 2 and pos.x <= map_width / 2 and pos.y >= -map_height / 2 and pos.y <= map_height / 2

func find_cell_near_center_with_wall() -> Cell:
	var center: Vector2i = Vector2i(0, 0)
	var closest_cell: Cell = null
	var min_distance: float = INF
	
	# Iterate over all cells to find the one closest to the center with at least one wall
	for cell in cells:
		if has_wall(cell):
			var distance: float = cell.pos.distance_to(center)
			if distance < min_distance:
				min_distance = distance
				closest_cell = cell
	
	return closest_cell

func has_wall(cell: Cell) -> bool:
	for direction in DIRECTIONS:
		var neighbor_pos: Vector2i = cell.pos + direction
		if not visited.has(neighbor_pos):
			return true
	return false

func spawn_exit() -> void:
	var cell: Cell = find_cell_near_center_with_wall()
	if cell == null:
		print("No suitable cell found for exit door.")
		return
	
	# Load and instance the exit door scene
	var exit: Node3D = exit_scene.instantiate() as Node3D
	var wall_direction: Vector2i = get_wall_direction(cell)
	
	# Place the door at the wall of the cell
	if wall_direction != Vector2i.ZERO:
		var exit_position: Vector3 = get_wall_position(cell, wall_direction)
		var exit_rotation: Vector3 = get_wall_rotation(wall_direction)
		
		exit.transform.origin = exit_position
		exit.rotation_degrees = exit_rotation
		
		add_child(exit)
		print("Exit spawned at:", exit_position)
		
		# Record the cell and direction for creating an opening
		exit_cells[cell.pos] = wall_direction

func get_wall_direction(cell: Cell) -> Vector2i:
	for direction in DIRECTIONS:
		var neighbor_pos: Vector2i = cell.pos + direction
		if not visited.has(neighbor_pos):
			return direction
	return Vector2i.ZERO

func get_wall_position(cell: Cell, direction: Vector2i) -> Vector3:
	var half_size: float = cell_size / 2.0
	var x: float = cell.pos.x * cell_size
	var z: float = cell.pos.y * cell_size
	var pos: Vector3 = Vector3(x, 0.0, z)
	
	match direction:
		Vector2i.UP:    pos += Vector3(0, 0, -half_size)
		Vector2i.DOWN:  pos += Vector3(0, 0, half_size)
		Vector2i.LEFT:  pos += Vector3(-half_size, 0, 0)
		Vector2i.RIGHT: pos += Vector3(half_size, 0, 0)
	
	return pos

func get_wall_rotation(direction: Vector2i) -> Vector3:
	match direction:
		Vector2i.UP:
			return Vector3(0, 180, 0)  # Facing back (towards +Z)
		Vector2i.DOWN:
			return Vector3(0, 0, 0)    # Facing forward (towards -Z)
		Vector2i.LEFT:
			return Vector3(0, -90, 0)   # Facing right (towards +X)
		Vector2i.RIGHT:
			return Vector3(0, 90, 0)  # Facing left (towards -X)
	return Vector3.ZERO
