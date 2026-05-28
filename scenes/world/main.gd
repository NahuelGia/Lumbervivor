extends Node2D

const TREE_SCENE := preload("res://scenes/objects/tree/tree.tscn")
const ZOMBIE_SCENE := preload("res://scenes/characters/zombie/zombie.tscn")

const TERRAIN_HALF := Vector2(750.0, 450.0)
const INITIAL_TREE_COUNT: int = 15
const ZOMBIE_SPAWN_BASE_INTERVAL: float = 8.0
const ZOMBIE_SPAWN_MIN_INTERVAL: float = 2.0
const DAY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const NIGHT_COLOR := Color(0.3, 0.3, 0.5, 1.0)
const TRANSITION_DURATION: float = 3.0
const VICTORY_DISPLAY_DURATION: float = 2.5

@onready var player: Player = $World/Player
@onready var trees_container: Node2D = $World/Trees
@onready var zombies_container: Node2D = $World/Zombies
@onready var cabin_fence: CabinFence = $World/Cabin/CabinFence
@onready var nav_region: NavigationRegion2D = $World/NavigationRegion2D
@onready var hud: HUD = $UI/HUD
@onready var shop: Shop = $UI/Shop
@onready var canvas_modulate: CanvasModulate = $World/CanvasModulate
@onready var day_night_timer: Timer = $DayNightTimer
@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer
@onready var victory_label: Label = $UI/VictoryLabel

enum Phase { DAY, NIGHT }

var phase: Phase = Phase.DAY
var current_round: int = 1
var active_zombies: int = 0
var night_ending: bool = false
var zombies_spawned_this_night: int = 0
var night_zombie_quota: int = 0


func _ready() -> void:
	_setup_navigation()
	_spawn_trees()
	day_night_timer.timeout.connect(_on_day_night_timer_timeout)
	zombie_spawn_timer.timeout.connect(_on_zombie_spawn_timer_timeout)
	cabin_fence.destroyed.connect(_on_fence_destroyed)


func _on_fence_destroyed() -> void:
	get_tree().quit()


func _setup_navigation() -> void:
	var nav_poly := NavigationPolygon.new()
	var verts := PackedVector2Array([
		Vector2(-TERRAIN_HALF.x, -TERRAIN_HALF.y),
		Vector2(TERRAIN_HALF.x, -TERRAIN_HALF.y),
		Vector2(TERRAIN_HALF.x, TERRAIN_HALF.y),
		Vector2(-TERRAIN_HALF.x, TERRAIN_HALF.y)
	])
	nav_poly.vertices = verts
	nav_poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	nav_region.navigation_polygon = nav_poly


func _spawn_trees() -> void:
	for child in trees_container.get_children():
		child.queue_free()
	for i in INITIAL_TREE_COUNT:
		var tree: ChoppableTree = TREE_SCENE.instantiate()
		tree.position = _random_position()
		trees_container.add_child(tree)


func _random_position() -> Vector2:
	return Vector2(
		randf_range(-TERRAIN_HALF.x, TERRAIN_HALF.x),
		randf_range(-TERRAIN_HALF.y, TERRAIN_HALF.y)
	)


func _random_position_on_edge() -> Vector2:
	match randi() % 4:
		0: return Vector2(randf_range(-TERRAIN_HALF.x, TERRAIN_HALF.x), -TERRAIN_HALF.y)
		1: return Vector2(randf_range(-TERRAIN_HALF.x, TERRAIN_HALF.x), TERRAIN_HALF.y)
		2: return Vector2(-TERRAIN_HALF.x, randf_range(-TERRAIN_HALF.y, TERRAIN_HALF.y))
		_: return Vector2(TERRAIN_HALF.x, randf_range(-TERRAIN_HALF.y, TERRAIN_HALF.y))


func _on_day_night_timer_timeout() -> void:
	if phase == Phase.DAY:
		_start_night()
	elif phase == Phase.NIGHT:
		zombie_spawn_timer.stop()
		night_ending = true
		if active_zombies == 0:
			night_ending = false
			_end_night()


func _start_night() -> void:
	phase = Phase.NIGHT
	night_zombie_quota = 10 + (current_round - 1) * 2
	zombies_spawned_this_night = 0
	zombie_spawn_timer.wait_time = maxf(ZOMBIE_SPAWN_MIN_INTERVAL, ZOMBIE_SPAWN_BASE_INTERVAL - (current_round - 1) * 0.5)
	zombie_spawn_timer.start()
	day_night_timer.start()
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", NIGHT_COLOR, TRANSITION_DURATION)


func _on_zombie_spawn_timer_timeout() -> void:
	if zombies_spawned_this_night >= night_zombie_quota:
		zombie_spawn_timer.stop()
		return
	if active_zombies >= 15:
		return
	_spawn_one_zombie()


func _spawn_one_zombie() -> void:
	var zombie: Zombie = ZOMBIE_SCENE.instantiate()
	zombie.position = _random_position_on_edge()
	zombie.target = cabin_fence if randf() < 0.7 else player
	zombies_container.add_child(zombie)
	zombie.died.connect(_on_zombie_died)
	active_zombies += 1
	zombies_spawned_this_night += 1


func _on_zombie_died() -> void:
	active_zombies = max(0, active_zombies - 1)
	if night_ending and active_zombies == 0:
		night_ending = false
		_end_night()


func _end_night() -> void:
	victory_label.text = "Sobreviviste la noche %d" % current_round
	victory_label.visible = true
	await get_tree().create_timer(VICTORY_DISPLAY_DURATION).timeout
	victory_label.visible = false
	_start_day()


func _start_day() -> void:
	phase = Phase.DAY
	current_round += 1
	player.restore_health()
	_spawn_trees()
	day_night_timer.start()
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", DAY_COLOR, TRANSITION_DURATION)


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_debug_skip_phase()


func _debug_skip_phase() -> void:
	day_night_timer.stop()
	if phase == Phase.DAY:
		print("[DEBUG] Saltando a NOCHE (ronda %d)" % current_round)
		_start_night()
	elif phase == Phase.NIGHT:
		print("[DEBUG] Saltando a DÍA (ronda %d)" % (current_round + 1))
		zombie_spawn_timer.stop()
		for zombie in zombies_container.get_children():
			zombie.queue_free()
		active_zombies = 0
		night_ending = false
		_end_night()
