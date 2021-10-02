# Player2
extends "res://Player.gd"

# Z-indices:
#   0 = Player1 trails
#   1 = Player1
#   2 = Player2
#   3 = Salt remover
#   4 = Salt
#   5 = Fog
#   6 = Complete Particles
#   7 = Ending Player

export (bool) var is_bot_evading = false
export (bool) var is_bot_jumping = false
export (bool) var has_salt = false
export (int) var max_speed = 200
export (int) var jump_speed = 380
export (int) var gravity = 980
export (float, 0, 1.0) var friction = 0.2
export (float) var acceleration = 15
export (int, 0, 200) var push_strength = 100
export (bool) var has_footstep_sound = true

var salt_remover = null

var level_index = null
var level_complete_view = null
var level_container = null

var initial_has_salt = false
var is_stepping_on_other_player = false

var air_time = 0
var was_in_air = false

var shake_on_reunite_enabled = ProjectSettings.get("effects/shake_on_reunite")

# For footsteps
var footstep_sound_enabled = ProjectSettings.get("effects/footstep_sound")
var jump_sound_enabled = ProjectSettings.get("effects/jump_sound")
var walk_sound_every = 0
var walk_sound_timer = 0

# For buffered jump and coyote time:
var jump_was_pressed = false
var was_grounded = false

var input_x = DIRECTION_NEUTRAL
var input_jump = false

var bot_action_time_remaining = 0
var bot_action = 0
var bot_ray_cast_vector = Vector2.ZERO

func _exit_tree():
	Engine.time_scale = 1.0

func reset():
	is_complete = false
	velocity = Vector2.ZERO
	direction = initial_direction
	original_position = null
	has_salt = initial_has_salt

	jump_was_pressed = false
	$BufferedJumpTimer.stop()
	was_grounded = false
	$CoyoteTimeTimer.stop()
	was_in_air = false
	walk_dust_every = 0
	walk_dust_timer = 0
	walk_sound_every = 0
	walk_sound_timer = 0
	freeze_unfreeze_time = 0
	split_previous_y = position.y

func _ready():
	if is_bot_evading:
		randomize()
		$BotRayCast.enabled = true
		$BotRayCast2.enabled = true
		bot_ray_cast_vector = $BotRayCast.cast_to
	$Salt/SaltEmitter.salt_parent = self
	$CompleteParticles.emitting = false
	initial_has_salt = has_salt
	if initial_has_salt:
		add_salt()
	else:
		has_salt = false
		$Salt.visible = false

	yield(get_tree(), "idle_frame")
	world = get_parent()
	salt_remover = world.get_node_or_null("SaltRemover")
	if salt_remover:
		salt_remover.get_node("SaltRemoverArea").connect("area_entered", self, "_on_SaltRemoverArea_area_entered")

func add_salt():
	has_salt = true
	$Salt.visible = true
	$Salt/SaltLabel.visible = true
	$Salt/Particles2D.amount = 8
	$Salt/Particles2D.one_shot = false
	$Salt/Particles2D.lifetime = 0.5
	$Salt/SaltEmitter.start()

func remove_salt():
	has_salt = false
	$Salt/Particles2D.amount = 32
	$Salt/Particles2D.one_shot = true
	$Salt/Particles2D.lifetime = 0.75
	$Salt/Particles2D.explosiveness = 0.5
	$Salt/Particles2D.process_material.gravity = Vector3(0, 98 * 4, 0)
	$Salt/Particles2D.process_material.initial_velocity = 200
	$Salt/SaltLabel.visible = false
	$Salt/SaltEmitter.explode(velocity)

func _physics_process(delta):
	if not is_inside_tree():
		return

	if is_interactive:
		if is_complete:
			handle_motion(delta)
			handle_collisions()
			handle_animation(delta)
			if Input.is_action_just_pressed("next_level"):
				if level_index == Global.ENDING_LEVEL:
					Global.has_played_ending = true
					$GottaSplitSound.play()
					yield($GottaSplitSound, "finished")
				level_container.go_to_next_level()
		else:
			handle_freeze_unfreeze_camera()
			if is_bot_evading:
				handle_bot_evading(delta)
			elif is_bot_jumping:
				handle_bot_jumping()
			else:
				handle_input()
			handle_jumping(delta)
			handle_walking(delta)
			handle_motion(delta)
			handle_collisions()
			handle_animation(delta)
	else:
		$AnimatedSprite.play("walk")

