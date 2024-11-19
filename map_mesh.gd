extends MeshInstance3D
class_name MapMesh

const CELL_DIRECTIONS = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

var map: Map
var vertex_count: int

var collision_vertices: PackedVector3Array = PackedVector3Array()
var collision_indices: PackedInt32Array = PackedInt32Array()

func update_mesh() -> void:
	if map == null:
		return
	
	collision_vertices.clear()
	collision_indices.clear()
	mesh = null
	
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	vertex_count = 0
	
	for cell in map.cells:
		update_cell_faces(st, cell)
	
	st.index()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	mesh = array_mesh

func neighbor_exists(pos: Vector2i) -> bool:
	return pos in map.visited

func update_cell_faces(st: SurfaceTool, cell: Cell) -> void:
	var half_size: float = map.cell_size / 2.0
	var x: float = cell.pos.x * map.cell_size
	var z: float = cell.pos.y * map.cell_size
	var pos: Vector3 = Vector3(x, 0.0, z)
	
	add_ceiling_face(st, pos, half_size)
	add_floor_face(st, pos, half_size)
	
	for i in range(4):
		var offset: Vector2i = CELL_DIRECTIONS[i]
		var neighbor_pos: Vector2i = cell.pos + offset
		if not neighbor_exists(neighbor_pos):
			add_wall_face(st, pos, i, half_size, cell.pos)

func add_ceiling_face(st: SurfaceTool, pos: Vector3, half_size: float) -> void:
	var y_offset: float = map.wall_height
	var normal: Vector3 = Vector3.DOWN
	
	var vertices: Array[Vector3] = [
		pos + Vector3(-half_size, y_offset, half_size),
		pos + Vector3(half_size, y_offset, half_size),
		pos + Vector3(half_size, y_offset, -half_size),
		pos + Vector3(-half_size, y_offset, -half_size)
	]
	
	add_face(st, vertices, normal)

func add_floor_face(st: SurfaceTool, pos: Vector3, half_size: float) -> void:
	var normal: Vector3 = Vector3.UP
	
	var vertices: Array[Vector3] = [
		pos + Vector3(-half_size, 0.0, -half_size),
		pos + Vector3(half_size, 0.0, -half_size),
		pos + Vector3(half_size, 0.0, half_size),
		pos + Vector3(-half_size, 0.0, half_size)
	]
	
	add_face(st, vertices, normal)

func add_wall_face(st: SurfaceTool, pos: Vector3, direction_index: int, half_size: float, cell_pos: Vector2i) -> void:
	# Check if this cell has an exit on the given wall direction
	var direction: Vector2i = CELL_DIRECTIONS[direction_index]
	if map.exit_cells.has(cell_pos) and map.exit_cells[cell_pos] == direction:
		# Skip adding the wall face if there's an exit door
		add_wall_with_opening(st, pos, direction_index, half_size)
		return
	
	# Normal wall generation
	var vertices: Array[Vector3]
	var normal: Vector3
	
	match direction_index:
		0:  # Front wall
			normal = Vector3.BACK
			vertices = [
				pos + Vector3(half_size, 0, -half_size),
				pos + Vector3(-half_size, 0, -half_size),
				pos + Vector3(-half_size, map.wall_height, -half_size),
				pos + Vector3(half_size, map.wall_height, -half_size)
			]
		1:  # Back wall
			normal = Vector3.FORWARD
			vertices = [
				pos + Vector3(-half_size, 0, half_size),
				pos + Vector3(half_size, 0, half_size),
				pos + Vector3(half_size, map.wall_height, half_size),
				pos + Vector3(-half_size, map.wall_height, half_size)
			]
		2:  # Left wall
			normal = Vector3.RIGHT
			vertices = [
				pos + Vector3(-half_size, 0, -half_size),
				pos + Vector3(-half_size, 0, half_size),
				pos + Vector3(-half_size, map.wall_height, half_size),
				pos + Vector3(-half_size, map.wall_height, -half_size)
			]
		3:  # Right wall
			normal = Vector3.LEFT
			vertices = [
				pos + Vector3(half_size, 0, half_size),
				pos + Vector3(half_size, 0, -half_size),
				pos + Vector3(half_size, map.wall_height, -half_size),
				pos + Vector3(half_size, map.wall_height, half_size)
			]
	
	add_face(st, vertices, normal)

