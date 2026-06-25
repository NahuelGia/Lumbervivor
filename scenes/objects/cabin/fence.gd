class_name CabinFence
extends StaticBody2D

const HIT_SOUNDS: Array = [
	preload("res://assets/audio/hit_fence.wav"),
	preload("res://assets/audio/hit_fence_2.wav"),
	preload("res://assets/audio/hit_fence_3.wav"),
]

signal destroyed
signal health_changed(current: int, max_val: int)

@onready var health: HealthComponent = $HealthComponent
@onready var hit_player: AudioStreamPlayer2D = $HitPlayer


func _ready() -> void:
	health.health_changed.connect(health_changed.emit)
	health.died.connect(_on_health_died)


func take_damage(amount: int) -> void:
	health.take_damage(amount)
	hit_player.stream = HIT_SOUNDS[randi() % HIT_SOUNDS.size()]
	hit_player.play()


func repair(amount: int) -> void:
	health.repair(amount)


func _on_health_died() -> void:
	destroyed.emit()
	queue_free()
