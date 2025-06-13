extends Character
class_name Enemy

enum State { IDLE, ATTACK }
enum IdleSubstate { STANDING, ROAMING, ALERTED, SEARCHING }
enum AttackSubstate { AWAIT, FLEE, APPROACH, DEFEND, STRIKE, STALL }

const THRESHOLD_A := 1.0
const THRESHOLD_B := 3.0

var BodyDetector : PlayerDetector
var cdm_seed = 0
var decision_processing = false
var rot_lock: bool = false
var current_speed := 2.0
@export var speed := 2.0
@export var accel := 10.0
@export var alertness := 2.0
@export var adrenaline := 1.0
@export var combat_range := 12.0
@export var patience := 1.0

@export var stall_cd : float = 1.0
var stall_meter : float = 0.0
@export var looker: Node3D
var awareness_rays: Array[RayCast3D]
var empty_areas : Array[Area3D]
var common : Array[Area3D]
@export var awareness_nodes: Array[Area3D]
@export var awareness_ray: RayCast3D
@export var awareness_sphere: CollisionShape3D
@export var nav: NavigationAgent3D
@onready var posturebar := $SubViewport/PostureBar

@onready var healthbar := $SubViewport/HealthBar
@export var animationTree: AnimationTree
var state_machine
var current_anim

var consequent_attack_points : float = 1.0
var stalling : bool = false
var current_state: State = State.IDLE
var current_idle_substate: IdleSubstate = IdleSubstate.STANDING
var current_attack_substate: AttackSubstate = AttackSubstate.AWAIT
var last_alerter: Node
var last_alerter_pos: Vector3
var curious_stage := 0
var curious := 0.0
var think_timer := 0.0
var default_transform: Transform3D
var current_attack_target
var last_seen
var prio
var turn_off_pain_inhibitors := false
var safeness := 0
func main_ready() -> void:
	cdm_seed = randf()
	default_transform = global_transform
	reset_ai_state()
	weapons_in_tree = get_tree().get_nodes_in_group("weapons")
	for a in weapons_in_tree:
		if a.owner == self:
			currentweapon = a
	healthbar.init_health(health)
	actor_setup.call_deferred()

func actor_setup():
	await get_tree().physics_frame

func alert(alert_level: float, alerter: Node) -> void:
	if prio == null:
		prio = alerter
		#print(" prio was null")
	#print(alerter)
	curious = min(curious + alert_level, 100.0)
	last_alerter = alerter
	if prio.curiosityFactor <= last_alerter.curiosityFactor or current_attack_substate == AttackSubstate.AWAIT:
		prio = alerter
		print(" prio is alerter")
	if curious > THRESHOLD_A and curious < THRESHOLD_B:
		curious_stage = 1
		look_at(alerter.global_position, Vector3.UP)
	elif curious > THRESHOLD_B:
		curious_stage = 2
		#print("MY CURIOSITY IS UNSATIABLE")
		nav.target_position = prio.global_position

func unalert() -> void:
	pass

func think() -> void:
	check_awareness()
	#if prio:
		#print(global_position.distance_to(prio.global_position))
	#print("cs: ", current_state)
	#print("attackss: ", current_attack_substate)
	#print("alerted and : ", nav.target_position)
	if stunned == false and health > 0.0:
		match current_state:
			State.IDLE:
				think_idle()
			State.ATTACK:
				
				
			
				combat_decision_making()

func think_idle() -> void:
	stalling = false
	lock_on = false
	#print("idle thought")
	#print("cis: ", current_idle_substate)
	if current_idle_substate == IdleSubstate.STANDING:
		listen()
		#print("stand proud")
	if curious >= THRESHOLD_A and curious < THRESHOLD_B:
		curious_stage = 1
		current_idle_substate = IdleSubstate.ALERTED
	elif curious > THRESHOLD_B:
		curious_stage = 2
		current_idle_substate = IdleSubstate.SEARCHING

		if current_idle_substate == IdleSubstate.SEARCHING:
			unalert()
	elif curious < THRESHOLD_A:
		curious_stage = 0
		if abs(velocity) != Vector3.ZERO:
			current_idle_substate = IdleSubstate.ROAMING
		else:
			nav.target_position = default_transform.origin
			IdleSubstate.STANDING

