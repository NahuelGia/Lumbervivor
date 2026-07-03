class_name PauseMenu
extends Control

@onready var volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/VolumeRow/VolumeSlider
@onready var resume_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $PanelContainer/MarginContainer/VBoxContainer/QuitButton
@onready var hud_ok_sound: AudioStreamPlayer = $HudOkSoundPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var master_bus = AudioServer.get_bus_index("Master")
	var current_db = AudioServer.get_bus_volume_db(master_bus)
	volume_slider.value = db_to_linear(current_db)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if get_tree().paused and not visible:
			return
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		_resume()
	else:
		visible = true
		get_tree().paused = true


func _resume() -> void:
	visible = false
	get_tree().paused = false


func _on_volume_slider_value_changed(value: float) -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	var volume_db = linear_to_db(value) if value > 0.0 else -80.0
	AudioServer.set_bus_volume_db(master_bus, volume_db)


func _on_resume_button_pressed() -> void:
	hud_ok_sound.play()
	_resume()


func _on_restart_button_pressed() -> void:
	hud_ok_sound.play()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	hud_ok_sound.play()
	get_tree().quit()
