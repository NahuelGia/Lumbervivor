class_name CabinFence
extends Destructible

const HIT_SOUNDS: Array = [
	preload("res://assets/audio/hit_fence.wav"),
	preload("res://assets/audio/hit_fence_2.wav"),
	preload("res://assets/audio/hit_fence_3.wav"),
]

signal destroyed
signal health_changed(current: int, max_val: int)

@onready var hit_player: AudioStreamPlayer2D = $HitPlayer


func _ready() -> void:
	super._ready()
	health.health_changed.connect(health_changed.emit)


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	hit_player.stream = HIT_SOUNDS[randi() % HIT_SOUNDS.size()]
	hit_player.play()


func repair(amount: int) -> void:
	health.repair(amount)


func reinforce(amount: int) -> void:
	health.reinforce(amount)


func _on_died() -> void:
	destroyed.emit()
	super._on_died()
