class_name GameOverScreen
extends Control

@onready var reason_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ReasonLabel
@onready var restart_button: Button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var hud_ok_sound: AudioStreamPlayer = $HudOkSoundPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_game_over(reason: String) -> void:
	reason_label.text = reason
	visible = true
	get_tree().paused = true


func _on_restart_button_pressed() -> void:
	hud_ok_sound.play()
	get_tree().paused = false
	get_tree().reload_current_scene()
