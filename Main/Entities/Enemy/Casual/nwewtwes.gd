@tool
extends Node3D

@export var sword_bone: Node3D  # The animated sword bone
@export var upper_body_bone: Node3D  # The upper body bone
@export var animation_player: AnimationPlayer
@export var debug_mode: bool = false  # Toggle for debug printing

var initial_sword_local_transform: Transform3D
var initial_upper_body_global_transform: Transform3D

func _ready():
	if sword_bone and upper_body_bone:
		initial_sword_local_transform = sword_bone.transform
		initial_upper_body_global_transform = upper_body_bone.global_transform

func _process(delta):
	if not sword_bone or not upper_body_bone or not animation_player:
		return

	# Get the current animation transform of the sword
	var anim_transform = get_animation_transform()

	# Calculate the change in the upper body's global transform
	var upper_body_change = upper_body_bone.global_transform * initial_upper_body_global_transform.inverse()

	# Apply the upper body change to the sword's animated state
	var final_transform = upper_body_change * anim_transform

	# Apply the final transform
	global_transform = final_transform

	if debug_mode:
		print_debug_info(anim_transform, upper_body_change, final_transform)

func get_animation_transform() -> Transform3D:
	var current_animation = animation_player.current_animation
	var current_time = animation_player.current_animation_position

	var track_index = animation_player.get_animation(current_animation).find_track(sword_bone.get_path(), Animation.TYPE_ANIMATION)
	if track_index != -1:
		return animation_player.get_animation(current_animation).transform_track_interpolate(track_index, current_time)
	else:
		return Transform3D.IDENTITY

func print_debug_info(anim_transform: Transform3D, upper_body_change: Transform3D, final: Transform3D):
	print("Animation Transform:", anim_transform)
	print("Upper Body Change:", upper_body_change)
	print("Final Transform:", final)
	print("Global Transform:", global_transform)
