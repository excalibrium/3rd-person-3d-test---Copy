extends Weapon
class_name CometSpear

@onready var playerar = get_tree().get_nodes_in_group("Player")
@onready var player: CharacterBody3D = playerar[0]
@export var hurtbox: Area3D
func _physics_process(delta):
	print(player)
	hitboxes = get_tree().get_nodes_in_group("hitbox")
	print(hitboxes)
func _on_spear_hitbox_area_entered(area):
	return

 

func _on_spear_hurtbox_area_entered(area):
	var tgtwjs = hurtbox.get_overlapping_bodies()
	for H in hitboxes:
		print("MONSTEROUS SEXER")
		if area == H:
			for body in tgtwjs:
				if body is CharacterBody3D:
					print("current weapon:", body.currentweapon)
					if body.currentweapon == self: return
					else:
						body.damage_by(10)
			print("SEX MONSTER")
			#player.damage_by(10)
			
