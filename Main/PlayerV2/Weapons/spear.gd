extends Weapon
class_name CometSpear

@onready var playerar = get_tree().get_nodes_in_group("Player")
@onready var player: CharacterBody3D = playerar[0]
@export var hurtbox: Area3D
func _physics_process(delta):
	#print(player)
	hitboxes = get_tree().get_nodes_in_group("hitbox")
	#print(hitboxes)
func _on_spear_hitbox_area_entered(area):
	return

 

func _on_spear_hurtbox_area_entered(area):
	var tgtwjs = hurtbox.get_overlapping_bodies() #no need
	for H in hitboxes:
		#print("MONSTEROUS SEXER")
		#print(H)
		if area == H:
			var neotgtwjs = area.get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d()

# it has to apply these V to the characterbody3d that owns the hitboxes that spear just hit
			print("current weapon:", neotgtwjs.currentweapon)
			if neotgtwjs.currentweapon == self: return
			else:
				neotgtwjs.damage_by(10)
			#print("SEX MONSTER")
			#player.damage_by(10)
			
