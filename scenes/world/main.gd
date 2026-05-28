extends Node2D

const TREE_SCENE := preload("res://scenes/objects/tree/tree.tscn")
const ZOMBIE_SCENE := preload("res://scenes/characters/zombie/zombie.tscn")

const TERRAIN_HALF := Vector2(750.0, 450.0)
const INITIAL_TREE_COUNT: int = 15
const INITIAL_ZOMBIE_COUNT: int = 5
const ZOMBIE_SPAWN_INTERVAL: float = 8.0
const ZOMBIE_MIN_SPAWN_DISTANCE: float = 200.0

@onready var player: Player = $World/Player
@onready var trees_container: Node2D = $World/Trees
@onready var zombies_container: Node2D = $World/Zombies
@onready var nav_region: NavigationRegion2D = $World/NavigationRegion2D
@onready var hud: HUD = $UI/HUD
@onready var shop: Shop = $UI/Shop
@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer

var active_zombies: int = 0
var fence: Node2D = null  # assigned when Block C adds CabinFence


func _ready() -> void:
	_setup_navigation()
	_spawn_trees()
	_spawn_zombies(INITIAL_ZOMBIE_COUNT)
	zombie_spawn_timer.timeout.connect(_on_zombie_spawn_timer_timeout)


func _process(_delta: float) -> void:
	pass


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
	for i in INITIAL_TREE_COUNT:
		var tree: ChoppableTree = TREE_SCENE.instantiate()
		tree.position = _random_position()
		trees_container.add_child(tree)


func _spawn_zombies(count: int) -> void:
	for i in count:
		var zombie: Zombie = ZOMBIE_SCENE.instantiate()
		zombie.position = _random_position_away_from_player()
		zombie.target = fence if (fence != null and randf() < 0.7) else player
		zombies_container.add_child(zombie)
		zombie.died.connect(_on_zombie_died)
		active_zombies += 1


func _random_position() -> Vector2:
	return Vector2(
		randf_range(-TERRAIN_HALF.x, TERRAIN_HALF.x),
		randf_range(-TERRAIN_HALF.y, TERRAIN_HALF.y)
	)


func _random_position_away_from_player() -> Vector2:
	var pos: Vector2
	while true:
		pos = _random_position()
		if pos.distance_to(player.global_position) >= ZOMBIE_MIN_SPAWN_DISTANCE:
			break
	return pos


func _on_zombie_died() -> void:
	active_zombies = max(0, active_zombies - 1)


func _on_zombie_spawn_timer_timeout() -> void:
	_spawn_zombies(2)
