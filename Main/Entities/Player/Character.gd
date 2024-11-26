extends CharacterBody3D

class_name Character 

const SPEED = 2.0
const JUMP_VELOCITY = 4.0


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var health = 100
var max_health = 100
var stamina = 100
var max_stamina = 100
var stamina_drain_rate = 20
var stamina_regeneration_rate = 32
var stamina_grace_period = 1
var time_since_stamina_used = 0

var is_dodging = false
var is_blocking = false
var staggered = false
var attacking = false
var attack_buffer = 0
var is_attacking = 0
var time_since_engage = 0
var attack_grace = 0.1
var stunned = false
var attack_timer := 0.0
var damI := 0.0
var damI_cd := 0.08
var weaponCollidingWall = false
var currentweapon: Weapon
var weapons_in_tree
@export var offhand: Offhand
var RMPos: Vector3
var is_rolling = false
var is_running = false
var is_moving = false
var movement_lock = false
var action_bar = 0
var instaslow := false
var attackCompensation
var throwableScene = preload("res://Main/Entities/throwable.tscn")
var spearScene = preload("res://Main/Entities/Player/Weapons/spear.tscn")
var botrkScene = preload("res://Main/Entities/Player/Weapons/BladeOfTheRuinedKing.tscn")
var fistScene = preload("res://Main/Entities/Player/Weapons/fists.tscn")
var LeftHandItem : String
var RightHandItem : String
var canBeDamaged
var lock_on : bool = false
@export var curiosityFactor := 1.0
@export var object_name := "the wind"
@export var threat_level := 0.0
@export var threat_sphere : Node

func _process(_delta):
	pass

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta * 1.125
	move_and_slide()

func death():
	
	global_position = Vector3(0,1,-200)
	reset()
	
func reset():
	health = 100
	stamina = 100
	velocity = Vector3.ZERO
	attacking = false
	is_blocking = false
	stunned = false
