class_name ChoppableTree
extends StaticBody2D

const WOOD_AMOUNT: int = 6

@export var max_health: int = 30

var current_health: int

signal chopped


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		chopped.emit()
		queue_free()
