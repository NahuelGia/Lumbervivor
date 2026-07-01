extends Node2D

const TREE_SCENE := preload("res://scenes/objects/tree/tree.tscn")
const TERRAIN_HALF := Vector2(750.0, 450.0)
const INITIAL_TREE_COUNT: int = 15

@onready var player: Player = %Player
@onready var trees_container: Node2D = %Trees
@onready var zombies_container: Node2D = %Zombies
@onready var cabin_fence: CabinFence = $World/Cabin/CabinFence
@onready var bench_marker: Node2D = $World/Cabin/CraftingBenchMarker
@onready var canvas_modulate: CanvasModulate = $World/CanvasModulate
@onready var hud: HUD = $UI/HUD
@onready var crafting_bench: CraftingBench = $UI/CraftingBench
@onready var game_over_screen: GameOverScreen = $UI/GameOverScreen
@onready var victory_screen: VictoryScreen = $UI/VictoryScreen
@onready var victory_label: Label = $UI/VictoryLabel
@onready var day_night_cycle: DayNightCycle = $DayNightCycle
@onready var zombie_spawner: ZombieSpawner = $ZombieSpawner



func _ready() -> void:
	_spawn_trees()
	zombie_spawner.setup(player, cabin_fence, zombies_container, TERRAIN_HALF)
	day_night_cycle.setup(canvas_modulate, victory_label, zombie_spawner, hud)
	crafting_bench.setup(player, cabin_fence, bench_marker)

	# Señales de ciclo día/noche
	day_night_cycle.night_started.connect(zombie_spawner.begin_night)
	day_night_cycle.night_sweep_started.connect(zombie_spawner.stop_spawning)
	zombie_spawner.all_zombies_cleared.connect(day_night_cycle.notify_zombies_cleared)
	day_night_cycle.day_started.connect(_on_day_started)

	# HUD
	player.health_changed.connect(hud.update_health)
	player.wood_changed.connect(hud.update_wood)
	cabin_fence.health_changed.connect(hud.update_fence)
	day_night_cycle.day_started.connect(hud.on_day_started)
	day_night_cycle.night_started.connect(hud.on_night_started)

	# CraftingBench: habilitar de día, deshabilitar de noche
	day_night_cycle.day_started.connect(crafting_bench.enable)
	day_night_cycle.night_started.connect(crafting_bench.disable)

	# Game Over
	cabin_fence.destroyed.connect(_on_fence_destroyed)
	player.died.connect(_on_player_died)

	# Inicializar HUD y bench con valores actuales
	hud.update_health(player.health.current_health, player.health.max_health)
	hud.update_wood(player.wood)
	hud.update_fence(cabin_fence.health.current_health, cabin_fence.health.max_health)
	hud.on_day_started(day_night_cycle.current_round)
	crafting_bench.enable(day_night_cycle.current_round)


func _on_fence_destroyed() -> void:
	crafting_bench.disable(0)
	game_over_screen.show_game_over("La reja de la cabaña fue destruida.")


func _on_player_died() -> void:
	crafting_bench.disable(0)
	game_over_screen.show_game_over("El leñador no sobrevivió.")


const WIN_ROUNDS: int = 5

func _on_day_started(round: int) -> void:
	if round > WIN_ROUNDS:
		victory_screen.show_victory()
		return
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
