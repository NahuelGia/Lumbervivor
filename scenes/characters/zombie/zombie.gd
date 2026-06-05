class_name Zombie
extends CharacterBody2D

enum ZombieType { NORMAL, RUNNER, TANK }

const ATTACK_RANGE: float = 45.0
const ATTACK_INTERVAL: float = 1.0

var move_speed: float = 75.0
var attack_damage: int = 10
var zombie_type: ZombieType = ZombieType.NORMAL

var target: Node2D
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0

signal died

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var visual: Polygon2D = $Visual
@onready var health: HealthComponent = $HealthComponent
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: HealthBar = $HealthBar


func _ready() -> void:
	health.died.connect(_on_health_died)
	health.health_changed.connect(health_bar.update_health)
	nav_agent.max_speed = move_speed
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	attack_timer.wait_time = ATTACK_INTERVAL
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	await get_tree().physics_frame
	if not is_instance_valid(self):
		return


func setup_type(type: ZombieType, round_number: int) -> void:
	zombie_type = type
	var scale_factor := 1.0 + 0.1 * (round_number - 1)
	match type:
		ZombieType.NORMAL:
			health.initialize(roundi(50 * scale_factor))
			attack_damage = roundi(10 * scale_factor)
			move_speed = 75.0
		ZombieType.RUNNER:
			health.initialize(roundi(35 * scale_factor))
			attack_damage = roundi(8 * scale_factor)
			move_speed = 130.0
		ZombieType.TANK:
			health.initialize(roundi(120 * scale_factor))
			attack_damage = roundi(20 * scale_factor)
			move_speed = 45.0
	nav_agent.max_speed = move_speed
	if is_inside_tree():
		_apply_type_color()


func _apply_type_color() -> void:
	match zombie_type:
		ZombieType.NORMAL:
			visual.color = Color("#CC3333")
		ZombieType.RUNNER:
			visual.color = Color("#DDCC00")
		ZombieType.TANK:
			visual.color = Color("#8B0000")


func _physics_process(delta: float) -> void:
	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		velocity = _knockback_velocity
		move_and_slide()
		return

	if not is_instance_valid(target):
		return

	var dist := global_position.distance_to(target.global_position)
	if dist <= ATTACK_RANGE:
		velocity = Vector2.ZERO
		move_and_slide()
		if attack_timer.is_stopped():
			attack_timer.start()
		return

	if not attack_timer.is_stopped():
		attack_timer.stop()

	nav_agent.target_position = target.global_position
	if nav_agent.is_navigation_finished():
		velocity = (target.global_position - global_position).normalized() * move_speed
		move_and_slide()
		return
	var next_pos := nav_agent.get_next_path_position()
	var desired_velocity := (next_pos - global_position).normalized() * move_speed
	if nav_agent.avoidance_enabled:
		nav_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if _knockback_timer > 0.0:
		return
	velocity = safe_velocity
	move_and_slide()


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func apply_knockback(knockback_velocity: Vector2, duration: float) -> void:
	_knockback_velocity = knockback_velocity
	_knockback_timer = duration
	attack_timer.stop()


func _on_attack_timer_timeout() -> void:
	if not is_instance_valid(target):
		attack_timer.stop()
		return
	if global_position.distance_to(target.global_position) <= ATTACK_RANGE:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)


func _on_health_died() -> void:
	died.emit()
	queue_free()
