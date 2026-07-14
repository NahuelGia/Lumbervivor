extends Control
class_name MainMenu

@onready var play_button = $PanelContainer/MarginContainer/VBoxContainer/PlayButton
@onready var settings_button = $PanelContainer/MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button = $PanelContainer/MarginContainer/VBoxContainer/QuitButton
@onready var hud_ok_sound: AudioStreamPlayer = $HudOkSoundPlayer

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	hud_ok_sound.play()
	get_tree().change_scene_to_file("res://scenes/ui/tutorial/tutorial.tscn")

func _on_settings_pressed() -> void:
	hud_ok_sound.play()
	get_tree().change_scene_to_file("res://scenes/ui/settings/settings.tscn")

func _on_quit_pressed() -> void:
	hud_ok_sound.play()
	get_tree().quit()
