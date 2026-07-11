class_name ChoppableTree
extends Destructible

signal chopped

@onready var health_bar: HealthBar = $HealthBar
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	super._ready()
	health.health_changed.connect(health_bar.update_health)
	anim_sprite.play("idle")


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	_play_hit()


func _play_hit() -> void:
	anim_sprite.play("hit")
	await anim_sprite.animation_finished
	if is_instance_valid(self):
		anim_sprite.play("idle")


func _on_died() -> void:
	chopped.emit()
	super._on_died()