func handle_bot_evading(delta):
	# Actions:
	#   0 = stay
	#  -1 = move left
	#   1 = move right
	#  -2 = jump left
	#   2 = jump right
	
	var result
	if bot_action_time_remaining > 0:
		bot_action_time_remaining -= delta
	else:
		result = rand_range(0.0, 1.0)
		
		# Stay 10%
		if result < 0.1:
			bot_action = 0
			# If other player is near maybe move left or move right
			if position.x > other_player.position.x - 50 and position.x < other_player.position.x + 50:
				result = rand_range(0.0, 1.0)
				if result < 0.9:
					if other_player.position.x >= position.x:
						bot_action = -1
					else:
						bot_action = 1

		# Move left 30%
		elif result < 0.4:
			bot_action = -1
			# If other player is at the left, maybe move right
			if other_player.position.x < position.x and position.x > other_player.position.x - 300 and position.x < other_player.position.x + 300:
				result = rand_range(0.0, 1.0)
				# Move right 90%
				if result < 0.9:
					bot_action = 1

		# Move left 30%
		elif result < 0.7:
			bot_action = 1
			# If other player is at the right, maybe move left
			if other_player.position.x > position.x and position.x > other_player.position.x - 300 and position.x < other_player.position.x + 300:
				result = rand_range(0.0, 1.0)
				# Move left 90%
				if result < 0.9:
					bot_action = -1

		# Jump 30%
		else:
			result = rand_range(0.0, 1.0)
			if position.x > other_player.position.x - 50 and position.x < other_player.position.x + 50:
				# Do not jump if other player is above
				if result <= 0.5:
					bot_action = -1
				else:
					bot_action = 1
			else:
				if result <= 0.5:
					bot_action = -2
				else:
					bot_action = 2

		bot_action_time_remaining = rand_range(0.1, 0.3)

	if $BotRayCast.is_colliding():
		if bot_action in [-1, 1]:
			result = rand_range(0.0, 1.0)
			if result < 0.8:
				# Reverse direction
				bot_action *= -1
				bot_action_time_remaining = rand_range(0.1, 0.3)
			elif result < 0.9:
				result = rand_range(0.0, 1.0)
				if result <= 0.5:
					bot_action = -2
				else:
					bot_action = 2

	if $BotRayCast2.is_colliding():
		if bot_action == -2:
			bot_action = -1
		elif bot_action == 2:
			bot_action = 2

	if bot_action == 0:
		bot_action_time_remaining /= 2
	elif bot_action == -1:
		input_x = -1
		$BotRayCast.cast_to = -bot_ray_cast_vector
	elif bot_action == 1:
		input_x = 1
		$BotRayCast.cast_to = bot_ray_cast_vector
	elif bot_action == -2:
		input_x = -1
		input_jump = true
		bot_action_time_remaining = 0
	elif bot_action == 2:
		input_x = 1
		input_jump = true
		bot_action_time_remaining = 0

func handle_bot_jumping():
	input_jump = true

func handle_input():
	if Input.is_action_pressed("move_left_2"):
		input_x = -1
	elif Input.is_action_pressed("move_right_2"):
		input_x = 1
	else:
		input_x = 0

	if Input.is_action_just_pressed("move_up_2") or (was_grounded and Input.is_action_pressed("move_up_2")):
		input_jump = true
	else:
		input_jump = false

