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
	
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	vertex_count = 0
	
	for cell in map.cells:
		update_cell_faces(st, cell)
	
	st.index()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	mesh = array_mesh

func neighbor_exists(pos: Vector2i, cells: Array[Vector2i]) -> bool:
	return pos in cells

func update_cell_faces(st: SurfaceTool, cell: Vector2i) -> void:
	var half_size: float = map.cell_size / 2.0
	var x: float = cell.x * map.cell_size
	var z: float = cell.y * map.cell_size
	var pos: Vector3 = Vector3(x, 0.0, z)
	
	add_ceiling_face(st, pos, half_size)
	add_floor_face(st, pos, half_size)
	
	for i in range(4):
		var offset: Vector2i = CELL_DIRECTIONS[i]
		var neighbor_pos: Vector2i = cell + offset
		
		if not neighbor_exists(neighbor_pos, map.cells):
			add_wall_face(st, pos, i, half_size)

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

func add_wall_face(st: SurfaceTool, pos: Vector3, direction_index: int, half_size: float) -> void:
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
