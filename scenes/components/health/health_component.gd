class_name HealthComponent
extends Node

@export var max_health: int = 100
var current_health: int

signal health_changed(current: int, max_val: int)
signal died


func _ready() -> void:
	current_health = max_health


func initialize(p_max: int) -> void:
	max_health = p_max
	current_health = p_max
	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()


func restore() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
