class_name Destructible
extends StaticBody2D

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	health.died.connect(_on_died)


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func _on_died() -> void:
	queue_free()
