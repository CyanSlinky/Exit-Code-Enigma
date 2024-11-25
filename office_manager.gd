extends CharacterBody3D
class_name OfficeManager

@onready var armature: Node3D = $Armature
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var character: MeshInstance3D = $Armature/Skeleton3D/Character
@onready var tie: MeshInstance3D = $Armature/Skeleton3D/Tie
@onready var map_indicator: MeshInstance3D = $MapIndicator

@export var speed: float = 2.0
@export var min_stop_duration: float = 2.0  # Minimum stop duration (in secs)
@export var max_stop_duration: float = 5.0  # Maximum stop duration (in secs)
@export var stop_chance: float = 0.3  # Chance to stop at a cell
@export var visit_penalty: int = 1  # Penalty increment for visited cells
@export var exploration_chance: float = 0.1  # Chance to force exploration
@export var additional_oscillation_penalty: int = 5  # Extra penalty for oscillation
@export var max_recent_path_length: int = 10  # Maximum recent path history

enum ManagerType {
	EVIL,
	GOOD,
	AMBIVALENT
}

var manager_type: ManagerType
var manager_color: Color

var map: Map
var current_target: Vector3 = Vector3.ZERO
var current_cell: Vector2i = Vector2i.ZERO
var previous_cell: Vector2i = Vector2i.ZERO

var is_stopping: bool = false
var stop_timer: float = 0.0
var cell_penalty_tracker: Dictionary = {}  # Tracks penalty scores for cells
var recent_path: Array[Vector2i] = []  # Tracks the recent path history

func _ready() -> void:
	GameData.office_manager = self
	randomize()
	initialize_manager_type()
	# Initialize the current cell based on the manager's starting position
	current_cell = map_position_to_cell(position)
	previous_cell = current_cell
	update_cell_penalty(current_cell)
	choose_new_target()

func initialize_manager_type() -> void:
	manager_type = ManagerType.values().pick_random()
	var char_mat: Material = character.get_surface_override_material(0).get_next_pass()
	var tie_mat: Material = tie.get_surface_override_material(0)
	var map_mat: Material = map_indicator.material_override
	match manager_type:
		ManagerType.EVIL:
			manager_color = Color.RED
		ManagerType.GOOD:
			manager_color = Color.DEEP_SKY_BLUE
		ManagerType.AMBIVALENT:
			manager_color = Color.LIGHT_SLATE_GRAY
	
	char_mat.set("albedo_color", manager_color)
	tie_mat.set("albedo_color", manager_color)
	map_mat.set("albedo_color", manager_color)

func _physics_process(delta: float) -> void:
	if is_stopping:
		handle_stop(delta)
	else:
		move_along_path()

func move_along_path() -> void:
	# Check if the manager has reached the current target
	if position.distance_to(current_target) < 0.1:
		# Reached the current target
		update_cell_penalty(current_cell)
		
		if current_cell == previous_cell:
			# Force a stop if walking back to the previous cell
			begin_stop()
		elif randf() < stop_chance:
			# Random chance to stop
			begin_stop()
		else:
			choose_new_target()
		return
	
	# Move towards the current target
	var direction: Vector3 = (current_target - position).normalized()
	velocity = direction * speed
	move_and_slide()
	face_direction(-direction)
	play_walk_animation()

func choose_new_target() -> void:
	# Get adjacent cells
	var neighbors: Array[Vector2i] = get_adjacent_cells(current_cell)
	if neighbors.size() == 0:
		#print("No valid neighbors to move to.")
		return # Exit early if no neighbors are valid
	
	# Declare chosen_cell with a fallback to the current cell
	var chosen_cell: Vector2i = current_cell
	
	# Random exploration bias
	if randf() < exploration_chance:
		var unvisited: Array[Vector2i] = []
		for neighbor in neighbors:
			if not cell_penalty_tracker.has(neighbor):
				unvisited.append(neighbor)
		if unvisited.size() > 0:
			chosen_cell = unvisited[randi() % unvisited.size()]
		else:
			chosen_cell = neighbors[randi() % neighbors.size()]
	else:
		# Penalize revisits and recent path
		var lowest_score: float = INF
		for neighbor in neighbors:
			var penalty: int = cell_penalty_tracker.get(neighbor, 0)
			if neighbor == previous_cell:
				penalty += additional_oscillation_penalty
			if recent_path.has(neighbor):
				penalty += additional_oscillation_penalty
			if penalty < lowest_score:
				lowest_score = penalty
				chosen_cell = neighbor
	
	# Update recent path
	update_recent_path(current_cell)
	previous_cell = current_cell
	current_cell = chosen_cell
	
	# Calculate the new target position in 3D space
	current_target = Vector3(current_cell.x * map.cell_size, 0, current_cell.y * map.cell_size)
	#print("New target chosen: ", current_target, " with penalty: ", cell_penalty_tracker.get(current_cell, 0))

func get_adjacent_cells(cell: Vector2i) -> Array[Vector2i]:
	var adjacent_cells: Array[Vector2i] = []
	for direction: Vector2i in map.DIRECTIONS:
		var neighbor: Vector2i = cell + direction
		# Ensure the neighbor is within bounds and is a valid cell
		if map.visited.has(neighbor):
			adjacent_cells.append(neighbor)
	return adjacent_cells

func map_position_to_cell(pos: Vector3) -> Vector2i:
	# Convert a 3D position to a 2D cell coordinate
	return Vector2i(
		int(pos.x / map.cell_size),
		int(pos.z / map.cell_size)
	)

func begin_stop() -> void:
	is_stopping = true
	stop_timer = randf_range(min_stop_duration, max_stop_duration)
	play_idle_animation()

func handle_stop(delta: float) -> void:
	stop_timer -= delta
	if stop_timer <= 0.0:
		is_stopping = false
		choose_new_target()

func face_direction(direction: Vector3) -> void:
	# Rotate the model to face the movement direction
	armature.look_at(position + direction, Vector3.UP)

func play_walk_animation() -> void:
	if animator.is_playing() and animator.current_animation == "Walk Forward":
		return
	animator.play("Walk Forward")

func play_idle_animation() -> void:
	if animator.is_playing() and animator.current_animation == "Idle":
		return
	animator.play("Idle")

func update_cell_penalty(cell: Vector2i) -> void:
	# Increment the penalty score for the visited cell
	if not cell_penalty_tracker.has(cell):
		cell_penalty_tracker[cell] = 0
	cell_penalty_tracker[cell] += visit_penalty
	#print("Updated penalty for cell ", cell, " to ", cell_penalty_tracker[cell])

func update_recent_path(cell: Vector2i) -> void:
	# Track recent path history
	recent_path.append(cell)
	if recent_path.size() > max_recent_path_length:
		recent_path.pop_front()

func _on_interactable_interaction_occurred() -> void:
	match manager_type:
		ManagerType.EVIL:
			GUI.display_notification("What happened?")
			GameData.start_game() # restarts the game.
		ManagerType.GOOD:
			GUI.display_notification("The exit code is: " + GameData.exit_code)
			for i in GameData.exit_code.length():
				GUI.update_character(i + 1, GameData.exit_code[i])
		ManagerType.AMBIVALENT:
			var choice: int = randi_range(0, 1)
			if choice == 0:
				GUI.display_notification("What happened?")
				GameData.start_game() # restarts the game.
			else:
				GUI.display_notification("The exit code is: " + GameData.exit_code)
				for i in GameData.exit_code.length():
					GUI.update_character(i + 1, GameData.exit_code[i])
