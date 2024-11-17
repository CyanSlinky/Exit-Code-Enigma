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

@export var shelf_scene: PackedScene
@export var shelf_probability: float = 0.05
@export var shelf_cluster_probability: float = 0.3
@export var shelf_offset: float = 0.6

@export var ceiling_light_scene: PackedScene
@export var ceiling_light_probability: float = 0.1

@export var sticky_note_scene: PackedScene
@export var num_sticky_notes: int = 10
@export var min_distance_between_notes: int = 3
@export var sticky_note_vertical_range: float = 1.0  # Max vertical offset up/down
@export var sticky_note_horizontal_range: float = 1.0  # Max horizontal offset left/right

var cells: Array[Cell]
var walls: Array[Cell]
var visited: Dictionary
var exit_cells: Dictionary
var shelf_cells: Dictionary

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

func _ready() -> void:
	generate_map()
	spawn_exit()
	spawn_shelf()
	spawn_ceiling_lights()
	spawn_sticky_notes()
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
		#print("Exit spawned at:", exit_position)
		
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

func spawn_shelf() -> void:
	if shelf_scene == null:
		return
	
	#var shelf_cells: Dictionary
	
	# Iterate over all cells to randomly place shelf
	for cell in cells:
		# Skip the exit cell
		if exit_cells.has(cell.pos):
			continue
		
		# Determine the base probability for this cell
		var probability: float = shelf_probability
		
		# Increase probability if there's shelf nearby
		for direction in DIRECTIONS:
			var neighbor_pos: Vector2i = cell.pos + direction
			if shelf_cells.has(neighbor_pos):
				probability += shelf_cluster_probability
				break
		
		# Attempt to place shelf based on the calculated probability
		if randf() < probability and has_wall(cell):
			place_shelf_in_cell(cell)
			#shelf_cells[cell.pos] = true

func place_shelf_in_cell(cell: Cell) -> void:
	var wall_direction: Vector2i = get_wall_direction(cell)
	if wall_direction == Vector2i.ZERO:
		return  # No valid wall to place shelf
	
	var shelf: Node3D = shelf_scene.instantiate() as Node3D
	var shelf_position: Vector3 = get_wall_position(cell, wall_direction)
	var shelf_rotation: Vector3 = get_wall_rotation(wall_direction)
	
	var offset: Vector3
	
	match wall_direction:
		Vector2i.UP:
			offset = Vector3(0, 0, shelf_offset)
		Vector2i.DOWN:
			offset = Vector3(0, 0, -shelf_offset)
		Vector2i.LEFT:
			offset = Vector3(shelf_offset, 0, 0)
		Vector2i.RIGHT:
			offset = Vector3(-shelf_offset, 0, 0)
	
	shelf.transform.origin = shelf_position + offset
	shelf.rotation_degrees = shelf_rotation
	add_child(shelf)
	
	# Mark this cell and wall as having a shelf
	if not shelf_cells.has(cell.pos):
		shelf_cells[cell.pos] = {}
	
	shelf_cells[cell.pos][wall_direction] = true

func spawn_sticky_notes() -> void:
	if sticky_note_scene == null or num_sticky_notes <= 0:
		return
	
	var placed_notes: Array[Vector2i] = []
	
	for i in range(num_sticky_notes):
		var cell: Cell = find_random_cell_with_free_wall(placed_notes)
		if cell == null:
			print("No suitable cell found for sticky note, placing randomly.")
			cell = find_random_empty_cell()
		
		place_sticky_note_in_cell(cell)
		placed_notes.append(cell.pos)

func find_random_cell_with_free_wall(placed_notes: Array[Vector2i]) -> Cell:
	var attempts: int = 100
	while attempts > 0:
		var cell: Cell = cells[randi() % cells.size()]
		
		# Skip the exit cell
		if exit_cells.has(cell.pos):
			attempts -= 1
			continue
		
		# Check if the cell has at least one free wall
		if get_free_wall_direction(cell) == Vector2i.ZERO:
			attempts -= 1
			continue
		
		# Check if the cell is too close to existing sticky notes
		var is_too_close: bool = false
		for note_pos in placed_notes:
			if note_pos.distance_to(cell.pos) < min_distance_between_notes:
				is_too_close = true
				break
		
		if not is_too_close:
			return cell
		
		attempts -= 1
	
	return null

