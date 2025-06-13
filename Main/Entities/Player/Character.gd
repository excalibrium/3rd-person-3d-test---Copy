extends CharacterBody3D

class_name Character 

const SPEED = 2.0
const JUMP_VELOCITY = 4.0


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var health := 100.0
@export var max_health := 100.0
@export var stamina := 100.0
@export var max_stamina := 100.0
var stamina_drain_rate = 20
var stamina_regeneration_rate = 16
var stamina_grace_period = 1.5
var time_since_stamina_used = 0.0
var max_posture := 100
var posture := 100


var is_dodging = false
var is_blocking = false
var staggered = false
var attacking = false
var attack_buffer = 0
var is_attacking = 0
var time_since_engage = 60
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
var LeftHandItem : String
var RightHandItem : String
var canBeDamaged
var lock_on : bool = false
@export var curiosityFactor := 1.0
@export var object_name := "the wind"
@export var threat_level := 0.0
@export var threat_sphere : Node
@onready var weapon_scenes : Dictionary[String, PackedScene] = {
	"fistScene": preload("res://Main/Entities/Player/Weapons/fists.tscn"),
	"spearScene": preload("res://Main/Entities/Player/Weapons/spear.tscn"),
	"botrkScene": preload("res://Main/Entities/Player/Weapons/BladeOfTheRuinedKing.tscn"),
	"bombScene": preload("res://Main/Entities/Player/Weapons/bomb.tscn")
}
@onready var splatScene := preload("res://Assets/exca_splatter/splatter_node.tscn")
@onready var weapons : Dictionary[String, int] = {
	"fist": 0,
	"spear": 1,
	"botrk": 2,
	"bomb": 3
}
func _process(_delta):
	pass

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta * 1.125
	move_and_slide()

func death():
	
	global_position = Vector3(0,2,0)
	reset()
	
func reset():
	posture = 100
	health = 100
	stamina = 100
	velocity = Vector3.ZERO
	attacking = false
	is_blocking = false
	stunned = false
