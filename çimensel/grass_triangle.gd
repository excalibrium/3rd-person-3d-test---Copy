extends MeshInstance3D
@export var player : CharacterBody3D
var player_position
func _physics_process(delta):
	print(player_position)
	print(get_active_material(0).get("shader_parameter/player_position"))
	player_position = player.position
	get_active_material(0).set("shader_parameter/player_position", player_position + Vector3(0,0.4,0))
