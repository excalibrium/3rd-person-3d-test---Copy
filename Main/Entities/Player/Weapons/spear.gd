extends Weapon
class_name CometSpear

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
#@onready var rigid_body_3d: RigidBody3D = $RigidBody3D
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
@export var hit_fx : GPUParticles3D
func _ready() -> void:
	previous_global_position = global_position
	set_owner(get_parent().owner)
	my_owner = owner
 
func _on_hurtbox_area_entered(area : Area3D):
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
		#$MeshInstance3D2.visible = true
	#else:
		#$MeshInstance3D2.visible = false

	#var rid := hurtbox.get_rid()
	# Get body physics state
	#var state := PhysicsServer3D.body_get_direct_state(rid)
	


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

						boxes.owner.damage_by(attack_damage * attack_multiplier,my_owner)
						audio_stream_player_3d.play()
						hit_fx.global_position = boxes.global_position
						hit_fx.emitting = true
						#if my_owner.has_method("gave_damage"):
							#my_owner.gave_damage()
						owners_hurt.append(boxes.owner)
						hitCD = 0.0
						owner.instaslow = true
						boxes.owner.instaslow = true
						await get_tree().create_timer(0.175).timeout
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

func _on_hitbox_body_entered(body: Node3D) -> void:
	if thrown == true:
		if body.is_in_group("impalable"):
			#reparent(body, true)
			if body.has_method("damage_by"):
				damage_induced = true
				body.damage_by(attack_damage * attack_multiplier,my_owner)
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
				call_deferred("reparent", area,true)
				thrown = false
			

func restart_particles():
	$GPUParticles3D2.emitting = false
	$GPUParticles3D2.restart()
	$GPUParticles3D2.emitting = true
