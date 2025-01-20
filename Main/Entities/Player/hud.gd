extends CanvasLayer

@export var player : CharacterBody3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label2.set_text("distance to ground: "+ str(player.distance_to_ground))
	$Label3.set_text("rmpos: "+ str(player.RMPos.y))
	$Label4.set_text("is on air: "+ str(player.is_on_air)+ str(player.is_on_floor()))
	$Label5.set_text("jump time: "+ str(player.jump_time))
	$Label6.set_text("state path: "+ str(player.current_path))
	$Label7.set_text("dami cd: "+ str(player.damI_cd))
	$Label8.set_text("move: "+ str(!player.staggered and player.is_moving == true and player.attacking == false and player.is_blocking == false and player.is_running == false and player.speed < 4.8 and player.is_on_floor()))
	$Label9.set_text("current state: "+ str(player.current_state))
	$Label10.set_text("dami: "+ str(player.damI >= player.damI_cd))