func check_awareness() -> void:
	#print(current_attack_substate, current_state,  current_attack_target)
	#print(prio)
	var a:float = -INF
	#if BodyDetector.find_bodies():
		#curious = prio.curiosityFactor
	for ray in $Raycast.raycasts:
		last_seen = ray.get_collider()
		if last_seen is CharacterBody3D:
			if prio == null:
				prio = last_seen
				a = last_seen.curiosityFactor
			elif last_seen.curiosityFactor > a and last_seen.is_in_group("Ally"): #something something future stuff
				a = last_seen.curiosityFactor
				prio = last_seen

			if prio and prio.is_in_group("Ally"):
				safeness = 0
				current_attack_target = prio
				current_state = State.ATTACK

				if last_seen and last_seen.owner == prio:
					curious = prio.curiosityFactor
					if prio.curiosityFactor >= (THRESHOLD_A + THRESHOLD_B) / 2:
						if prio.is_in_group("Ally"):
							safeness = 0
							current_attack_target = prio
							current_state = State.ATTACK
					else:
						unalert()

func combat_decision_making() -> void:
	#if current_attack_target.current_state in ["Attack_1", "Attack_2"]:
		#current_attack_substate = AttackSubstate.DEFEND
	#print(decision_processing)
	var decision_timeout = 5.0
	if decision_processing and attack_timer > decision_timeout:
		decision_processing = false
		current_attack_substate = AttackSubstate.AWAIT
	match current_attack_substate:
		AttackSubstate.AWAIT:
			decision_processing = false
			
			if current_attack_target.threat_level > threat_level and turn_off_pain_inhibitors == false:
				lock_on = false
				current_attack_substate = AttackSubstate.FLEE
			else:
				current_attack_substate = AttackSubstate.APPROACH
		AttackSubstate.FLEE:
			flee()
			current_speed = speed * 2.0
			if find_nearest_ally() and find_nearest_ally().global_position.distance_to(global_position) < 2:
				if global_position.distance_to(current_attack_target.global_position) > 10:
					#print("im safe")
					safeness += 1
				if global_position.distance_to(current_attack_target.global_position) < 10:
					#print("must attack")
					current_attack_substate = AttackSubstate.AWAIT
					turn_off_pain_inhibitors = true
			if safeness > 5:
				#print("wew time to go back to post")
				current_state = State.IDLE
				curious = 1
		AttackSubstate.APPROACH:
			#decision_processing = false
			if decision_processing == false:
				
				stalling = false
				#movement_lock = false
			if prio and stalling == false:
				#print("indeed")
				lock_on = true
				#print("APPROACH")
				nav.target_position = current_attack_target.global_position
			if global_position.distance_to(current_attack_target.global_position) < combat_range:
				#print("far")
				current_speed = speed / 1.5
			else:
				current_speed = speed * 2.5
			if global_position.distance_to(current_attack_target.global_position) < currentweapon.length and decision_processing == false: #was 2.25 patch0.1
				#if current_attack_target.current_state in ["Attack_1", "Attack_2"]:
					#current_attack_substate = AttackSubstate.DEFEND
				#if current_attack_target.current_state in ["idle", "walk"]:
					spin("init")
				#print("close")
		AttackSubstate.STRIKE:
			movement_lock = true
			rot_lock = true
			#decision_processing = true
			
			state_machine.travel("Attack_1")
			if decision_processing == false:
				consequent_attack_points += 1.0
			decision_processing = true
			
			#current_attack_substate = AttackSubstate.APPROACH
			#print("attack")
		AttackSubstate.DEFEND:
			rot_lock = true
			movement_lock = true
			decision_processing = true
			
			state_machine.travel("block")
			#current_attack_substate = AttackSubstate.APPROACH
			#print("defend")
		AttackSubstate.STALL:
			decision_processing = false
			attacking = false
			is_blocking = false
			#print(empty_areas)
			for each in awareness_nodes:
				if each.has_overlapping_bodies():
					empty_areas.erase(each)
					continue
				else:
					#print(each, "empty?")
					empty_areas.append(each)
			if stalling == false and empty_areas.is_empty() == false:
				var a = empty_areas.pick_random()
				common = awareness_nodes.filter(func(element): return element in empty_areas)
				if common:
					nav.target_position = common.pick_random().global_position + Vector3(randf_range(-1.0 , 1.0), 0, randf_range(-1.0 , 1.0))
					stall_meter = 0.0
					stalling = true
				else:
					current_attack_substate = AttackSubstate.APPROACH
					stalling = false
			#print(empty_areas)
			empty_areas.clear()
			#if common:
				#nav.target_position = common.pick_random().global_position
			
			if nav.get_final_position() == position or stall_meter > stall_cd + cdm_seed:
				stalling = false
				current_attack_substate = AttackSubstate.APPROACH
