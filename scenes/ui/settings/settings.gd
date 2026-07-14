extends Control
class_name Settings

@onready var volume_slider = $PanelContainer/MarginContainer/VBoxContainer/VolumeContainer/VolumeSlider
@onready var volume_label = $PanelContainer/MarginContainer/VBoxContainer/VolumeContainer/VolumeLabel
@onready var back_button = $PanelContainer/MarginContainer/VBoxContainer/BackButton
@onready var hud_ok_sound: AudioStreamPlayer = $HudOkSoundPlayer

func _ready() -> void:
	# Asegurar que el audio no está muteado y tiene volumen máximo
	AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_volume_db(0, 6.0)

	volume_slider.value = 1.0
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)

	_update_volume_label()

func _on_volume_changed(value: float) -> void:
	if value == 0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		# Mapear 0.0-1.0 a -40dB a +6dB para mejor rango
		var db_value = lerpf(-40.0, 6.0, value)
		AudioServer.set_bus_volume_db(0, db_value)
	_update_volume_label()

func _update_volume_label() -> void:
	var vol = volume_slider.value
	if vol == 0:
		volume_label.text = "Volumen: Silencio"
	else:
		volume_label.text = "Volumen: %d%%" % int(vol * 100)

func _on_back_pressed() -> void:
	hud_ok_sound.play()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
