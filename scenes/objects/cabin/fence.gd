class_name CabinFence
extends StaticBody2D

signal destroyed

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	health.died.connect(_on_health_died)


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func _on_health_died() -> void:
	destroyed.emit()
	queue_free()
