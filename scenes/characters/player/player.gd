class_name Player
extends CharacterBody2D

const WOOD_PER_TREE: int = 6
const PUSH_FORCE: float = 500.0
const PUSH_DURATION: float = 0.3

@export var move_speed: float = 250.0

var wood: int = 0

signal wood_changed(amount: int)
signal health_changed(current: int, max_val: int)
signal died

@onready var axe: Axe = $Axe
@onready var health: HealthComponent = $HealthComponent
@onready var push_area: Area2D = $PushArea


func _ready() -> void:
	health.health_changed.connect(health_changed.emit)
	health.died.connect(died.emit)
	health_changed.emit(health.current_health, health.max_health)
	axe.hit_zombie.connect(_on_axe_hit_zombie)
	axe.hit_tree.connect(_on_axe_hit_tree)


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_face_mouse()
	_handle_attack()
	_handle_push()
	move_and_slide()


func _handle_movement() -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed


func _face_mouse() -> void:
	look_at(get_global_mouse_position())


func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		axe.swing()


func _handle_push() -> void:
	if not Input.is_action_just_pressed("push"):
		return
	for body in push_area.get_overlapping_bodies():
		if body is Zombie:
			var dir := body.global_position - global_position
			if dir.is_zero_approx():
				dir = Vector2.RIGHT
			else:
				dir = dir.normalized()
			body.apply_knockback(dir * PUSH_FORCE, PUSH_DURATION)


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func restore_health() -> void:
	health.restore()


func _on_axe_hit_zombie(zombie: Zombie) -> void:
	zombie.take_damage(axe.damage)


func _on_axe_hit_tree(tree: ChoppableTree) -> void:
	if not tree.chopped.is_connected(_on_tree_chopped):
		tree.chopped.connect(_on_tree_chopped, CONNECT_ONE_SHOT)
	tree.take_damage(axe.damage)


func _on_tree_chopped() -> void:
	wood += WOOD_PER_TREE
	wood_changed.emit(wood)
