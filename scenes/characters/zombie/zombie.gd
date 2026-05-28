class_name Zombie
extends CharacterBody2D

enum ZombieType { NORMAL, RUNNER, TANK }

var move_speed: float = 75.0
var max_health: int = 50
var attack_damage: int = 10

var current_health: int
var target: Node2D
var zombie_type: ZombieType = ZombieType.NORMAL

signal died

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	current_health = max_health
	nav_agent.max_speed = move_speed
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	_apply_type_color()
	await get_tree().physics_frame
	if not is_instance_valid(self):
		return


func setup_type(type: ZombieType, round_number: int) -> void:
	zombie_type = type
	var scale_factor := 1.0 + 0.1 * (round_number - 1)
	match type:
		ZombieType.NORMAL:
			max_health = roundi(50 * scale_factor)
			attack_damage = roundi(10 * scale_factor)
			move_speed = 75.0
		ZombieType.RUNNER:
			max_health = roundi(35 * scale_factor)
			attack_damage = roundi(8 * scale_factor)
			move_speed = 130.0
		ZombieType.TANK:
			max_health = roundi(120 * scale_factor)
			attack_damage = roundi(20 * scale_factor)
			move_speed = 45.0
	current_health = max_health
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


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	nav_agent.target_position = target.global_position
	if nav_agent.is_navigation_finished():
		return
	var next_pos := nav_agent.get_next_path_position()
	var desired_velocity := (next_pos - global_position).normalized() * move_speed
	if nav_agent.avoidance_enabled:
		nav_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	if current_health <= 0:
		died.emit()
		queue_free()
