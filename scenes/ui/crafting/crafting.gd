class_name CraftingBench
extends Control

const COST_AXE: int = 100
const COST_ARMOR: int = 50
const COST_BARRICADE: int = 30
const COST_TOWER_WOOD: int = 70
const COST_TOWER_STONE: int = 120
const COST_STONE_AXE: int = 140
const COST_STONE_ARMOR: int = 60
const COST_STONE_FENCE: int = 150
const BENCH_PROXIMITY: float = 160.0

var _player: Player
var _fence: CabinFence
var _bench_marker: StaticBody2D
var _tower: Tower
var _is_day: bool = true
var _bench_paused: bool = false
var _axe_bought: bool = false
var _armor_bought: bool = false
var _barricade_bought: bool = false
var _tower_bought: bool = false
var _stone_axe_bought: bool = false
var _stone_armor_bought: bool = false
var _stone_fence_bought: bool = false
var _debug_free_upgrades: bool = false

@onready var axe_button: Button = $PanelContainer/MarginContainer/VBoxContainer/AxeButton
@onready var armor_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ArmorButton
@onready var barricade_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BarricadeButton
@onready var tower_button: Button = $PanelContainer/MarginContainer/VBoxContainer/TowerButton
@onready var stone_axe_button: Button = $PanelContainer/MarginContainer/VBoxContainer/StoneAxeButton
@onready var stone_armor_button: Button = $PanelContainer/MarginContainer/VBoxContainer/StoneArmorButton
@onready var stone_fence_button: Button = $PanelContainer/MarginContainer/VBoxContainer/StoneFenceButton
@onready var hud_ok_sound: AudioStreamPlayer = $HudOkSoundPlayer

signal tower_purchased


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	axe_button.process_mode = Node.PROCESS_MODE_ALWAYS
	armor_button.process_mode = Node.PROCESS_MODE_ALWAYS
	barricade_button.process_mode = Node.PROCESS_MODE_ALWAYS
	tower_button.process_mode = Node.PROCESS_MODE_ALWAYS
	stone_axe_button.process_mode = Node.PROCESS_MODE_ALWAYS
	stone_armor_button.process_mode = Node.PROCESS_MODE_ALWAYS
	stone_fence_button.process_mode = Node.PROCESS_MODE_ALWAYS


func setup(player: Player, fence: CabinFence, bench_marker: StaticBody2D, tower: Tower) -> void:
	_player = player
	_fence = fence
	_bench_marker = bench_marker
	_tower = tower
	player.wood_changed.connect(_on_resource_changed)
	player.stone_changed.connect(_on_resource_changed)


func enable(_round: int) -> void:
	_is_day = true


func disable(_round: int) -> void:
	_is_day = false
	if visible:
		_close()
	else:
		visible = false


func _near_bench() -> bool:
	if is_instance_valid(_bench_marker):
		return _player.global_position.distance_to(_bench_marker.global_position) <= BENCH_PROXIMITY
	return is_instance_valid(_fence) and \
		_player.global_position.distance_to(_fence.global_position) <= BENCH_PROXIMITY


func _unhandled_key_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_F9:
		_debug_free_upgrades = not _debug_free_upgrades
		print("[DEBUG] Mejoras gratis: ", _debug_free_upgrades)
		if visible:
			_update_buttons()
	if event.is_action_pressed("open_bench") and _is_day:
		if visible:
			_close()
		elif _near_bench():
			_open()


func _open() -> void:
	hud_ok_sound.play()
	visible = true
	_bench_paused = true
	get_tree().paused = true
	_update_buttons()


func _close() -> void:
	hud_ok_sound.play()
	visible = false
	if _bench_paused:
		_bench_paused = false
		get_tree().paused = false


func _on_resource_changed(_amount: int) -> void:
	if visible:
		_update_buttons()


