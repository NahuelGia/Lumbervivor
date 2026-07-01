class_name HUD
extends Control

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var wood_label: Label = $MarginContainer/VBoxContainer/WoodLabel
@onready var round_label: Label = $MarginContainer/VBoxContainer/RoundLabel
@onready var phase_label: Label = $MarginContainer/VBoxContainer/PhaseLabel
@onready var fence_label: Label = $MarginContainer/VBoxContainer/FenceLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TimerLabel


func update_health(current: int, max_val: int) -> void:
	health_label.text = "Vida: %d / %d" % [current, max_val]


func update_wood(amount: int) -> void:
	wood_label.text = "Madera: %d" % amount


func update_fence(current: int, max_val: int) -> void:
	fence_label.text = "Reja: %d / %d" % [current, max_val]


func on_day_started(round: int) -> void:
	round_label.text = "Ronda: %d" % round
	phase_label.text = "Fase: DÍA"


func on_night_started(round: int) -> void:
	round_label.text = "Ronda: %d" % round
	phase_label.text = "Fase: NOCHE"


func update_timer(seconds_left: float) -> void:
	var minutes := int(seconds_left) / 60
	var seconds := int(seconds_left) % 60
	timer_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]
