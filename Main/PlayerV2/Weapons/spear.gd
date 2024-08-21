extends Weapon
class_name CometSpear

@export var hurtbox: Area3D
func _ready():
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
func _process(delta):
#	print(neotgtwjs)
	#print(hitCD)
	if hitCD < hitCD_cap:
		hitCD += delta
	#print(self, owner, get_parent().owner , Hurt, neotgtwjs)
	if in_area == true and Hurt == true:
		neotgtwjs = incheck.owner
	else:
		neotgtwjs = null

	if neotgtwjs != null:
		if Hurt == false or neotgtwjs.currentweapon == self: return
		else:
			prevhit = neotgtwjs
			if hitCD >= hitCD_cap:
				prevhit.damage_by(attack_damage * attack_multiplier)
#				print("HIT! " , incheck.get_parent().get_parent().get_tree_string())
				owner.instaslow = true
				prevhit.instaslow = true
				await get_tree().create_timer(0.1).timeout
				owner.instaslow = false
				prevhit.instaslow = false
				hitCD = 0.0
			if prevhit.currentweapon != self and guard_break == true:
				prevhit.guard_break()


