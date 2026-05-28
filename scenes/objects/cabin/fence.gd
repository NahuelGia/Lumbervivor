class_name CabinFence
extends StaticBody2D

@export var max_health: int = 200

var current_health: int

signal destroyed


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	if current_health <= 0:
		destroyed.emit()
		queue_free()
