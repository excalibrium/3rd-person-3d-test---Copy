# tool makes it so code runs in the editor before the game starts.
@tool
extends Node3D

class_name Ground

## Size in meters. Expands the floor from the middle point to x/2 meters right and x/2 meters left.
@export var FloorSize: Vector2 = Vector2(2, 2):
	get:
		return FloorSize
	set(val):
		FloorSize = val
		set_mesh_size(val)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_mesh_size(val):
	# Workaround bug that causes this function to run before the scene is loaded.
	if is_node_ready():
		$StaticBody3D/MeshInstance3D.mesh.size = val
		$StaticBody3D/CollisionShape3D.shape.size = Vector3(val.x, 2, val.y)
	else:
		await ready
		set_mesh_size(val)
