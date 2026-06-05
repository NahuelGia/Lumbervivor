class_name ChoppableTree
extends StaticBody2D

signal chopped

@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: HealthBar = $HealthBar


func _ready() -> void:
	health.died.connect(_on_health_died)
	health.health_changed.connect(health_bar.update_health)


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func _on_health_died() -> void:
	chopped.emit()
	queue_free()
