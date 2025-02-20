extends Node
@export var player : CharacterBody3D
var counter := 0.0
var spawn_limit := 15.0
var casene
var current_spawned := 0.0
var spawn_count_limit := 10.0
var scene = preload("res://Main/Entities/Enemy/Casual/casual_enemy.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_nodes_in_group("Player")[0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_spawned = get_tree().get_nodes_in_group("enemies").size()
	counter += delta
	if counter >= spawn_limit / player.killed and current_spawned < spawn_count_limit:
		spawn_casual()
		counter = 0.0
func _input(event):
	if Input.is_action_pressed("F"):
		spawn_casual()

func spawn_casual():
	
	casene = scene.instantiate()
	add_child(casene)
	casene.cdm_seed = 0.10379016399384
	casene.decision_processing = false
	casene.rot_lock = false
	casene.speed = 1.33333333333333
	casene.accel = 10.0
	casene.alertness = 2.0
	casene.adrenaline = 1.0
	casene.combat_range = 12.0
	casene.patience = 1.0
	casene.stall_meter = 1.0
	casene.stalling = false
	casene.current_state = 1
	casene.current_idle_substate = 1
	casene.current_attack_substate = 2


	casene.curious_stage = 0
	casene.curious = 0.07
	casene.current_attack_target = player
	casene.last_seen = null
	casene.prio = player
	casene.turn_off_pain_inhibitors = false
	casene.safeness = 0.0

	player.enemies.append(casene)
