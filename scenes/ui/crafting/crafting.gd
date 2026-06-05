class_name CraftingBench
extends Control

const COST_AXE: int = 100
const COST_ARMOR: int = 50
const COST_BARRICADE: int = 30

var _player: Player
var _fence: CabinFence
var _is_day: bool = true
var _bench_paused: bool = false
var _axe_bought: bool = false
var _armor_bought: bool = false
var _barricade_bought: bool = false

@onready var axe_button: Button = $PanelContainer/MarginContainer/VBoxContainer/AxeButton
@onready var armor_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ArmorButton
@onready var barricade_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BarricadeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	axe_button.process_mode = Node.PROCESS_MODE_ALWAYS
	armor_button.process_mode = Node.PROCESS_MODE_ALWAYS
	barricade_button.process_mode = Node.PROCESS_MODE_ALWAYS


func setup(player: Player, fence: CabinFence) -> void:
	_player = player
	_fence = fence
	player.wood_changed.connect(_on_wood_changed)


func enable(_round: int) -> void:
	_is_day = true


func disable(_round: int) -> void:
	_is_day = false
	if visible:
		_close()
	else:
		visible = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_bench") and _is_day:
		if visible:
			_close()
		else:
			_open()


func _open() -> void:
	visible = true
	_bench_paused = true
	get_tree().paused = true
	_update_buttons()


func _close() -> void:
	visible = false
	if _bench_paused:
		_bench_paused = false
		get_tree().paused = false


func _on_wood_changed(_amount: int) -> void:
	if visible:
		_update_buttons()


func _update_buttons() -> void:
	var axe_suffix := "  [COMPRADO]" if _axe_bought else "  —  %d madera" % COST_AXE
	axe_button.text = "Hacha mejorada  +15 daño" + axe_suffix
	axe_button.disabled = _axe_bought or _player.wood < COST_AXE

	var armor_suffix := "  [COMPRADO]" if _armor_bought else "  —  %d madera" % COST_ARMOR
	armor_button.text = "Armadura de madera  +30 HP máx." + armor_suffix
	armor_button.disabled = _armor_bought or _player.wood < COST_ARMOR

	var barricade_suffix := "  [COMPRADO]" if _barricade_bought else "  —  %d madera" % COST_BARRICADE
	barricade_button.text = "Barricada de madera  +100 HP reja" + barricade_suffix
	barricade_button.disabled = _barricade_bought or _player.wood < COST_BARRICADE


func _on_axe_button_pressed() -> void:
	if _axe_bought or not _player.spend_wood(COST_AXE):
		return
	_player.upgrade_axe(15)
	_axe_bought = true
	_update_buttons()


func _on_armor_button_pressed() -> void:
	if _armor_bought or not _player.spend_wood(COST_ARMOR):
		return
	_player.upgrade_armor(30)
	_armor_bought = true
	_update_buttons()


func _on_barricade_button_pressed() -> void:
	if _barricade_bought or not _player.spend_wood(COST_BARRICADE):
		return
	if not is_instance_valid(_fence):
		return
	_fence.repair(100)
	_barricade_bought = true
	_update_buttons()
