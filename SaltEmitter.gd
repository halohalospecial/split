# SaltEmitter
extends Node2D
const Salt = preload("res://Salt.tscn")

var is_active = false
var salt_parent = null

export (bool) var is_firework = false
export (Rect2) var firework_bounds = Rect2(0, 0, 0, 0)
export (bool) var has_firework_sounds = false

func _ready():
	if is_firework:
		randomize()
		compute_firework_position()
		$SpawnTimer.wait_time = rand_range(1.0, 3.0)
		$SpawnTimer.start()
		explode()

func compute_firework_position():
	position = Vector2(firework_bounds.position.x + rand_range(0, firework_bounds.size.x), firework_bounds.position.y + rand_range(0, firework_bounds.size.y))

func start():
	is_active = true
	spawn_many()
	$SpawnTimer.start()

func explode(extra_velocity = Vector2.ZERO):
	is_active = false
	for i in 32:
		var salt = spawn()
		var radians = rand_range(0, TAU)
		var value = rand_range(200, 400)
		salt.duration = salt.duration * 1.5
		salt.linear_velocity = Vector2(cos(radians) * value, sin(radians) * value) + extra_velocity
	if not is_firework:
		$SpawnTimer.stop()

func _on_SpawnTimer_timeout():
	if is_firework:
		compute_firework_position()
		explode()
	else:
		spawn_many()

func spawn_many():
	for i in randi() % 4 + 1:
		spawn()
		$SpawnTimer.wait_time = rand_range(0.1, 0.3)
		$SpawnTimer.start()

func spawn():
	var salt = Salt.instance()
	if salt_parent:
		salt_parent.get_parent().call_deferred("add_child", salt)
		salt.position = salt_parent.position + Vector2(rand_range(-8, 8), -22 + rand_range(-4, 4))
	else:
		get_parent().call_deferred("add_child", salt)
		salt.position = position + Vector2(rand_range(-8, 8), -22 + rand_range(-4, 4))
	salt.z_index = z_index + 1
	var scale = rand_range(1, 1.5)
	salt.scale = Vector2(scale, scale)
	salt.gravity_scale = rand_range(1, 1.5)
	return salt