func handle_walking(delta):
	if input_x == -1:
		velocity.x = max(velocity.x - acceleration, -max_speed)
		if direction == DIRECTION_RIGHT and velocity.x > 0 and is_on_floor():
			create_foot_dust(velocity.x / 10)
			reset_walk_dust_timer()
		direction = DIRECTION_LEFT
	elif input_x == 1:
		velocity.x = min(velocity.x + acceleration, max_speed)
		if direction == DIRECTION_LEFT and velocity.x < 0 and is_on_floor():
			create_foot_dust(velocity.x / 10)
			reset_walk_dust_timer()
		direction = DIRECTION_RIGHT
	else:
		velocity.x = lerp(velocity.x, 0, friction)

	if is_walking():
		walk_sound_timer += delta
		if walk_sound_timer > walk_sound_every:
			if footstep_sound_enabled:
				play_footstep()
			reset_walk_sound_timer()
			
		walk_dust_timer += delta
		if walk_dust_timer > walk_dust_every:
			create_foot_dust()
			reset_walk_dust_timer()
	else:
		walk_dust_timer = 0

func play_footstep(volume_db=-12):
	if has_footstep_sound:
		var footstep_sound = $FootstepSound
		footstep_sound.pitch_scale = rand_range(0.8, 1.2)
		footstep_sound.volume_db = volume_db
		footstep_sound.play()

func reset_walk_sound_timer():
	walk_sound_timer = 0
	walk_sound_every = 0.23

func handle_freeze_unfreeze_camera():
	if Input.is_action_just_pressed("freeze_screen_2"):
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
	transfer_salt_remover()
	transfer_player()

	$FreezeCameraSound.play()
	level_container.unsplit_screen()

	if shake_on_merge_screen_enabled:
		camera.shake(0.475)

func transfer_salt_remover():
	if is_instance_valid(salt_remover):
		if salt_remover.is_active:
			var salt_delta = salt_remover.position - camera.position
			var other_salt_delta = salt_remover.position - other_player.camera.position
			
			salt_remover.original_position = camera.position + salt_delta
			salt_remover.position = Vector2(CENTER_X, THREE_QUARTERS_SPLIT_HEIGHT) + salt_delta
			salt_remover.initial_frozen_position = salt_remover.position

			# Do not show if out of bounds of lower half screen
			if salt_remover.position.y + (salt_remover.get_rect().size.y / 2) > SPLIT_Y:
				get_parent().remove_child(salt_remover)
				frozen_view.add_child(salt_remover)
			else:
				salt_remover.get_parent().remove_child(salt_remover)

			# Make a clone for upper half
			# Do not show clone if out of bounds of upper half screen or has the same position as original
			var clone_position = Vector2(CENTER_X, HALF_SPLIT_HEIGHT) + other_salt_delta
			if not salt_remover.position.is_equal_approx(clone_position) and clone_position.y - (salt_remover.get_rect().size.y / 2)  <= SPLIT_Y:
				salt_remover.clone = salt_remover.duplicate()
				frozen_view.add_child(salt_remover.clone)
				salt_remover.clone.get_node("SaltRemoverArea").connect("area_entered", self, "_on_SaltRemoverArea_area_entered")
				salt_remover.clone.original_position = other_player.camera.position + other_salt_delta
				salt_remover.clone.position = clone_position
				salt_remover.clone.initial_frozen_position = salt_remover.clone.position

func transfer_player():
	get_parent().remove_child(self)
	frozen_view.add_child(self)	
	original_position = camera.position
	position = Vector2(CENTER_X, THREE_QUARTERS_SPLIT_HEIGHT)
	initial_frozen_position = position

func handle_unfreeze_camera():
	remove_frozen_colliders()
	return_salt_remover()
	return_player()

	$PlayerSplitParticles.visible = false
	camera.smoothing_enabled = true
	camera.target = self
	
	level_container.split_screen()
	$UnfreezeCameraSound.play()

func return_salt_remover():
	if is_instance_valid(salt_remover):
		if salt_remover.is_active:
			if frozen_view.is_a_parent_of(salt_remover):
				frozen_view.remove_child(salt_remover)
			world.add_child(salt_remover)
			var salt_delta = salt_remover.position - salt_remover.initial_frozen_position
			salt_remover.position = salt_remover.original_position + salt_delta

		if is_instance_valid(salt_remover.clone):
			if salt_remover.clone.is_active:
				if frozen_view.is_a_parent_of(salt_remover.clone):
					frozen_view.remove_child(salt_remover.clone)
				salt_remover.clone.queue_free()
				salt_remover.clone = null

