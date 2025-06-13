@tool
extends Node3D

@export var progress := false
@export var active := false
@onready var path_follow_3d: PathFollow3D = $Path3D/PathFollow3D
@onready var path_3d: Path3D = $Path3D
@export var gravity := 1.0
@export var trajectory := Vector3(0.0, 0.0, 0.0)
@export var speed_multiplier := 1.0  # Controls how fast splats move along the path

@export_category("Properties")
@export var point_based := true
@export var points := 5
@export var lifetime := 1.0

@export_category("Splat Properties")
@export var splats := 10
@export var spawn_delay := 0.05  # Time between spawning each splat
@export var splat_scene: PackedScene  # Can be a MeshInstance3D with QuadMesh scene
@export var splat_material: Material  # Material to use when creating splats on the fly
@export var randomize_rotation := true
@export var scale_variation := 0.2

var splat_instances = []
var elapsed_time := 0.0
var last_spawn_time := 0.0
var is_spawning := false
var spawn_count := 0

func _ready():
	# Just make sure at least path_3d exists
	if not path_3d:
		push_error("Path3D node is required!")
		return

func _physics_process(delta: float) -> void:
	if progress:
		elapsed_time += delta
		
		# Check if it's time to spawn another splat
		if is_spawning and elapsed_time - last_spawn_time >= spawn_delay and spawn_count < splats:
			spawn_splat()
			last_spawn_time = elapsed_time
			spawn_count += 1
			
		# Check if we've finished spawning all splats
		if spawn_count >= splats:
			is_spawning = false
	
	if active == true:
		calculate_splat()
		start_spawning()
		active = false
	
	# Update existing splats
	update_splats(delta)
	
func calculate_splat() -> void:
	if not path_3d or not path_3d.curve:
		return
		
	path_3d.curve.clear_points()
	
	# Add starting point
	path_3d.curve.add_point(Vector3.ZERO)
	
	# Calculate trajectory points
	for i in range(1, points + 1):
		var t = float(i) / points * lifetime
		var point_position = Vector3.ZERO + trajectory * t + Vector3(0.0, -0.5 * gravity * t * t, 0.0)
		path_3d.curve.add_point(point_position)

func start_spawning():
	elapsed_time = 0.0
	last_spawn_time = -spawn_delay  # Start the first splat immediately
	is_spawning = true
	spawn_count = 0
	
	# Clear any existing splats
	for splat in splat_instances:
		if is_instance_valid(splat):
			splat.queue_free()
	
	splat_instances.clear()

func spawn_splat():
	var splat_instance
	
	if splat_scene:
		# Use the provided PackedScene
		splat_instance = splat_scene.instantiate()
		splat_instance.scale = Vector3(0.3,0.3, 0.3)
	else:
		# Create a MeshInstance3D with QuadMesh on the fly
		splat_instance = MeshInstance3D.new()
		
		# Create and set up a QuadMesh
		var plane_mesh = PlaneMesh.new()
		plane_mesh.size = Vector2(0.01, 0.01)  # Default size
		splat_instance.mesh = plane_mesh
		
		# Apply material if provided
		if splat_material:
			splat_instance.material_override = splat_material
	
	# Randomize the scale if needed
	if scale_variation > 0:
		var scale_factor = 1.0 + randf_range(-scale_variation, scale_variation)
		
		# Handle scaling differently based on node type
		if splat_instance is MeshInstance3D and splat_instance.mesh is PlaneMesh:
			# For QuadMesh, we need to modify the mesh size directly
			var plane_mesh = splat_instance.mesh as PlaneMesh
			plane_mesh.size = Vector2.ONE * scale_factor
		else:
			# For other types, we can use the regular scale property
			splat_instance.scale = Vector3.ONE * scale_factor
	
	# Randomize rotation if needed
	if randomize_rotation:
		splat_instance.rotation = Vector3(
			randf_range(0, TAU),
			randf_range(0, TAU),
			randf_range(0, TAU)
		)
	
	# Store spawn time for progress tracking
	splat_instance.set_meta("spawn_time", elapsed_time)
	splat_instance.set_meta("progress", 0.0)  # Track progress along path (0.0 to 1.0)
	
	# Add to the scene tree
	add_child(splat_instance)
	splat_instances.append(splat_instance)
	
	# Position at the start of the path
	position_splat_on_path(splat_instance, 0.0)

func position_splat_on_path(splat_instance, ratio):
	if not path_3d or not path_3d.curve or path_3d.curve.point_count == 0:
		return
		
	# Position along the curve
	var position = path_3d.curve.sample_baked(ratio * path_3d.curve.get_baked_length())
	splat_instance.global_transform.origin = global_transform.origin + position

func update_splats(delta):
	if not progress:
		return
		
	var i = 0
	while i < splat_instances.size():
		var splat = splat_instances[i]
		
		if not is_instance_valid(splat):
			splat_instances.remove_at(i)
			continue
		
		# Update progress along path
		var current_progress = splat.get_meta("progress")
		current_progress += delta * speed_multiplier / lifetime
		splat.set_meta("progress", current_progress)
		
		# Check if splat has reached the end of the path
		if current_progress >= 1.0:
			splat.queue_free()
			
			splat_instances.remove_at(i)
			continue
		
		# Update position on path
		position_splat_on_path(splat, current_progress)
		i += 1
