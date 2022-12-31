# Player1
extends "res://Player.gd"
# const TrailSprite = preload("res://PlayerSprite2.tscn")

export (bool) var is_bobbing = true
export (bool) var has_trails = false
export(float) var move_speed = 250.0
export (int) var max_speed = 200
export (float) var acceleration = 15.0
export (float, 0, 1.0) var friction = 0.1
export (int, 0, 200) var push_strength = 100

var bob_time = 0
var bob_offset_y = 0
var is_stepped_on = false

var is_colliding_with_tile = false

func _ready():
	yield(get_tree(), "idle_frame")
	world = get_parent()
	if has_trails:
		$TrailTimer.start()

func reset():
	is_complete = false
	velocity = Vector2.ZERO
	direction = initial_direction
	bob_time = 0
	original_position = null
	is_stepped_on = false
	freeze_unfreeze_time = 0
	split_previous_y = position.y

func _physics_process(delta):
	if not is_inside_tree():
		return

	if is_interactive:
		if not is_complete:
			handle_freeze_unfreeze_camera()
			handle_motion(delta)
			handle_bobbing(delta)
			other_player.is_stepping_on_other_player = $HeadArea1.overlaps_body(other_player)
			is_stepped_on = other_player.is_stepping_on_other_player
			handle_collisions()
			handle_animation()
	else:
		handle_bobbing(delta)
		handle_animation()

func handle_bobbing(delta):
	if is_bobbing:
		if is_idle():
			var freq = 5
			var amplitude = 4
			bob_time += delta
			bob_offset_y = sin(bob_time * freq) * amplitude
			$AnimatedSprite.position.y = bob_offset_y
			$Eyes.position.y = bob_offset_y
			$CollisionShape2D.position.y = bob_offset_y
			$HeadArea1.position.y = bob_offset_y
			$ConnectArea1.position.y = bob_offset_y
			$PlayerLight.position.y = bob_offset_y
			$LightOccluder2D.position.y = bob_offset_y
			$SaltCollider.position.y = bob_offset_y
			$FloorRayCast.position.y = bob_offset_y

func handle_freeze_unfreeze_camera():
	if Input.is_action_just_pressed("freeze_screen_1"):
		freeze_unfreeze_time = OS.get_ticks_msec()
		split_previous_y = position.y
		is_camera_frozen = not is_camera_frozen
		if is_camera_frozen:
			handle_freeze_camera()
		else:
			handle_unfreeze_camera()

func handle_freeze_camera():
	camera.target = null
	camera.smoothing_enabled = false
	camera.position = position

	add_frozen_colliders()
	transfer_player()

	if shake_on_merge_screen_enabled:
		camera.shake(0.475)

func transfer_player():
	get_parent().remove_child(self)
	frozen_view.add_child(self)
	original_position = camera.position
	position = Vector2(CENTER_X, HALF_SPLIT_HEIGHT)
	initial_frozen_position = position

func handle_unfreeze_camera():
	remove_frozen_colliders()
	return_player()

	$PlayerSplitParticles.visible = false
	camera.smoothing_enabled = true
	camera.target = self

	if not is_complete:
		set_collision_layer_bit(0, 1)
		set_collision_mask_bit(0, 1)

func return_player():
	frozen_view.remove_child(self)
	world.add_child(self)
	if position.y <= SPLIT_Y:
		position = position - Vector2(CENTER_X, HALF_SPLIT_HEIGHT) + original_position
	else:
		var delta = other_player.original_position - Vector2(CENTER_X, THREE_QUARTERS_SPLIT_HEIGHT)
		position = position + delta

