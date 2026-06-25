class_name Zombie
extends CharacterBody2D

enum ZombieType { NORMAL, RUNNER, TANK }

const ATTACK_RANGE: float = 45.0
const ATTACK_INTERVAL: float = 1.0

var move_speed: float = 75.0
var attack_damage: int = 10
var zombie_type: ZombieType = ZombieType.NORMAL

const GRUNT_SOUNDS: Array = [
	preload("res://assets/audio/zombie1.wav"),
	preload("res://assets/audio/zombie2.wav"),
	preload("res://assets/audio/zombie3.wav"),
]
const GRUNT_INTERVAL_MIN: float = 4.0
const GRUNT_INTERVAL_MAX: float = 8.0

var target: Node2D
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0
var _last_dir: String = "south"
var _is_hit: bool = false
var _is_attacking: bool = false
var _is_dead: bool = false

signal died

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: HealthBar = $HealthBar
@onready var grunt_player: AudioStreamPlayer2D = $GruntPlayer


func _ready() -> void:
	health.died.connect(_on_health_died)
	health.health_changed.connect(health_bar.update_health)
	nav_agent.max_speed = move_speed
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	attack_timer.wait_time = ATTACK_INTERVAL
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	_grunt_timer = randf_range(GRUNT_INTERVAL_MIN, GRUNT_INTERVAL_MAX)
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


func _update_animation() -> void:
	if _is_hit or _is_attacking or _is_dead:
		return
	if velocity.length_squared() > 1.0:
		_last_dir = _velocity_to_dir(velocity)
		_play_anim("walk_" + _last_dir)
	elif not attack_timer.is_stopped():
		_start_attack_anim()
	else:
		_play_anim("walk_" + _last_dir)


func _start_attack_anim() -> void:
	_is_attacking = true
	anim_sprite.play("attack_" + _last_dir)
	await anim_sprite.animation_finished
	if is_instance_valid(self):
		_is_attacking = false


func _play_anim(anim: String) -> void:
	if anim_sprite.animation != anim or not anim_sprite.is_playing():
		anim_sprite.play(anim)


func _velocity_to_dir(vel: Vector2) -> String:
	var deg := fposmod(rad_to_deg(vel.angle()) + 22.5, 360.0)
	match int(deg / 45.0) % 8:
		0: return "east"
		1: return "south_east"
		2: return "south"
		3: return "south_west"
		4: return "west"
		5: return "north_west"
		6: return "north"
		7: return "north_east"
	return "east"


func _physics_process(delta: float) -> void:
	_update_animation()
	if _is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
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
	if not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) <= ATTACK_RANGE:
		return
	if nav_agent.is_navigation_finished():
		return
	velocity = safe_velocity
	move_and_slide()


func take_damage(amount: int) -> void:
	health.take_damage(amount)
	_play_hit_anim()


func apply_knockback(knockback_velocity: Vector2, duration: float) -> void:
	_knockback_velocity = knockback_velocity
	_knockback_timer = duration
	attack_timer.stop()
	_play_hit_anim()


func _play_hit_anim() -> void:
	if _is_hit or _is_dead:
		return
	_is_hit = true
	anim_sprite.play("hit_" + _last_dir)
	await anim_sprite.animation_finished
	if is_instance_valid(self):
		_is_hit = false


func _on_attack_timer_timeout() -> void:
	if not is_instance_valid(target):
		attack_timer.stop()
		return
	if global_position.distance_to(target.global_position) <= ATTACK_RANGE:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)


func _on_health_died() -> void:
	_is_dead = true
	died.emit()
	set_physics_process(false)
	attack_timer.stop()
	anim_sprite.play("death_" + _last_dir)
	await anim_sprite.animation_finished
	queue_free()
