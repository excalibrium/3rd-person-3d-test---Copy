@tool
extends ReflectionProbe

@export var follow = true
@onready var player: PlayerController = $"../Player"

func _process(delta: float) -> void:
	if follow and Engine.is_editor_hint():
		global_position.x = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position.x
		global_position.z = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position.z
		global_position.y = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position.y / 1.2
		global_position.y += -EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position.y / 200.0
	if follow and not Engine.is_editor_hint():
		global_position.x = player.cam.global_position.x
		global_position.z = player.cam.global_position.z
		global_position.y = player.cam.global_position.y / 1.2
		global_position.y += -player.cam.global_position.y / 200.0
	#global_position.x = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position.x

	#EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