func add_frozen_colliders():
	var tile_map = get_parent().get_node("TileMap")

	var cell_width = tile_map.cell_size.x
	var cell_height = tile_map.cell_size.y
	var half_cell_width = cell_width / 2
	var half_cell_height = cell_height / 2
	
	frozen_colliders = StaticBody2D.new()
	frozen_colliders.set_collision_layer_bit(5, 32) # for salt collision

	for cell in tile_map.get_used_cells():
		var collider_x = CENTER_X - camera.position.x + (cell.x * cell_width) + half_cell_width + tile_map.position.x
		var collider_y = HALF_SPLIT_HEIGHT - camera.position.y + (cell.y * cell_height) + half_cell_height + tile_map.position.y
		
		if collider_y - half_cell_height <= SPLIT_Y:
			var rect = RectangleShape2D.new()

			var collider_height = cell_height
			var excess = 0
			if collider_y + half_cell_height > SPLIT_Y:
				excess = collider_y + half_cell_height - SPLIT_Y
				collider_height = cell_height - excess
				rect.set_extents(Vector2(half_cell_width, collider_height / 2))
				collider_y = collider_y - (excess / 2)
			else:
				rect.set_extents(Vector2(half_cell_width, half_cell_height))

			# Do not add thin colliders
			if rect.get_extents().y >= 0.5:
				var collider = CollisionShape2D.new()
				frozen_colliders.call_deferred("add_child", collider)
				collider.shape = rect
				collider.translate(Vector2(collider_x, collider_y))
				
				if player_light_enabled:
					var light_occluder = LightOccluder2D.new()
					frozen_colliders.call_deferred("add_child", light_occluder)
					light_occluder.translate(Vector2(collider_x -half_cell_width , collider_y - half_cell_height))
					var occluder = OccluderPolygon2D.new()
					var half_excess = excess / 2
					occluder.polygon = PoolVector2Array([Vector2(0, half_excess), Vector2(cell_width, half_excess), Vector2(cell_width, half_excess + collider_height), Vector2(0, half_excess + collider_height)])
					light_occluder.occluder = occluder
			
	frozen_view.call_deferred("add_child", frozen_colliders)

func handle_motion(delta):
	var is_colliding_with_floor = $FloorRayCast.is_colliding() and $FloorRayCast.get_collider().name != "Player2"
	if Input.is_action_pressed("move_left_1"):
		velocity.x = max(velocity.x - acceleration, -max_speed)
		if direction == DIRECTION_RIGHT and velocity.x > 0 and is_colliding_with_floor:
			create_foot_dust(velocity.x / 10, position.distance_to($FloorRayCast.get_collision_point()))
			reset_walk_dust_timer()
		direction = DIRECTION_LEFT
	elif Input.is_action_pressed("move_right_1"):
		velocity.x = min(velocity.x + acceleration, max_speed)
		if direction == DIRECTION_LEFT and velocity.x < 0 and is_colliding_with_floor:
			create_foot_dust(velocity.x / 10, position.distance_to($FloorRayCast.get_collision_point()))
			reset_walk_dust_timer()
		direction = DIRECTION_RIGHT
	else:
		velocity.x = lerp(velocity.x, 0, friction)

	if abs(velocity.x) > 10 and is_colliding_with_floor:
		walk_dust_timer += delta
		if walk_dust_timer > walk_dust_every:
			create_foot_dust(0, position.distance_to($FloorRayCast.get_collision_point()))
			reset_walk_dust_timer()
	else:
		walk_dust_timer = 0
	
	if Input.is_action_pressed("move_up_1"):
		velocity.y = max(velocity.y - acceleration, -max_speed)
	elif Input.is_action_pressed("move_down_1"):
		
		velocity.y = min(velocity.y + acceleration, max_speed)
	else:
		velocity.y = lerp(velocity.y, 0, friction)

	var up_direction = Vector2.UP
	var stop_on_slope = false
	var max_slides = 4
	var floor_max_angle = PI/4
	var infinite_inertia = false
	velocity = move_and_slide(velocity, up_direction, stop_on_slope, max_slides, floor_max_angle, infinite_inertia)

func handle_collisions():
	# Workaround to not teleport lower half to (300, 300) when upper half is in (300, 450)
	if not is_complete and is_camera_frozen:
		var collision_value = not has_just_frozen_unfrozen()
		set_collision_layer_bit(0, collision_value)
		set_collision_mask_bit(0, collision_value)

	var was_colliding_with_tile = is_colliding_with_tile
	is_colliding_with_tile = false
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider is RigidBody2D:
			collision.collider.apply_central_impulse(-collision.normal * push_strength)
		is_colliding_with_tile = collision.collider.is_class("TileMap") or collision.collider.is_class("StaticBody2D")
		if is_colliding_with_tile and not was_colliding_with_tile and not is_idle():
			var offset = collision.normal * -14
			create_tile_dust(offset.x, offset.y)

