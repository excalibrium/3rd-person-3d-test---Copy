extends Weapon
class_name BoTRK

#@onready var playerar = get_tree().get_nodes_in_group("Player")
#@onready var player: CharacterBody3D = playerar[0]
@export var hurtbox: Area3D
func _ready():
	attack_damage = 5.0
	set_owner(get_parent().owner)
func _physics_process(delta):
	pass

 

func _on_hurtbox_area_entered(area):

	if area.is_in_group("hitbox"):
		in_area = true
		incheck = area
	if area.is_in_group("walls"):
		owner.weaponCollidingWall = true
func _on_hurtbox_area_exited(area):
	if area.is_in_group("hitbox"):
		in_area = false
	if area.is_in_group("walls"):
		owner.weaponCollidingWall = false
# it has to apply these V to the characterbody3d that owns the hitboxes that spear just hit
func _process(delta):
#	print(neotgtwjs)
	#print(hitCD)
	if hitCD < hitCD_cap:
		hitCD += delta
	#print(owner, Hurt, neotgtwjs)
	#print(incheck)
	if in_area == true and Hurt == true:
		neotgtwjs = incheck.owner
	else:
		neotgtwjs = null
		#print(incheck.get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d())
	#prinwt(Hurt)
	if neotgtwjs != null:
		if Hurt == false or neotgtwjs.currentweapon == self: return
		else:
			prevhit = neotgtwjs
			if hitCD >= hitCD_cap:
				if prevhit.offhand.Active == false:
					prevhit.damage_by(attack_damage * attack_multiplier)
#				print("HIT! " , incheck.get_parent().get_parent().get_tree_string())
					owner.instaslow = true
					prevhit.instaslow = true
					await get_tree().create_timer(0.1).timeout
				#owner.attack_timer -= 0.015
				#prevhit.attack_timer -= 0.015
					owner.instaslow = false
					prevhit.instaslow = false
				else:
					owner.stunned = true
					owner.attacking = false
					owner.state_machine.travel("hit_cancel")
				hitCD = 0.0
			if prevhit.currentweapon != self and guard_break == true:
				prevhit.guard_break()
		#player.damage_by(10)


