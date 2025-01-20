@tool
class_name CustomModifierTest
extends SkeletonModifier3D

enum Mode {
	ADD_TRANSFORM,
	REPLACE_TRANSFORM,
	REPLACE_POSITION,
	REPLACE_ROTATION
}

@export var skewer: Node3D
@export var bone: String
@export var mode: Mode = Mode.ADD_TRANSFORM

func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if !skeleton:
		return

	var bone_idx: int = skeleton.find_bone(bone)
	var original_pose: Transform3D = skeleton.get_bone_global_pose(bone_idx)
	
	var final_transform: Transform3D
	
	match mode:
		Mode.ADD_TRANSFORM:
			final_transform = original_pose * skewer.transform
		Mode.REPLACE_TRANSFORM:
			final_transform = skewer.transform
		Mode.REPLACE_POSITION:
			final_transform = Transform3D(original_pose.basis, skewer.global_position)
		Mode.REPLACE_ROTATION:
			final_transform = Transform3D(skewer.global_transform.basis, original_pose.origin)
	
	skeleton.set_bone_global_pose(bone_idx, final_transform)
