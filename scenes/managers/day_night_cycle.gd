class_name DayNightCycle
extends Node

enum Phase { DAY, NIGHT }

const DAY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const NIGHT_COLOR := Color(0.3, 0.3, 0.5, 1.0)
const TRANSITION_DURATION: float = 3.0
const VICTORY_DISPLAY_DURATION: float = 2.5
const DAY_DURATION: float = 90.0
const NIGHT_DURATION: float = 120.0

# Background clear color (must match project.godot default_clear_color)
const DAY_BG_COLOR := Color(0.12, 0.38, 0.12, 1.0)
# Same darkening ratio as NIGHT_COLOR applied to the canvas (×0.3 R/G, ×0.5 B)
const NIGHT_BG_COLOR := Color(0.12 * 0.3, 0.38 * 0.3, 0.12 * 0.5, 1.0)

var phase: Phase = Phase.DAY
var current_round: int = 1
var night_ending: bool = false
var _ending_night: bool = false

signal night_started(round: int)
signal night_sweep_started()
signal day_started(round: int)

@onready var day_night_timer: Timer = $DayNightTimer

var _canvas_modulate: CanvasModulate
var _victory_label: Label
var _zombie_spawner: ZombieSpawner


func setup(canvas_mod: CanvasModulate, v_label: Label, spawner: ZombieSpawner) -> void:
	_canvas_modulate = canvas_mod
	_victory_label = v_label
	_zombie_spawner = spawner
	day_night_timer.timeout.connect(_on_day_night_timer_timeout)


func notify_zombies_cleared() -> void:
	if night_ending and not _ending_night:
		night_ending = false
		_end_night()


func _on_day_night_timer_timeout() -> void:
	if phase == Phase.DAY:
		_begin_night()
	elif phase == Phase.NIGHT:
		night_ending = true
		night_sweep_started.emit()
		if not _zombie_spawner.has_active_zombies():
			night_ending = false
			if not _ending_night:
				_end_night()


func debug_skip() -> void:
	day_night_timer.stop()
	if phase == Phase.DAY:
		print("[DEBUG] Saltando a NOCHE (ronda %d)" % current_round)
		_begin_night()
	elif phase == Phase.NIGHT:
		print("[DEBUG] Saltando a DÍA (ronda %d)" % (current_round + 1))
		night_ending = false
		_zombie_spawner.debug_clear_all()
		if not _ending_night:
			_end_night()


func _set_bg_color(color: Color) -> void:
	RenderingServer.set_default_clear_color(color)


func _begin_night() -> void:
	phase = Phase.NIGHT
	day_night_timer.wait_time = NIGHT_DURATION
	day_night_timer.start()
	night_started.emit(current_round)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_canvas_modulate, "color", NIGHT_COLOR, TRANSITION_DURATION)
	tween.tween_method(_set_bg_color, DAY_BG_COLOR, NIGHT_BG_COLOR, TRANSITION_DURATION)


func _end_night() -> void:
	_ending_night = true
	day_night_timer.stop()
	_victory_label.text = "Sobreviviste la noche %d" % current_round
	_victory_label.visible = true
	await get_tree().create_timer(VICTORY_DISPLAY_DURATION).timeout
	if not is_instance_valid(self):
		return
	_ending_night = false
	_victory_label.visible = false
	phase = Phase.DAY
	current_round += 1
	day_night_timer.wait_time = DAY_DURATION
	day_night_timer.start()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_canvas_modulate, "color", DAY_COLOR, TRANSITION_DURATION)
	tween.tween_method(_set_bg_color, NIGHT_BG_COLOR, DAY_BG_COLOR, TRANSITION_DURATION)
	day_started.emit(current_round)