func find_random_empty_cell() -> Cell:
	var attempts: int = 100
	while attempts > 0:
		var cell: Cell = cells[randi() % cells.size()]
		
		# Ensure the cell is not the exit and doesn't have shelves
		if not shelf_cells.has(cell.pos) and not exit_cells.has(cell.pos):
			return cell
		
		attempts -= 1
	
	# Fallback to any random cell if all else fails
	return cells[randi() % cells.size()]

func place_sticky_note_in_cell(cell: Cell) -> void:
	var wall_direction: Vector2i = get_free_wall_direction(cell)
	if wall_direction == Vector2i.ZERO:
		return
	
	var sticky_note: Node3D = sticky_note_scene.instantiate() as Node3D
	var sticky_note_position: Vector3 = get_wall_position(cell, wall_direction)
	var sticky_note_rotation: Vector3 = get_wall_rotation(wall_direction)
	
	# Adjust the height to place the note above the ground
	sticky_note_position += Vector3.UP * wall_height / 3.0
	
	# Add a small random rotation to make it look natural
	sticky_note_rotation.z = randf_range(-10.0, 10.0)  # Small tilt
	
	# Add random vertical offset (up and down)
	sticky_note_position.y += randf_range(-sticky_note_vertical_range, sticky_note_vertical_range)
	
	# Add random horizontal offset (left and right relative to the wall)
	var horizontal_offset: float = randf_range(-sticky_note_horizontal_range, sticky_note_horizontal_range)
	match wall_direction:
		Vector2i.UP, Vector2i.DOWN:
			sticky_note_position.x += horizontal_offset  # Offset along X axis for front/back walls
		Vector2i.LEFT, Vector2i.RIGHT:
			sticky_note_position.z += horizontal_offset  # Offset along Z axis for side walls
	
	sticky_note.transform.origin = sticky_note_position
	sticky_note.rotation_degrees = sticky_note_rotation
	add_child(sticky_note)

func get_free_wall_direction(cell: Cell) -> Vector2i:
	for direction in DIRECTIONS:
		var neighbor_pos: Vector2i = cell.pos + direction
		
		# Check if there's a wall in this direction
		if not visited.has(neighbor_pos):
			# Skip if a shelf is already on this wall
			if shelf_cells.has(cell.pos) and shelf_cells[cell.pos].has(direction):
				continue
			
			return direction  # Wall found
	return Vector2i.ZERO  # No free wall found

func spawn_ceiling_lights() -> void:
	if ceiling_light_scene == null:
		return
	
	for cell in cells:
		# Skip cells that already have certain features like exits or shelves if necessary
		if exit_cells.has(cell.pos) or shelf_cells.has(cell.pos):
			continue
		
		# Place a ceiling light based on the probability
		if randf() < ceiling_light_probability:
			place_ceiling_light_in_cell(cell)

func place_ceiling_light_in_cell(cell: Cell) -> void:
	var ceiling_light: Node3D = ceiling_light_scene.instantiate() as Node3D
	
	# Calculate the positions at the centers of the quarters of the cell
	var quarter_offset: float = cell_size / 4.0
	var base_x: float = cell.pos.x * cell_size - cell_size / 2 + quarter_offset
	var base_z: float = cell.pos.y * cell_size - cell_size / 2 + quarter_offset
	var y: float = wall_height  # Assuming the light hangs from the ceiling at wall height
	
	# Define the four possible positions
	var positions: Array = [
		Vector3(base_x, y, base_z),
		Vector3(base_x + cell_size / 2, y, base_z),
		Vector3(base_x, y, base_z + cell_size / 2),
		Vector3(base_x + cell_size / 2, y, base_z + cell_size / 2)
	]
	
	# Select a random position from the four
	var selected_position: Vector3 = positions[randi() % positions.size()]
	
	ceiling_light.transform.origin = selected_position
	#ceiling_light.rotation_degrees = Vector3(0, randf_range(0, 360), 0)  # Random rotation around the y-axis
	
	add_child(ceiling_light)
