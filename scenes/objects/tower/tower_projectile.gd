class_name TowerProjectile
extends Area2D

const SPEED: float = 350.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 20
var _hit_targets: Array[Node2D] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta


func _on_body_entered(body: Node2D) -> void:
	if body in _hit_targets:
		return
	_hit_targets.append(body)
	if body is Zombie:
		body.take_damage(damage)
		queue_free()
