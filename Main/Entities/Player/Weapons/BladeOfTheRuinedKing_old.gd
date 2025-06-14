extends Weapon
class_name BoTRKold
var previous_global_position: Vector3
var current_velocity: Vector3
@export var hurtbox: Area3D



func _ready() -> void:
	set_owner(get_parent().owner)

 
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

func _physics_process(delta):
	current_velocity = (global_position - previous_global_position) / delta
	
	# Store current position for next frame
	previous_global_position = global_position
	print(current_velocity)
	if hitCD < hitCD_cap:
		hitCD += delta

	if in_area == true and Hurt == true:
		neotgtwjs = incheck.owner
	else:
		neotgtwjs = null

	if neotgtwjs != null:
		if Hurt == false or neotgtwjs.currentweapon == self: return
		else:
			prevhit = neotgtwjs
			if hitCD >= hitCD_cap:
				if prevhit.offhand.Active == false:
					prevhit.damage_by(attack_damage * attack_multiplier)
					
					if owner.instaslow == false:
						owner.instaslow = true
					if prevhit.instaslow == false:
						prevhit.instaslow = true
					await get_tree().create_timer(0.05).timeout
					owner.instaslow = false
					prevhit.instaslow = false
				else:
					owner.stunned = true
					owner.attacking = false
					owner.state_machine.travel("hit_cancel")
				hitCD = 0.0
			if prevhit.currentweapon != self and guard_break == true:
				prevhit.parried()