func handle_leaning():
	if velocity.x <= -10:
		$AnimatedSprite.rotation_degrees = max(velocity.x, -40) / 10.0
	elif velocity.x >= 10:
		$AnimatedSprite.rotation_degrees = min(velocity.x, 40) / 10.0
	else:
		$AnimatedSprite.rotation_degrees = 0
	$Eyes.rotation_degrees = $AnimatedSprite.rotation_degrees

func handle_animation():
	if direction in [DIRECTION_RIGHT, DIRECTION_NEUTRAL]:
		$AnimatedSprite.flip_h = false
		$AnimatedSprite.offset.x = 0
	elif direction == DIRECTION_LEFT:
		$AnimatedSprite.flip_h = true
		$AnimatedSprite.offset.x = 6

	if is_stepped_on and is_idle():
		$AnimatedSprite.play("stepped_on")
		$Eyes.play("blank")
	else:
		$AnimatedSprite.play("idle")
		if $AnimatedSprite.get_animation() == "idle" and $AnimatedSprite.get_frame() == 0:
			# Blink
			$Eyes.play("blank")
		else:
			$Eyes.play("idle")
	
	handle_eyes()
	handle_leaning()
	handle_split_particles()

func is_near(target):
	var look_min_distance = 32 * 6
	return position.distance_squared_to(target.position) <= look_min_distance * look_min_distance

func handle_eyes():
	var eyes_offset = Vector2.ZERO
	var extra_eyes_offset = Vector2.ZERO
	if direction in [DIRECTION_RIGHT, DIRECTION_NEUTRAL]:
		$Eyes.flip_h = false
	elif direction == DIRECTION_LEFT:
		$Eyes.flip_h = true
		extra_eyes_offset = Vector2(6, 0)

	var look_target = null
	if not is_stepped_on and other_player and is_near(other_player):
		look_target = other_player
		eyes_offset = position.direction_to(look_target.position).round()
	else:
		if velocity.x <= -10:
			eyes_offset.x = -1
		elif velocity.x >= 10:
			eyes_offset.x = 1
		if velocity.y <= -10:
			eyes_offset.y = -1
		elif velocity.y >= 10:
			eyes_offset.y = 1

	var direction_sign = -1 if direction == DIRECTION_LEFT else 1
	$Eyes.offset = Vector2(direction_sign, 0) if eyes_offset.is_equal_approx(Vector2.ZERO) else eyes_offset
	$Eyes.offset += extra_eyes_offset

func is_idle():
	return abs(velocity.x) < 10 and abs(velocity.y) < 10

func _on_ConnectArea_area_entered(area):
	if area.name == "ConnectArea2" and not is_complete and not other_player.has_salt:
		is_complete = true
		# Disable collision
		set_collision_layer_bit(0, 0)
		set_collision_mask_bit(0, 0)

# func create_trail():
# 	var trail_sprite = TrailSprite.instance()
# 	trail_sprite.visible = false
# 	get_parent().call_deferred("add_child", trail_sprite)
# 	yield(get_tree(), "idle_frame")
# 	trail_sprite.position = position + Vector2(0, bob_offset_y)
# 	trail_sprite.playing = false
# 	trail_sprite.animation = $AnimatedSprite.animation
# 	trail_sprite.frame = $AnimatedSprite.frame
# 	trail_sprite.flip_h = $AnimatedSprite.flip_h
# 	trail_sprite.is_trail = true
# 	trail_sprite.visible = true
# 	trail_sprite.z_index = z_index - 1

# func _on_TrailTimer_timeout():
# 	var speed_threshold = max_speed * 0.75
# 	if abs(velocity.x) >= speed_threshold or abs(velocity.y) >= speed_threshold:
# 		create_trail()