func _update_buttons() -> void:
	var axe_suffix := "  [COMPRADO]" if _axe_bought else "  —  %d madera" % COST_AXE
	axe_button.text = "Hacha mejorada  +15 daño" + axe_suffix
	axe_button.disabled = _axe_bought or not (_debug_free_upgrades or _player.wood >= COST_AXE)

	stone_axe_button.visible = _axe_bought
	if _axe_bought:
		var stone_axe_suffix := "  [COMPRADO]" if _stone_axe_bought else "  —  %d piedra" % COST_STONE_AXE
		stone_axe_button.text = "Hacha de piedra  +20 daño" + stone_axe_suffix
		stone_axe_button.disabled = _stone_axe_bought or not (_debug_free_upgrades or _player.stone >= COST_STONE_AXE)

	var armor_suffix := "  [COMPRADO]" if _armor_bought else "  —  %d madera" % COST_ARMOR
	armor_button.text = "Armadura de madera  +30 HP máx." + armor_suffix
	armor_button.disabled = _armor_bought or not (_debug_free_upgrades or _player.wood >= COST_ARMOR)

	stone_armor_button.visible = _armor_bought
	if _armor_bought:
		var stone_armor_suffix := "  [COMPRADO]" if _stone_armor_bought else "  —  %d piedra" % COST_STONE_ARMOR
		stone_armor_button.text = "Armadura de piedra  +40 HP máx." + stone_armor_suffix
		stone_armor_button.disabled = _stone_armor_bought or not (_debug_free_upgrades or _player.stone >= COST_STONE_ARMOR)

	var barricade_suffix := "  [COMPRADO]" if _barricade_bought else "  —  %d madera" % COST_BARRICADE
	barricade_button.text = "Barricada de madera  +100 HP reja" + barricade_suffix
	barricade_button.disabled = _barricade_bought or not (_debug_free_upgrades or _player.wood >= COST_BARRICADE)

	stone_fence_button.visible = _barricade_bought
	if _barricade_bought:
		var stone_fence_suffix := "  [COMPRADO]" if _stone_fence_bought else "  —  %d piedra" % COST_STONE_FENCE
		stone_fence_button.text = "Refuerzo de piedra  +100 HP máx. reja" + stone_fence_suffix
		stone_fence_button.disabled = _stone_fence_bought or not (_debug_free_upgrades or _player.stone >= COST_STONE_FENCE)

	var tower_suffix := "  [COMPRADO]" if _tower_bought else "  —  %d madera / %d piedra" % [COST_TOWER_WOOD, COST_TOWER_STONE]
	tower_button.text = "Torreta  Dispara a zombies" + tower_suffix
	tower_button.disabled = _tower_bought or not (_debug_free_upgrades or \
		(_player.wood >= COST_TOWER_WOOD and _player.stone >= COST_TOWER_STONE))


func _try_spend_wood(amount: int) -> bool:
	if _debug_free_upgrades:
		return true
	return _player.spend_wood(amount)


func _try_spend_stone(amount: int) -> bool:
	if _debug_free_upgrades:
		return true
	return _player.spend_stone(amount)


func _try_spend_mixed(wood_amount: int, stone_amount: int) -> bool:
	if _debug_free_upgrades:
		return true
	if _player.wood < wood_amount or _player.stone < stone_amount:
		return false
	_player.spend_wood(wood_amount)
	_player.spend_stone(stone_amount)
	return true


func _on_axe_button_pressed() -> void:
	hud_ok_sound.play()
	if _axe_bought or not _try_spend_wood(COST_AXE):
		return
	_player.upgrade_axe(15)
	_axe_bought = true
	_update_buttons()


func _on_stone_axe_button_pressed() -> void:
	hud_ok_sound.play()
	if not _axe_bought or _stone_axe_bought or not _try_spend_stone(COST_STONE_AXE):
		return
	_player.upgrade_axe(20)
	_stone_axe_bought = true
	_update_buttons()


func _on_armor_button_pressed() -> void:
	hud_ok_sound.play()
	if _armor_bought or not _try_spend_wood(COST_ARMOR):
		return
	_player.upgrade_armor(30)
	_armor_bought = true
	_update_buttons()


func _on_stone_armor_button_pressed() -> void:
	hud_ok_sound.play()
	if not _armor_bought or _stone_armor_bought or not _try_spend_stone(COST_STONE_ARMOR):
		return
	_player.upgrade_armor(40)
	_stone_armor_bought = true
	_update_buttons()


func _on_barricade_button_pressed() -> void:
	hud_ok_sound.play()
	if _barricade_bought or not _try_spend_wood(COST_BARRICADE):
		return
	if not is_instance_valid(_fence):
		return
	_fence.repair(100)
	_barricade_bought = true
	_update_buttons()


func _on_stone_fence_button_pressed() -> void:
	hud_ok_sound.play()
	if not _barricade_bought or _stone_fence_bought or not _try_spend_stone(COST_STONE_FENCE):
		return
	if not is_instance_valid(_fence):
		return
	_fence.reinforce(100)
	_stone_fence_bought = true
	_update_buttons()


func _on_tower_button_pressed() -> void:
	hud_ok_sound.play()
	if _tower_bought or not _try_spend_mixed(COST_TOWER_WOOD, COST_TOWER_STONE):
		return
	_tower_bought = true
	if is_instance_valid(_tower):
		_tower.visible = true
		_tower._update_collision_state()
		_tower.setup_obstacle()
	_update_buttons()