func add_wall_with_opening(st: SurfaceTool, pos: Vector3, direction_index: int, half_size: float) -> void:
	var opening_width: float = 2.5
	var opening_height: float = 3.5
	var opening_half_width: float = opening_width / 2.0
	
	# Calculate wall vertices relative to the cell position
	var normal: Vector3
	var bottom: float = 0.0
	var top: float = map.wall_height
	
	match direction_index:
		0:  # Front wall (facing -Z)
			normal = Vector3.BACK
			#print("front wall")
			
			# Top part of the wall above the opening (counterclockwise order)
			add_face(st, [
				pos + Vector3(half_size, opening_height, -half_size),
				pos + Vector3(-half_size, opening_height, -half_size),
				pos + Vector3(-half_size, top, -half_size),
				pos + Vector3(half_size, top, -half_size)
			], normal)
			
			# Left side of the opening (counterclockwise order)
			add_face(st, [
				pos + Vector3(-opening_half_width, bottom, -half_size),
				pos + Vector3(-half_size, bottom, -half_size),
				pos + Vector3(-half_size, opening_height, -half_size),
				pos + Vector3(-opening_half_width, opening_height, -half_size)
			], normal)
			
			# Right side of the opening (counterclockwise order)
			add_face(st, [
				pos + Vector3(half_size, bottom, -half_size),
				pos + Vector3(opening_half_width, bottom, -half_size),
				pos + Vector3(opening_half_width, opening_height, -half_size),
				pos + Vector3(half_size, opening_height, -half_size)
			], normal)
			
		1:  # Back wall (facing +Z)
			normal = Vector3.FORWARD
			#print("back wall")
			
			# Top part of the wall above the opening (counterclockwise order)
			add_face(st, [
				pos + Vector3(-half_size, opening_height, half_size),
				pos + Vector3(half_size, opening_height, half_size),
				pos + Vector3(half_size, top, half_size),
				pos + Vector3(-half_size, top, half_size)
			], normal)
			
			# Left side of the opening (counterclockwise order)
			add_face(st, [
				pos + Vector3(-half_size, bottom, half_size),
				pos + Vector3(-opening_half_width, bottom, half_size),
				pos + Vector3(-opening_half_width, opening_height, half_size),
				pos + Vector3(-half_size, opening_height, half_size)
			], normal)
			
			# Right side of the opening (counterclockwise order)
			add_face(st, [
				pos + Vector3(opening_half_width, bottom, half_size),
				pos + Vector3(half_size, bottom, half_size),
				pos + Vector3(half_size, opening_height, half_size),
				pos + Vector3(opening_half_width, opening_height, half_size)
			], normal)
			
		2:  # Left wall (facing -X)
			normal = Vector3.RIGHT
			#print("left wall")
			
			# Top part above the opening
			add_face(st, [
				pos + Vector3(-half_size, opening_height, -half_size),
				pos + Vector3(-half_size, opening_height, half_size),
				pos + Vector3(-half_size, top, half_size),
				pos + Vector3(-half_size, top, -half_size)
			], normal)
			
			# Left side of the opening
			add_face(st, [
				pos + Vector3(-half_size, bottom, -half_size),
				pos + Vector3(-half_size, bottom, -opening_half_width),
				pos + Vector3(-half_size, opening_height, -opening_half_width),
				pos + Vector3(-half_size, opening_height, -half_size)
			], normal)
			
			# Right side of the opening
			add_face(st, [
				pos + Vector3(-half_size, bottom, opening_half_width),
				pos + Vector3(-half_size, bottom, half_size),
				pos + Vector3(-half_size, opening_height, half_size),
				pos + Vector3(-half_size, opening_height, opening_half_width)
			], normal)
			
		3:  # Right wall (facing +X)
			normal = Vector3.LEFT
			#print("right wall")
			
			# Top part above the opening
			add_face(st, [
				pos + Vector3(half_size, opening_height, half_size),
				pos + Vector3(half_size, opening_height, -half_size),
				pos + Vector3(half_size, top, -half_size),
				pos + Vector3(half_size, top, half_size)
			], normal)
			
			# Left side of the opening
			add_face(st, [
				pos + Vector3(half_size, bottom, -opening_half_width),
				pos + Vector3(half_size, bottom, -half_size),
				pos + Vector3(half_size, opening_height, -half_size),
				pos + Vector3(half_size, opening_height, -opening_half_width)
			], normal)
			
			# Right side of the opening
			add_face(st, [
				pos + Vector3(half_size, bottom, half_size),
				pos + Vector3(half_size, bottom, opening_half_width),
				pos + Vector3(half_size, opening_height, opening_half_width),
				pos + Vector3(half_size, opening_height, half_size)
			], normal)

func add_face(st: SurfaceTool, vertices: Array[Vector3], normal: Vector3) -> void:
	for vertex in vertices:
		st.set_normal(normal)
		st.add_vertex(vertex)
		vertex_count += 1
		#print(vertex_count)
	
	st.add_index(vertex_count - 4)
	st.add_index(vertex_count - 3)
	st.add_index(vertex_count - 2)
	st.add_index(vertex_count - 4)
	st.add_index(vertex_count - 2)
	st.add_index(vertex_count - 1)
	
	collision_vertices.append_array(vertices)
	collision_indices.append(vertex_count - 4)
	collision_indices.append(vertex_count - 3)
	collision_indices.append(vertex_count - 2)
	collision_indices.append(vertex_count - 4)
	collision_indices.append(vertex_count - 2)
	collision_indices.append(vertex_count - 1)
