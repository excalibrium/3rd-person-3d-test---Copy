extends Weapon
class_name BoTRK

#@onready var playerar = get_tree().get_nodes_in_group("Player")
#@onready var player: CharacterBody3D = playerar[0]
@export var hurtbox: Area3D
var neotgtwjs
var in_area := false
var incheck
var prevhit
var hitCD := 0.0
func _ready():
	pass
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
	if hitCD < 0.3:
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
			if hitCD >= 0.3:
				prevhit.damage_by(attack_damage * attack_multiplier)
#				print("HIT! " , incheck.get_parent().get_parent().get_tree_string())
				owner.instaslow = true
				prevhit.instaslow = true
				await get_tree().create_timer(0.1).timeout
				#owner.attack_timer -= 0.015
				#prevhit.attack_timer -= 0.015
				owner.instaslow = false
				prevhit.instaslow = false
				hitCD = 0.0
			if prevhit.currentweapon != self and guard_break == true:
				prevhit.guard_break()
		#player.damage_by(10)


