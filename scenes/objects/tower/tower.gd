class_name Tower
extends StaticBody2D

const PROJECTILE_SCENE := preload("res://scenes/objects/tower/tower_projectile.tscn")
const DETECTION_RANGE: float = 300.0
const FIRE_RATE: float = 1.0
const PROJECTILE_DAMAGE: int = 20

var _fire_timer: float = 0.0
var _current_target: Zombie
var _projectile_container: Node2D

signal destroyed

@onready var health: HealthComponent = $HealthComponent
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	health.died.connect(_on_health_died)
	_fire_timer = FIRE_RATE
	var root = get_tree().root.get_child(0)
	_projectile_container = root.find_child("Projectiles", true, false)
	if not _projectile_container:
		push_error("Tower: no se pudo encontrar el contenedor de proyectiles")


func _physics_process(delta: float) -> void:
	_fire_timer -= delta
	_current_target = _find_nearest_zombie()
	if _current_target:
		_rotate_towards(_current_target.global_position)
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


func _rotate_towards(target_pos: Vector2) -> void:
	var direction := target_pos - global_position
	rotation = direction.angle()


func _fire() -> void:
	if not _projectile_container:
		return
	var projectile: TowerProjectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position
	projectile.direction = Vector2.RIGHT.rotated(rotation)
	projectile.damage = PROJECTILE_DAMAGE
	_projectile_container.add_child(projectile)


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func setup_obstacle() -> void:
	var nav_obstacle = NavigationObstacle2D.new()
	nav_obstacle.vertices = PackedVector2Array([-20, -20, 20, -20, 20, 20, -20, 20])
	add_child(nav_obstacle)


func _on_health_died() -> void:
	destroyed.emit()
	queue_free()
