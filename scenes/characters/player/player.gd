class_name Player
extends CharacterBody2D

const WOOD_PER_TREE: int = 5
const STONE_PER_ROCK: int = 10
const HIT_SOUNDS: Array = [
	preload("res://assets/audio/hit1.wav"),
	preload("res://assets/audio/hit2.wav"),
	preload("res://assets/audio/hit3.wav"),
]
const PUSH_FORCE: float = 300.0
const PUSH_DURATION: float = 0.3

enum Direction { E, SE, S, SW, W, NW, N, NE }

@export var move_speed: float = 250.0

var wood: int = 0
var stone: int = 0
var _facing: Direction = Direction.E
var _move_dir: Direction = Direction.E
var _footstep_timer: float = 0.0
var _axe_hit_cooldown: float = 0.0

const FOOTSTEP_INTERVAL: float = 0.65
const AXE_HIT_COOLDOWN: float = 0.65	

signal wood_changed(amount: int)
signal stone_changed(amount: int)
signal health_changed(current: int, max_val: int)
signal died

@onready var axe: Axe = $Axe
@onready var health: HealthComponent = $HealthComponent
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var axe_hit_player: AudioStreamPlayer = $AxeHitPlayer
@onready var zombie_hit_player: AudioStreamPlayer = $ZombieHitPlayer


func _ready() -> void:
	
	health.health_changed.connect(health_changed.emit)
	health.died.connect(died.emit)
	health_changed.emit(health.current_health, health.max_health)
	axe.hit_zombie.connect(_on_axe_hit_zombie)
	axe.hit_zombie_push.connect(_on_axe_hit_zombie_push)
	axe.hit_tree.connect(_on_axe_hit_tree)
	axe.hit_stone.connect(_on_axe_hit_stone)
	anim_sprite.animation_finished.connect(_on_animation_finished)
	


func _physics_process(delta: float) -> void:
	_handle_movement()
	_face_mouse()
	_handle_attack()
	_handle_push()
	_update_idle_animation()
	_handle_footstep(delta)
	_axe_hit_cooldown = maxf(0.0, _axe_hit_cooldown - delta)
	move_and_slide()


func _handle_movement() -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	if direction.length_squared() > 0.0:
		_move_dir = _angle_to_direction(direction.angle())


func _handle_footstep(delta: float) -> void:
	var is_walking := anim_sprite.animation.begins_with("walk") and anim_sprite.is_playing()
	if not is_walking:
		if footstep_player.playing:
			footstep_player.stop()
		return
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = FOOTSTEP_INTERVAL
		footstep_player.play()


func _face_mouse() -> void:
	look_at(get_global_mouse_position())
	_facing = _angle_to_direction(rotation)
	anim_sprite.rotation = -rotation


func _angle_to_direction(angle: float) -> Direction:
	var deg := fposmod(rad_to_deg(angle) + 22.5, 360.0)
	match int(deg / 45.0) % 8:
		0: return Direction.E
		1: return Direction.SE
		2: return Direction.S
		3: return Direction.SW
		4: return Direction.W
		5: return Direction.NW
		6: return Direction.N
		7: return Direction.NE
	return Direction.E


func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		if axe.can_swing():
			var anim := _get_attack_anim()
			if anim != "":
				var frames := anim_sprite.sprite_frames
				var duration := frames.get_frame_count(anim) / frames.get_animation_speed(anim)
				anim_sprite.speed_scale = duration / axe.attack_cooldown
				anim_sprite.play(anim)
		axe.swing()


func _get_attack_anim() -> String:
	match _facing:
		Direction.N:  return "attack_north"
		Direction.NE: return "attack_north_east"
		Direction.E:  return "attack_east"
		Direction.SE: return "attack_south_east"
		Direction.S:  return "attack_south"
		Direction.SW: return "attack_south_west"
		Direction.W:  return "attack_west"
		Direction.NW: return "attack_north_west"
		_: return ""


func _handle_push() -> void:
	if Input.is_action_just_pressed("push"):
		if axe.can_swing():
			var anim := _get_push_anim()
			if anim != "":
				var frames := anim_sprite.sprite_frames
				var duration := frames.get_frame_count(anim) / frames.get_animation_speed(anim)
				anim_sprite.speed_scale = duration / axe.attack_cooldown
				anim_sprite.play(anim)
		axe.push_swing()


