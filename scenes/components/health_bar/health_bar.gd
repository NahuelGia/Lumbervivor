class_name HealthBar
extends Node2D

const BAR_WIDTH: float = 40.0
const BAR_HEIGHT: float = 5.0
const HIDE_DELAY: float = 2.0

var _ratio: float = 1.0
var _hide_timer: float = 0.0


func _ready() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_hide_timer -= delta
	if _hide_timer <= 0.0:
		visible = false


func update_health(current: int, max_val: int) -> void:
	if max_val <= 0 or current >= max_val:
		return
	_ratio = float(current) / float(max_val)
	_hide_timer = HIDE_DELAY
	visible = true
	queue_redraw()


func _draw() -> void:
	var x := -BAR_WIDTH / 2.0
	draw_rect(Rect2(x, 0.0, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
	draw_rect(Rect2(x, 0.0, BAR_WIDTH * _ratio, BAR_HEIGHT), Color(0.85, 0.15, 0.15, 1.0))
