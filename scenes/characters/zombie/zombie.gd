class_name Zombie
extends CharacterBody2D

@export var move_speed: float = 75.0
@export var max_health: int = 50
@export var attack_damage: int = 10

var current_health: int

signal died


func _ready() -> void:
	current_health = max_health


func _physics_process(_delta: float) -> void:
	pass


func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		died.emit()
		queue_free()
