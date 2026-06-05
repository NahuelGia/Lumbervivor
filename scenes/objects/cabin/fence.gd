class_name CabinFence
extends StaticBody2D

signal destroyed
signal health_changed(current: int, max_val: int)

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	health.health_changed.connect(health_changed.emit)
	health.died.connect(_on_health_died)


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func repair(amount: int) -> void:
	health.repair(amount)


func _on_health_died() -> void:
	destroyed.emit()
	queue_free()
