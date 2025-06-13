extends Weapon
class_name BoTRK

var previous_global_position: Vector3
var current_velocity: Vector3

var damage_induced := false
var veldir
var owners_hurt : Array[CharacterBody3D]
var owners : Array[CharacterBody3D]
@export var hurtbox: Area3D
var inbox : Array[Area3D]
var blacklisted_boxes : Array[Area3D]
var boxes_hit : Array[Area3D]
func _ready() -> void:
	previous_global_position = global_position
	set_owner(get_parent().owner)
	my_owner = owner
 
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

func _process(_delta: float) -> void:
	current_velocity = (global_position - previous_global_position) / _delta
	
	# Store current position for next frame
	previous_global_position = global_position
	#print(current_velocity)
	if Hurt == false:
		owners_hurt.clear()
		owners.clear()
		boxes_hit.clear()
		blacklisted_boxes.clear()
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
						if boxes.owner.offhand and boxes.owner.offhand.perfect_active == false and boxes.owner.offhand.Active == true and owner.health > 0.0:
							owner.parried(boxes.owner)
							boxes_hit.erase(boxes)
							return
						elif boxes.owner.offhand and boxes.owner.offhand.perfect_active == true:
							owner.parried(boxes.owner)
							boxes_hit.erase(boxes)
							owner.instaslow = true
							boxes.owner.instaslow = true
							await get_tree().create_timer(0.5).timeout
							owner.instaslow = false
							boxes.owner.instaslow = false
							return
							
						boxes.owner.damage_by(attack_damage * attack_multiplier,my_owner)
						owners_hurt.append(boxes.owner)
						hitCD = 0.0
						owner.instaslow = true
						boxes.owner.instaslow = true
						await get_tree().create_timer(0.075).timeout
						owner.instaslow = false
						boxes.owner.instaslow = false
						boxes_hit.erase(boxes)
func _physics_process(delta):

	if hitCD < hitCD_cap:
		hitCD += delta

func _on_hitbox_body_entered(body: Node3D) -> void:
	if thrown == true:
		if body.is_in_group("impalable"):
			#reparent(body, true)
			if body.has_method("damage_by"):
				damage_induced = true
				body.damage_by(10,my_owner)
				my_owner.instaslow = true
				body.instaslow = true
				await get_tree().create_timer(0.075).timeout
				my_owner.instaslow = false
				body.instaslow = false
			thrown = false

func _on_hitbox_area_entered(area: Area3D) -> void:
	if thrown == true:
		if area.is_in_group("impalable"):
				if area.owner is CharacterBody3D and damage_induced == true:
					my_owner = owner
				reparent(area, true)
				thrown = false
