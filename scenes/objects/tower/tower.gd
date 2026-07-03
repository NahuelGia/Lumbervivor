class_name Tower
extends StaticBody2D

const PROJECTILE_SCENE := preload("res://scenes/objects/tower/tower_projectile.tscn")
const DETECTION_RANGE: float = 300.0
const FIRE_RATE: float = 1.0
const PROJECTILE_DAMAGE: int = 20

var _fire_timer: float = 0.0
var _current_target: Zombie
var _projectile_container: Node2D
var _current_direction: String = "south"
var _is_transitioning: bool = false

signal destroyed

@onready var health: HealthComponent = $HealthComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_sound_player: AudioStreamPlayer2D = $ShootSoundPlayer


func _ready() -> void:
	visible = false
	_update_collision_state()
	health.died.connect(_on_health_died)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_fire_timer = FIRE_RATE
	var root = get_tree().root.get_child(0)
	_projectile_container = root.find_child("Projectiles", true, false)
	if not _projectile_container:
		push_error("Tower: no se pudo encontrar el contenedor de proyectiles")
	_play_idle_animation()


func _physics_process(delta: float) -> void:
	if not visible:
		return
	_fire_timer -= delta
	_current_target = _find_nearest_zombie()
	if _current_target:
		_check_direction_change()
		if _fire_timer <= 0.0:
			_fire()
			_fire_timer = FIRE_RATE
	else:
		_current_target = null


func _find_nearest_zombie() -> Zombie:
	var zombies = get_tree().get_nodes_in_group("zombies")
	var nearest: Zombie = null
	var nearest_dist: float = DETECTION_RANGE
	for zombie in zombies:
		if not is_instance_valid(zombie):
			continue
		var dist := global_position.distance_to(zombie.global_position)
		if dist < nearest_dist:
			nearest = zombie
			nearest_dist = dist
	return nearest


func _fire() -> void:
	if not _projectile_container or not _current_target:
		return
	var projectile: TowerProjectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position
	var aim_point := _calculate_lead_position(_current_target)
	projectile.direction = global_position.direction_to(aim_point)
	projectile.damage = PROJECTILE_DAMAGE
	_projectile_container.add_child(projectile)
	shoot_sound_player.play()


func _calculate_lead_position(target: Zombie) -> Vector2:
	var target_velocity: Vector2 = target.velocity
	var to_target: Vector2 = target.global_position - global_position

	var a: float = target_velocity.dot(target_velocity) - TowerProjectile.SPEED * TowerProjectile.SPEED
	var b: float = 2.0 * to_target.dot(target_velocity)
	var c: float = to_target.dot(to_target)

	var t: float = 0.0
	if abs(a) < 0.0001:
		if abs(b) > 0.0001:
			t = -c / b
	else:
		var discriminant: float = b * b - 4.0 * a * c
		if discriminant >= 0.0:
			var sqrt_disc: float = sqrt(discriminant)
			t = _smallest_positive_root((-b + sqrt_disc) / (2.0 * a), (-b - sqrt_disc) / (2.0 * a))

	if t <= 0.0:
		return target.global_position
	return target.global_position + target_velocity * t


func _smallest_positive_root(t1: float, t2: float) -> float:
	if t1 > 0.0 and t2 > 0.0:
		return min(t1, t2)
	elif t1 > 0.0:
		return t1
	elif t2 > 0.0:
		return t2
	return 0.0


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func setup_obstacle() -> void:
	var nav_obstacle = NavigationObstacle2D.new()
	nav_obstacle.vertices = PackedVector2Array([-20, -20, 20, -20, 20, 20, -20, 20])
	add_child(nav_obstacle)


func _on_health_died() -> void:
	destroyed.emit()
	queue_free()


func _update_collision_state() -> void:
	if is_instance_valid(collision_shape):
		collision_shape.disabled = not visible


func _get_direction_from_angle(angle: float) -> String:
	var normalized_angle = fmod(angle + TAU, TAU)
	normalized_angle = rad_to_deg(normalized_angle)

	if normalized_angle >= 337.5 or normalized_angle < 22.5:
		return "east"
	elif normalized_angle < 67.5:
		return "south_east"
	elif normalized_angle < 112.5:
		return "south"
	elif normalized_angle < 157.5:
		return "south_west"
	elif normalized_angle < 202.5:
		return "west"
	elif normalized_angle < 247.5:
		return "north_west"
	elif normalized_angle < 292.5:
		return "north"
	else:
		return "north_east"


func _check_direction_change() -> void:
	if not _current_target or _is_transitioning:
		return

	var target_direction = _get_direction_from_angle(
		global_position.angle_to_point(_current_target.global_position)
	)

	if target_direction != _current_direction:
		_is_transitioning = true
		_play_transition_animation(target_direction)


func _play_transition_animation(target_direction: String) -> void:
	var transition_name = "%s_to_%s" % [_current_direction, target_direction]

	if animated_sprite.sprite_frames.has_animation(transition_name):
		animated_sprite.play(transition_name)
	else:
		var reverse_name = "%s_to_%s" % [target_direction, _current_direction]
		if animated_sprite.sprite_frames.has_animation(reverse_name):
			animated_sprite.play(reverse_name)
			animated_sprite.flip_h = true
		else:
			_is_transitioning = false
			_current_direction = target_direction
			_play_idle_animation()


func _play_idle_animation() -> void:
	var idle_name = "idle_%s" % _current_direction
	if animated_sprite.sprite_frames.has_animation(idle_name):
		animated_sprite.play(idle_name)
		animated_sprite.flip_h = false


func _on_animation_finished() -> void:
	if _is_transitioning:
		_is_transitioning = false
		_play_idle_animation()
