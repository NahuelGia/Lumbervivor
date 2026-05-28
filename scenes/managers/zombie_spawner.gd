class_name ZombieSpawner
extends Node

const ZOMBIE_SCENE := preload("res://scenes/characters/zombie/zombie.tscn")
const ZOMBIE_SPAWN_BASE_INTERVAL: float = 8.0
const ZOMBIE_SPAWN_MIN_INTERVAL: float = 2.0
const MAX_CONCURRENT_ZOMBIES: int = 15

var active_zombies: int = 0
var zombies_spawned_this_night: int = 0
var night_zombie_quota: int = 0
var _night_ending: bool = false
var _terrain_half: Vector2

signal all_zombies_cleared

@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer

var _player: Player
var _cabin_fence: CabinFence
var _zombies_container: Node2D


func setup(p: Player, fence: CabinFence, container: Node2D, terrain_half: Vector2) -> void:
	_player = p
	_cabin_fence = fence
	_zombies_container = container
	_terrain_half = terrain_half
	zombie_spawn_timer.timeout.connect(_on_zombie_spawn_timer_timeout)


func begin_night(round: int) -> void:
	_night_ending = false
	night_zombie_quota = 10 + (round - 1) * 2
	zombies_spawned_this_night = 0
	zombie_spawn_timer.wait_time = maxf(ZOMBIE_SPAWN_MIN_INTERVAL, ZOMBIE_SPAWN_BASE_INTERVAL - (round - 1) * 0.5)
	zombie_spawn_timer.start()


func stop_spawning() -> void:
	zombie_spawn_timer.stop()
	_night_ending = true
	if not has_active_zombies():
		all_zombies_cleared.emit()


func has_active_zombies() -> bool:
	return active_zombies > 0


func _on_zombie_spawn_timer_timeout() -> void:
	if zombies_spawned_this_night >= night_zombie_quota:
		zombie_spawn_timer.stop()
		return
	if active_zombies >= MAX_CONCURRENT_ZOMBIES:
		return
	_spawn_one_zombie()


func _spawn_one_zombie() -> void:
	var zombie: Zombie = ZOMBIE_SCENE.instantiate()
	zombie.position = _random_position_on_edge()
	zombie.target = _cabin_fence if randf() < 0.7 else _player
	_zombies_container.add_child(zombie)
	zombie.died.connect(_on_zombie_died)
	active_zombies += 1
	zombies_spawned_this_night += 1


func _on_zombie_died() -> void:
	active_zombies = max(0, active_zombies - 1)
	if _night_ending and not has_active_zombies():
		all_zombies_cleared.emit()


func debug_clear_all() -> void:
	zombie_spawn_timer.stop()
	for zombie in _zombies_container.get_children():
		zombie.queue_free()
	active_zombies = 0
	_night_ending = false


func _random_position_on_edge() -> Vector2:
	match randi() % 4:
		0: return Vector2(randf_range(-_terrain_half.x, _terrain_half.x), -_terrain_half.y)
		1: return Vector2(randf_range(-_terrain_half.x, _terrain_half.x), _terrain_half.y)
		2: return Vector2(-_terrain_half.x, randf_range(-_terrain_half.y, _terrain_half.y))
		_: return Vector2(_terrain_half.x, randf_range(-_terrain_half.y, _terrain_half.y))
