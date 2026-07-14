class_name ChoppableStone
extends Destructible

const HIT_SOUNDS: Array = [
	preload("res://assets/audio/stone_hit.wav"),
	preload("res://assets/audio/stone_hit2.wav"),
	preload("res://assets/audio/stone_hit3.wav"),
]

signal mined

@onready var health_bar: HealthBar = $HealthBar
@onready var hit_player: AudioStreamPlayer2D = $HitPlayer


func _ready() -> void:
	super._ready()
	health.health_changed.connect(health_bar.update_health)


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	hit_player.stream = HIT_SOUNDS[randi() % HIT_SOUNDS.size()]
	hit_player.play()


func _on_died() -> void:
	mined.emit()
	super._on_died()