func find_nearest_ally() -> Node:
	var alpha_group = get_tree().get_nodes_in_group("enemies")
	var nearest_ally: Node = null
	var nearest_distance: float = INF

	for ally in alpha_group:
		if ally == self:
			continue  # Skip self
		var distance = global_position.distance_to(ally.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_ally = ally

	return nearest_ally

func flee():
	var nearest_ally = find_nearest_ally()
	if nearest_ally:
		if global_position.distance_to(find_nearest_ally().global_position) < 100:
			nav.target_position = find_nearest_ally().global_position
			#print("LESSEAMUP")
		if global_position.distance_to(find_nearest_ally().global_position) >= 100:
			turn_off_pain_inhibitors = true
			current_attack_substate = AttackSubstate.APPROACH
			#print("ahhellnaw imma die...")
	else:
		#print("noone to save me imma die... ATTACK!!!!")  ES   EEEEEEEEECDCDCAQ
		turn_off_pain_inhibitors = true
		current_attack_substate = AttackSubstate.APPROACH

func push(towards, hitter):
	if towards == "left":
		velocity += global_transform.basis * Vector3(10, 0, 0)
	if towards == "right":
		velocity += global_transform.basis * Vector3(-10, 0, 0)
	if towards == "fwd":
		velocity += global_transform.basis * Vector3(0, 0, -10)
	if towards == "bwd":
		velocity += global_transform.basis * Vector3(0, 0, 10)
	if towards == "bwdplayer":
		var direction: Vector3 = global_position - hitter.global_position
		direction = direction.normalized()
		velocity += direction * 5
	return

func get_health_percentage():
	var H = max_health
	var h = health
	return int((float(h) / H) * 100)

func spin(wheel):
	if decision_processing == false:
		cdm_seed = randf()
	match wheel:
		"init":
			if cdm_seed >= 0.9 / consequent_attack_points:
				if movement_lock == false:
					current_attack_substate = AttackSubstate.STALL
					consequent_attack_points = 1.0
			elif get_health_percentage() > 50:
				return spin("above_50")
			elif get_health_percentage() <= 50:
				return spin("below_50")
		"above_50":
			if cdm_seed >= 0.3 and decision_processing == false:
				current_attack_substate = AttackSubstate.STRIKE
			if cdm_seed < 0.3 and decision_processing == false:
				current_attack_substate = AttackSubstate.DEFEND
		"below_50":
			if cdm_seed >= 0.7 and decision_processing == false:
				current_attack_substate = AttackSubstate.STRIKE
			if cdm_seed < 0.7 and decision_processing == false:
				current_attack_substate = AttackSubstate.DEFEND

func reset_ai_state():
	movement_lock = false
	stunned = false
	stalling = false
	rot_lock = false
	lock_on = false
	current_state = State.IDLE
	current_idle_substate = IdleSubstate.STANDING
	current_attack_substate = AttackSubstate.AWAIT
	last_alerter = null
	last_alerter_pos = Vector3.ZERO
	curious_stage = 0
	curious = 0.0
	think_timer = 0.0
	current_attack_target = null
	last_seen = null
	prio = null
	turn_off_pain_inhibitors = false
	safeness = 0
	decision_processing = false
	nav.target_position = default_transform.origin
	if state_machine:
		state_machine.travel("idle2")  # Or whatever your default animation is
	#print("AI state reset")

func listen():
	pass
