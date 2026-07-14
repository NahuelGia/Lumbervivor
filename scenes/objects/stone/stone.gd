class_name ChoppableStone
extends Destructible

signal mined

@onready var health_bar: HealthBar = $HealthBar


func _ready() -> void:
	super._ready()
	health.health_changed.connect(health_bar.update_health)


func _on_died() -> void:
	mined.emit()
	super._on_died()
