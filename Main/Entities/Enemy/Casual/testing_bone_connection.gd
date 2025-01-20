@tool
extends Node3D

@export var sword_node: Node3D  # The Node3D representing the sword
@export var upper_body_bone: Node3D  # The upper body bone
@export var animation_player: AnimationPlayer
@export var skeleton: Skeleton3D  # The Skeleton3D node
@export var sword_bone_name: String  # The name of the sword bone in the skeleton
@export var debug_mode: bool = true  # Toggle for debug printing
@export var position_offset: Vector3 = Vector3.ZERO  # Additional offset from the upper body

var sword_bone_idx: int = -1

func _ready():
	print("Script is running. Checking initial setup...")
	if skeleton and sword_bone_name:
		sword_bone_idx = skeleton.find_bone(sword_bone_name)
		if sword_bone_idx == -1:
			push_error("Could not find bone named " + sword_bone_name + " in the skeleton.")
	else:
		push_error("Skeleton or sword_bone_name is not set.")
	
	print("sword_node: ", sword_node)
	print("upper_body_bone: ", upper_body_bone)
	print("animation_player: ", animation_player)
	print("skeleton: ", skeleton)
	print("sword_bone_name: ", sword_bone_name)
	print("sword_bone_idx: ", sword_bone_idx)

func _process(delta):
	if not sword_node or not upper_body_bone or not animation_player or not skeleton or sword_bone_idx == -1:
		push_error("One or more required nodes are not set. Skipping process.")
		return

	# Get the local animation transform
	var anim_transform = get_animation_transform()
	if anim_transform == null:
		push_error("Failed to get animation transform.")
		return

	# Get the current forward direction of the upper body
	var upper_body_forward = -upper_body_bone.global_transform.basis.z

	# Create a basis that aligns the sword with the upper body's forward direction
	var aligned_basis = Basis().looking_at(upper_body_forward, Vector3.UP)

	# Combine the aligned basis with the animation rotation
	var final_basis = aligned_basis * anim_transform.basis

	# Set the final transform
	sword_node.global_transform.basis = final_basis
	
	# Calculate and set the final position
	var upper_body_position = upper_body_bone.global_position
	var offset = position_offset + anim_transform.origin
	var rotated_offset = upper_body_bone.global_transform.basis * offset
	var final_position = upper_body_position + rotated_offset
	
	if debug_mode:
		print("upper_body_position: ", upper_body_position)
		print("position_offset: ", position_offset)
		print("anim_transform.origin: ", anim_transform.origin)
		print("rotated_offset: ", rotated_offset)
		print("final_position: ", final_position)
	
	global_position = final_position
	#global_rotation = upper_body_bone.global_rotation
func get_animation_transform() -> Transform3D:
	if sword_bone_idx != -1:
		return skeleton.get_bone_pose(sword_bone_idx)
	else:
		push_error("Invalid sword bone index.")
		return Transform3D.IDENTITY

func print_debug_info(anim_transform: Transform3D, final_transform: Transform3D):
	print("Animation Transform:", anim_transform)
	print("Final Transform:", final_transform)
