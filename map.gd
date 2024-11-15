extends StaticBody3D
class_name Map

@onready var map_mesh: MapMesh = $MapMesh
@onready var map_collider: CollisionShape3D = $MapCollider

@export var cell_size: float = 4.0
@export var wall_height: float = 6.0
@export var map_width: int = 40
@export var map_height: int = 40

var cells: Array[Vector2i]
var visited: Dictionary
var walls: Array[Vector2i]

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

func _ready() -> void:
	generate_map()
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
	
	# Start at (0, 0)
	var start_pos: Vector2i = Vector2i(0, 0)
	carve(start_pos)
	
	# Carve passages using Prim's Algorithm
	while walls.size() > 0:
		# Pick a random wall from the list
		var random_wall_index: int = randi() % walls.size()
		var wall_pos: Vector2i = walls[random_wall_index]
		walls.erase(wall_pos)
		
		# Check if carving here connects two unconnected regions
		if can_carve(wall_pos):
			carve(wall_pos)

func carve(pos: Vector2i) -> void:
	if not visited.get(pos, false):
		cells.append(pos)
		visited[pos] = true
	
	# Add neighboring walls to the list
	for direction in DIRECTIONS:
		var next_pos: Vector2i = pos + direction
		if not visited.get(next_pos, false) and is_within_bounds(next_pos):
			walls.append(next_pos)

func can_carve(pos: Vector2i) -> bool:
	var unvisited_neighbors: int = 0
	
	# Count how many neighbors are unvisited
	for direction in DIRECTIONS:
		var neighbor_pos: Vector2i = pos + direction
		if visited.get(neighbor_pos, false):
			unvisited_neighbors += 1
	
	# Carve only if it connects exactly one visited cell (i.e., creates a passage)
	return unvisited_neighbors == 1

func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= -map_width / 2.0 and pos.x <= map_width / 2.0 and pos.y >= -map_height / 2.0 and pos.y <= map_height / 2.0

# Function to ensure all cells are accessible
func ensure_connectivity() -> void:
	var connected_cells: Array[Vector2i] = []
	var queue: Array[Vector2i] = [Vector2i(0, 0)]
	var visited_check: Dictionary = {}
	
	# Flood-fill to find all connected cells
	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		connected_cells.append(current)
		visited_check[current] = true
		
		for direction in DIRECTIONS:
			var neighbor: Vector2i = current + direction
			if visited.get(neighbor, false) and not visited_check.has(neighbor):
				queue.append(neighbor)
	
	# Identify isolated cells and connect them
	var isolated_cells: Array[Vector2i] = []
	for cell in cells:
		if not visited_check.has(cell):
			isolated_cells.append(cell)
	
	# Connect each isolated cell to the nearest connected cell
	for isolated in isolated_cells:
		connect_to_maze(isolated, visited_check)

# Function to connect an isolated cell to the nearest connected cell
func connect_to_maze(cell: Vector2i, visited_check: Dictionary) -> void:
	var closest_cell: Vector2i = Vector2i()
	var min_distance: float = INF
	
	# Find the nearest connected cell
	for connected: Vector2i in visited_check.keys():
		var distance: float = cell.distance_to(connected)
		if distance < min_distance:
			min_distance = distance
			closest_cell = connected
	
	# Carve a path from the isolated cell to the nearest connected cell
	if min_distance < INF:
		carve_path(cell, closest_cell)

# Function to carve a straight path between two cells
func carve_path(start: Vector2i, end: Vector2i) -> void:
	var current_pos: Vector2i = start
	
	# Carve a path by moving horizontally first, then vertically
	while current_pos.x != end.x:
		current_pos.x += sign(end.x - current_pos.x)
		carve(current_pos)
	
	while current_pos.y != end.y:
		current_pos.y += sign(end.y - current_pos.y)
		carve(current_pos)
