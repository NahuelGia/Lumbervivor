class_name Zombie
extends CharacterBody2D

@export var move_speed: float = 75.0
@export var max_health: int = 50
@export var attack_damage: int = 10

var current_health: int
var target: Node2D

signal died

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	current_health = max_health
	nav_agent.max_speed = move_speed
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	await get_tree().physics_frame


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
	current_health -= amount
	if current_health <= 0:
		died.emit()
		queue_free()
