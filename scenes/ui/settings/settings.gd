extends Control
class_name Settings

@onready var volume_slider = $PanelContainer/MarginContainer/VBoxContainer/VolumeContainer/VolumeSlider
@onready var volume_label = $PanelContainer/MarginContainer/VBoxContainer/VolumeContainer/VolumeLabel
@onready var back_button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	volume_slider.value = AudioServer.get_bus_mute(0) ? 0 : db_to_linear(AudioServer.get_bus_peak_volume_left_db(0))

	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)

	_update_volume_label()

func _on_volume_changed(value: float) -> void:
	if value == 0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear2db(value))
	_update_volume_label()

func _update_volume_label() -> void:
	var vol = volume_slider.value
	if vol == 0:
		volume_label.text = "Volumen: Silencio"
	else:
		volume_label.text = "Volumen: %d%%" % int(vol * 100)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
