extends Weapon
class_name CometSpear

@onready var playerar = get_tree().get_nodes_in_group("Player")
@onready var player: CharacterBody3D = playerar[0]
@export var hurtbox: Area3D
var neotgtwjs
var in_area := false
var incheck
func _physics_process(delta):
	#print(player)
	hitboxes = get_tree().get_nodes_in_group("hitbox")
	#print(hitboxes)

 

func _on_hurtbox_area_entered(area):

	if area.is_in_group("hitbox"):
		in_area = true
		incheck = area
func _on_hurtbox_area_exited(area):
	if area.is_in_group("hitbox"):
		in_area = false

# it has to apply these V to the characterbody3d that owns the hitboxes that spear just hit
func _process(delta):
	print(in_area)
	#print(incheck)
	if in_area == true:
		neotgtwjs = incheck.owner
		#print(incheck.get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d())
	#prinwt(Hurt)
	if neotgtwjs != null:
		if Hurt == false or neotgtwjs.currentweapon == self: return
		else:
			neotgtwjs.damage_by(10)
			
	#print("SEX MONSTER")
		#player.damage_by(10)


