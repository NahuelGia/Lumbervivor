extends Control
class_name Settings

@onready var volume_slider = $VBoxContainer/VolumeContainer/VolumeSlider
@onready var difficulty_slider = $VBoxContainer/DifficultyContainer/DifficultySlider
@onready var volume_label = $VBoxContainer/VolumeContainer/VolumeLabel
@onready var difficulty_label = $VBoxContainer/DifficultyContainer/DifficultyLabel
@onready var back_button = $VBoxContainer/BackButton

const DIFFICULTY_NAMES = ["Fácil", "Normal", "Difícil", "Pesadilla"]

func _ready() -> void:
	volume_slider.value = AudioServer.get_bus_mute(0) ? 0 : db_to_linear(AudioServer.get_bus_peak_volume_left_db(0))
	difficulty_slider.value = 1  # Default Normal

	volume_slider.value_changed.connect(_on_volume_changed)
	difficulty_slider.value_changed.connect(_on_difficulty_changed)
	back_button.pressed.connect(_on_back_pressed)

	_update_volume_label()
	_update_difficulty_label()

func _on_volume_changed(value: float) -> void:
	if value == 0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear2db(value))
	_update_volume_label()

func _on_difficulty_changed(value: float) -> void:
	_update_difficulty_label()

func _update_volume_label() -> void:
	var vol = volume_slider.value
	if vol == 0:
		volume_label.text = "Volumen: Silencio"
	else:
		volume_label.text = "Volumen: %d%%" % int(vol * 100)

func _update_difficulty_label() -> void:
	var diff = int(difficulty_slider.value)
	difficulty_label.text = "Dificultad: %s" % DIFFICULTY_NAMES[diff]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
