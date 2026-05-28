class_name Player
extends CharacterBody2D

const WOOD_PER_TREE: int = 6

@export var move_speed: float = 250.0
@export var max_health: int = 100

var current_health: int
var wood: int = 0

signal health_changed(current: int, max_val: int)
signal wood_changed(amount: int)
signal died

@onready var axe: Axe = $Axe


func _ready() -> void:
	current_health = max_health
	axe.hit_zombie.connect(_on_axe_hit_zombie)
	axe.hit_tree.connect(_on_axe_hit_tree)


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_face_mouse()
	_handle_attack()
	move_and_slide()


func _handle_movement() -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed


func _face_mouse() -> void:
	look_at(get_global_mouse_position())


func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		axe.swing()


func _on_axe_hit_zombie(zombie: Zombie) -> void:
	zombie.take_damage(axe.damage)


func _on_axe_hit_tree(tree: ChoppableTree) -> void:
	if not tree.chopped.is_connected(_on_tree_chopped):
		tree.chopped.connect(_on_tree_chopped, CONNECT_ONE_SHOT)
	tree.take_damage(axe.damage)


func restore_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _on_tree_chopped() -> void:
	wood += WOOD_PER_TREE
	wood_changed.emit(wood)
