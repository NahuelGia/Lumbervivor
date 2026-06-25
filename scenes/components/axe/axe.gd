class_name Axe
extends Area2D

signal hit_zombie(zombie: Zombie)
signal hit_zombie_push(zombie: Zombie)
signal hit_tree(tree: ChoppableTree)

@export var damage: int = 20
@export var swing_duration: float = 0.25
@export var attack_cooldown: float = 0.5

var _is_on_cooldown: bool = false
var _is_push_mode: bool = false
var _hit_targets: Array[Node2D] = []


func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)


func can_swing() -> bool:
	return not _is_on_cooldown


func swing() -> void:
	if _is_on_cooldown:
		return
	_is_on_cooldown = true
	_hit_targets.clear()
	_play_swing_animation()
	if _is_push_mode:
		await get_tree().create_timer(0.2).timeout
	monitoring = true
	await get_tree().create_timer(swing_duration).timeout
	monitoring = false
	await get_tree().create_timer(attack_cooldown - swing_duration).timeout
	_is_on_cooldown = false


func push_swing() -> void:
	if _is_on_cooldown:
		return
	_is_push_mode = true
	await swing()
	if not is_instance_valid(self):
		return
	_is_push_mode = false


func _play_swing_animation() -> void:
	rotation_degrees = 50.0
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", -50.0, swing_duration)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.1)


func _on_body_entered(body: Node2D) -> void:
	if body in _hit_targets:
		return
	_hit_targets.append(body)
	if body is Zombie:
		if _is_push_mode:
			hit_zombie_push.emit(body)
		else:
			hit_zombie.emit(body)
	elif body is ChoppableTree and not _is_push_mode:
		hit_tree.emit(body)
