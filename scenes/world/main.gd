extends Node2D

const TREE_SCENE := preload("res://scenes/objects/tree/tree.tscn")
const TERRAIN_HALF := Vector2(750.0, 450.0)
const INITIAL_TREE_COUNT: int = 15

@onready var player: Player = $World/Player
@onready var trees_container: Node2D = $World/Trees
@onready var zombies_container: Node2D = $World/Zombies
@onready var cabin_fence: CabinFence = $World/Cabin/CabinFence
@onready var canvas_modulate: CanvasModulate = $World/CanvasModulate
@onready var hud: HUD = $UI/HUD
@onready var shop: Shop = $UI/Shop
@onready var victory_label: Label = $UI/VictoryLabel
@onready var day_night_cycle: DayNightCycle = $DayNightCycle
@onready var zombie_spawner: ZombieSpawner = $ZombieSpawner


func _ready() -> void:
	_spawn_trees()
	zombie_spawner.setup(player, cabin_fence, zombies_container, TERRAIN_HALF)
	day_night_cycle.setup(canvas_modulate, victory_label, zombie_spawner)
	day_night_cycle.night_started.connect(zombie_spawner.begin_night)
	day_night_cycle.night_sweep_started.connect(zombie_spawner.stop_spawning)
	zombie_spawner.all_zombies_cleared.connect(day_night_cycle.notify_zombies_cleared)
	day_night_cycle.day_started.connect(_on_day_started)
	cabin_fence.destroyed.connect(_on_fence_destroyed)


func _on_fence_destroyed() -> void:
	get_tree().quit()


func _on_day_started(_round: int) -> void:
	player.restore_health()
	_spawn_trees()


func _spawn_trees() -> void:
	for child in trees_container.get_children():
		child.queue_free()
	for i in INITIAL_TREE_COUNT:
		var tree: ChoppableTree = TREE_SCENE.instantiate()
		tree.position = _random_position()
		trees_container.add_child(tree)


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			day_night_cycle.debug_skip()


func _random_position() -> Vector2:
	return Vector2(
		randf_range(-TERRAIN_HALF.x, TERRAIN_HALF.x),
		randf_range(-TERRAIN_HALF.y, TERRAIN_HALF.y)
	)
