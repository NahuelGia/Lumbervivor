class_name ChoppableTree
extends StaticBody2D

signal chopped

@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: HealthBar = $HealthBar
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health.died.connect(_on_health_died)
	health.health_changed.connect(health_bar.update_health)
	anim_sprite.play("idle")


func take_damage(amount: int) -> void:
	health.take_damage(amount)
	_play_hit()


func _play_hit() -> void:
	anim_sprite.play("hit")
	await anim_sprite.animation_finished
	if is_instance_valid(self):
		anim_sprite.play("idle")


func _on_health_died() -> void:
	chopped.emit()
	queue_free()
