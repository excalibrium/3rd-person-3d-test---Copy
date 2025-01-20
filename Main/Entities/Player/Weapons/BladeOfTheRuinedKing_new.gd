extends Weapon
class_name BoTRK

var damage_induced := false
var veldir
var owners_hurt : Array[CharacterBody3D]
var owners : Array[CharacterBody3D]
@export var hurtbox: Area3D
var inbox : Array[Area3D]
var blacklisted_boxes : Array[Area3D]
var boxes_hit : Array[Area3D]
func _ready() -> void:
	set_owner(get_parent().owner)

 
func _on_hurtbox_area_entered(area):
	if area.is_in_group("hitbox"):
		in_area = true
		inbox.append(area)
	if area.is_in_group("walls") and owner is CharacterBody3D:
		owner.weaponCollidingWall = true
func _on_hurtbox_area_exited(area):
	if area.is_in_group("hitbox"):
		in_area = false
		inbox.erase(area)
		boxes_hit.erase(area)
	if area.is_in_group("walls") and owner is CharacterBody3D:
		owner.weaponCollidingWall = false

func _process(delta: float) -> void:
	if in_area == true:
		if Hurt == true:
			for each_box in inbox:
				if boxes_hit.has(each_box) == false and blacklisted_boxes.has(each_box) == false:
					boxes_hit.append(each_box)
			if hitCD >= hitCD_cap:
				for boxes in boxes_hit:
					if owners_hurt.has(boxes.owner) == false and owners.has(boxes.owner) == false and boxes.owner.currentweapon != self:
						if boxes.owner != self.owner:
							owners.append(boxes.owner)

						boxes.owner.damage_by(attack_damage * attack_multiplier)
						owners_hurt.append(boxes.owner)
						hitCD = 0.0
						owner.instaslow = true
						boxes.owner.instaslow = true
						await get_tree().create_timer(0.075).timeout
						owner.instaslow = false
						boxes.owner.instaslow = false
						boxes_hit.erase(boxes)
	if Hurt == false:
		owners_hurt.clear()
		owners.clear()
		boxes_hit.clear()
		blacklisted_boxes.clear()
func _physics_process(delta):

	if hitCD < hitCD_cap:
		hitCD += delta

	#if in_area == true and Hurt == true:
		#neotgtwjs = incheck.owner
	#else:
		#neotgtwjs = null

	#if neotgtwjs != null:
		#if Hurt == false or neotgtwjs.currentweapon == self: return
		#else:
			#prevhit = neotgtwjs
			#if hitCD >= hitCD_cap:
				#if prevhit.offhand.Active == false:
					#prevhit.damage_by(attack_damage * attack_multiplier)
					#owner.instaslow = true
					#prevhit.instaslow = true
					#await get_tree().create_timer(0.1).timeout
					#owner.instaslow = false
					#prevhit.instaslow = false
				#else:
					#owner.stunned = true
					#owner.attacking = false
					#owner.state_machine.travel("hit_cancel")
				#hitCD = 0.0
			#if prevhit.currentweapon != self and guard_break == true:
				#prevhit.guard_break()