func return_player():
	frozen_view.remove_child(self)
	world.add_child(self)
	if position.y > SPLIT_Y:
		position = position - Vector2(CENTER_X, THREE_QUARTERS_SPLIT_HEIGHT) + original_position
	else:
		var delta = other_player.original_position - Vector2(CENTER_X, HALF_SPLIT_HEIGHT)
		position = position + delta

func add_frozen_colliders():
	var tile_map = get_parent().get_node("TileMap")

	var cell_width = tile_map.cell_size.x
	var cell_height = tile_map.cell_size.y
	var half_cell_width = cell_width / 2
	var half_cell_height = cell_height / 2

	frozen_colliders = StaticBody2D.new()
	frozen_colliders.set_collision_layer_bit(5, 32) # for salt collision

	frozen_view.call_deferred("add_child", frozen_colliders)	

	for cell in tile_map.get_used_cells():
		var collider_x = CENTER_X - camera.position.x + (cell.x * cell_width) + half_cell_width + tile_map.position.x
		var collider_y = (THREE_QUARTERS_SPLIT_HEIGHT) - camera.position.y + (cell.y * cell_height) + half_cell_height + tile_map.position.y
		
		if collider_y + half_cell_height > SPLIT_Y:
			var rect = RectangleShape2D.new()
			
			var collider_height = cell_height
			var excess = 0
			if collider_y - half_cell_height <= SPLIT_Y:
				excess = SPLIT_Y - (collider_y - half_cell_height)
				collider_height = cell_height - excess
				rect.set_extents(Vector2(half_cell_width, collider_height / 2))
				collider_y = collider_y + (excess / 2)
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
					var half_sobra = excess / 2
					occluder.polygon = PoolVector2Array([Vector2(0, half_sobra), Vector2(cell_width, half_sobra), Vector2(cell_width, half_sobra + collider_height), Vector2(0, half_sobra + collider_height)])
					light_occluder.occluder = occluder

func handle_motion(delta):
	if is_complete:
		velocity.x = lerp(velocity.x, 0, friction)

	velocity.y += gravity * delta

	var up_direction = Vector2.UP
	var stop_on_slope = false
	var max_slides = 4
	var floor_max_angle = PI/4
	var infinite_inertia = false
	if not jump_was_pressed and is_stepping_on_other_player:
		var snap = Vector2.DOWN * 24
		velocity = move_and_slide_with_snap(velocity, snap, up_direction, stop_on_slope, max_slides, floor_max_angle, infinite_inertia)
	else:
		velocity = move_and_slide(velocity, up_direction, stop_on_slope, max_slides, floor_max_angle, infinite_inertia)

func handle_jumping(delta):
	if input_jump:
		is_stepping_on_other_player = false
		other_player.is_stepped_on = false
		jump_was_pressed = true
		buffered_jump_time()

	if is_on_floor():
		if was_in_air:
			was_in_air = false
			# Workaround to not play sound and create dust right after merge/unmerge
			if not has_just_frozen_unfrozen():
				play_footstep(-12 + min(9 * air_time/0.5, 12))
				create_foot_dust()
			reset_walk_sound_timer()

		if not was_grounded:
			coyote_time()
		was_grounded = true

	if is_in_air():
		air_time += delta
		was_in_air = true
	else:
		if air_time > 0.5:
			if not is_camera_frozen:
				camera.shake(air_time * 0.7)
		air_time = 0

	if jump_was_pressed and was_grounded:
		do_jump()

func do_jump():
	was_in_air = true
	$BufferedJumpTimer.stop()
	jump_was_pressed = false
	$CoyoteTimeTimer.stop()
	was_grounded = false
	velocity.y = -jump_speed
	$AnimatedSprite.play("jump")

func buffered_jump_time():
	$BufferedJumpTimer.stop()
	$BufferedJumpTimer.start()

func _on_BufferedJumpTimer_timeout():
	jump_was_pressed = false

func coyote_time():
	$CoyoteTimeTimer.stop()
	$CoyoteTimeTimer.start()

func _on_CoyoteTimeTimer_timeout():
	was_grounded = false