func _get_push_anim() -> String:
	match _facing:
		Direction.N:  return "push_north"
		Direction.NE: return "push_north_east"
		Direction.E:  return "push_east"
		Direction.SE: return "push_south_east"
		Direction.S:  return "push_south"
		Direction.SW: return "push_south_west"
		Direction.W:  return "push_west"
		Direction.NW: return "push_north_west"
		_: return ""


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func restore_health() -> void:
	health.restore()


func spend_wood(amount: int) -> bool:
	if wood < amount:
		return false
	wood -= amount
	wood_changed.emit(wood)
	return true


func spend_stone(amount: int) -> bool:
	if stone < amount:
		return false
	stone -= amount
	stone_changed.emit(stone)
	return true


func upgrade_axe(damage_bonus: int) -> void:
	axe.damage += damage_bonus


func upgrade_armor(health_bonus: int) -> void:
	health.increase_max(health_bonus)


func _update_idle_animation() -> void:
	var is_moving := velocity.length_squared() > 0.0
	var anim_name := anim_sprite.animation
	if (anim_name.begins_with("attack") or anim_name.begins_with("push")) and anim_sprite.is_playing():
		return
	anim_sprite.speed_scale = 1.0
	var anim := _get_walk_anim() if is_moving else _get_idle_anim()
	if anim != "":
		anim_sprite.play(anim)
	else:
		anim_sprite.stop()


func _get_walk_anim() -> String:
	match _move_dir:
		Direction.N:  return "walk_north"
		Direction.NE: return "walk_north_east"
		Direction.E:  return "walk_east"
		Direction.SE: return "walk_south_east"
		Direction.S:  return "walk_south"
		Direction.SW: return "walk_south_west"
		Direction.W:  return "walk_west"
		Direction.NW: return "walk_north_west"
		_: return _get_idle_anim()


func _get_idle_anim() -> String:
	match _move_dir:
		Direction.N:  return "idle_north"
		Direction.NE: return "idle_north_east"
		Direction.E:  return "idle_east"
		Direction.SE: return "idle_south_east"
		Direction.S:  return "idle_south"
		Direction.SW: return "idle_south_west"
		Direction.W:  return "idle_west"
		Direction.NW: return "idle_north_west"
		_: return ""


func _on_animation_finished() -> void:
	_update_idle_animation()


func _on_axe_hit_zombie(zombie: Zombie) -> void:
	zombie.take_damage(axe.damage)
	zombie_hit_player.stream = HIT_SOUNDS[randi() % HIT_SOUNDS.size()]
	zombie_hit_player.play()


func _on_axe_hit_zombie_push(zombie: Zombie) -> void:
	var dir := zombie.global_position - global_position
	if dir.is_zero_approx():
		dir = Vector2.RIGHT
	else:
		dir = dir.normalized()
	zombie.apply_knockback(dir * PUSH_FORCE, PUSH_DURATION)


func _harvest(resource: Destructible, finished_signal: Signal, on_finished: Callable) -> void:
	if not finished_signal.is_connected(on_finished):
		finished_signal.connect(on_finished, CONNECT_ONE_SHOT)
	resource.take_damage(axe.damage)
	_play_axe_hit_feedback()


func _on_axe_hit_tree(tree: ChoppableTree) -> void:
	_harvest(tree, tree.chopped, _on_tree_chopped)


func _on_tree_chopped() -> void:
	wood += WOOD_PER_TREE
	wood_changed.emit(wood)


func _on_axe_hit_stone(stone_node: ChoppableStone) -> void:
	_harvest(stone_node, stone_node.mined, _on_stone_mined)


func _on_stone_mined() -> void:
	stone += STONE_PER_ROCK
	stone_changed.emit(stone)


func _play_axe_hit_feedback() -> void:
	if _axe_hit_cooldown > 0.0:
		return
	_axe_hit_cooldown = AXE_HIT_COOLDOWN
	axe_hit_player.play()
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(axe_hit_player):
		axe_hit_player.stop()