func handle_collisions():
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider is RigidBody2D:
			collision.collider.apply_central_impulse(-collision.normal * push_strength)

func handle_animation(_delta):
	if not is_complete:
		if not is_on_floor() and not is_stepping_on_other_player:
			if is_in_air():
				# Workaround to not change animation right after merge/unmerge
				if not has_just_frozen_unfrozen():
					$AnimatedSprite.play("fall")
			else:
				$AnimatedSprite.play("jump")
		elif is_walking():
			$AnimatedSprite.play("walk")
		else:
			$AnimatedSprite.play("idle")

		if direction in [DIRECTION_RIGHT, DIRECTION_NEUTRAL]:
			$AnimatedSprite.flip_h = false
			$AnimatedSprite.offset.x = 0
		elif direction == DIRECTION_LEFT:
			$AnimatedSprite.flip_h = true
			$AnimatedSprite.offset.x = 14

	handle_split_particles()

func is_in_air():
	return not is_on_floor() and not is_stepping_on_other_player and velocity.y > 0

func is_walking():
	return (abs(velocity.x) > acceleration/2 or input_x != 0) and is_on_floor()

func _on_SaltRemoverArea_area_entered(area):
	if area.name == "SaltRemovalArea2" and not is_complete:
		if is_instance_valid(salt_remover):
			if salt_remover.is_active:
				$RemoveSaltSound.play()
				remove_salt()
				if salt_remover and salt_remover.is_active:
					salt_remover.destroy()
				if is_instance_valid(salt_remover.clone):
					if salt_remover.clone.is_active:
						salt_remover.clone.destroy()

func _on_ConnectArea_area_entered(area):
	if area.name == "ConnectArea1" and not is_complete and not has_salt:
		var completed_levels = Global.completed_levels
		completed_levels[level_index] = true
		Global.completed_levels = completed_levels
		is_complete = true
		Engine.time_scale = 0.5

		if level_index == Global.ENDING_LEVEL:
			$AnimatedSprite.play("complete")
		else:
			$AnimatedSprite.play("complete")

		$AnimatedSprite.scale = Vector2(1, 1)
		$AnimatedSprite.offset.y = 16
		other_player.visible = false
		if other_player.direction in [DIRECTION_RIGHT, DIRECTION_NEUTRAL]:
			$AnimatedSprite.flip_h = false
			$AnimatedSprite.offset.x = 4
		elif other_player.direction == DIRECTION_LEFT:
			$AnimatedSprite.flip_h = true
			$AnimatedSprite.offset.x = 10

		if level_index != Global.ENDING_LEVEL:
			$CompleteSound.play()

		if ProjectSettings.get("effects/chromatic_aberration_on_reunite"):
			$AnimatedSprite.material.set_shader_param("apply", true)
			$CompleteTween.interpolate_property($AnimatedSprite.material, "shader_param/amount_y", 20, 0, 1.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		$CompleteTween.interpolate_property(self, "scale", Vector2(1.4, 1.4), Vector2(1, 1), 1.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		$CompleteTween.start()
		
		if shake_on_reunite_enabled:
			camera.shake(0.5)
			other_player.camera.shake(0.5)
		
		$CompleteParticles.emitting = true
		$CompleteParticles.one_shot = true
		$CompleteParticles.restart()

		$CompleteTimer.start()

func _on_CompleteTimer_timeout():
	if level_index == Global.ENDING_LEVEL:
		$AnimatedSprite.play("complete_split")
		$AnimatedSprite.speed_scale = 1.0 / Engine.time_scale
		$YouCompleteMeSound.play()
		yield($YouCompleteMeSound, "finished")
	
	level_container.fade_out_split_particles()

	level_complete_view.visible = true
	if level_index == Global.ENDING_LEVEL:
		level_complete_view.get_node("Label").text = "Thanks for Playing!"
		level_complete_view.get_node("SubLabel").text = "Press Enter to play again"
	level_complete_view.get_node("AnimationPlayer").playback_speed = 1.0 / Engine.time_scale
	level_complete_view.get_node("AnimationPlayer").play("Darken")
