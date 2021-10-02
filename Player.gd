# Player
extends KinematicBody2D
const FootDust = preload("res://FootDust.tscn")
const TileDust = preload("res://TileDust.tscn")

const DIRECTION_NEUTRAL = 0
const DIRECTION_LEFT = -1
const DIRECTION_RIGHT = 1

export (bool) var is_interactive = true
export (int, -1, 1) var initial_direction = DIRECTION_NEUTRAL
export (bool) var has_light = true

const CENTER_X = 300
const SPLIT_Y = 300
const HALF_SPLIT_HEIGHT = SPLIT_Y / 2
const THREE_QUARTERS_SPLIT_HEIGHT = SPLIT_Y + HALF_SPLIT_HEIGHT

var direction = initial_direction
var is_camera_frozen = false
var is_complete = false
var velocity = Vector2.ZERO
var original_position = null
var initial_frozen_position = null

var world = null
var camera = null
var other_player = null
var frozen_view = null
var frozen_colliders = null

# For foot dust
var walk_dust_every = 0
var walk_dust_timer = 0

# For wall dust
var wall_dust_enabled = ProjectSettings.get("effects/wall_dust")

# For merge/unmerge
var split_previous_y = Vector2.ZERO
var freeze_unfreeze_time = 0

var player_light_enabled = ProjectSettings.get("effects/player_light")
var shake_on_merge_screen_enabled = ProjectSettings.get("effects/shake_on_merge_screen")

func _ready():
	$PlayerLight.visible = player_light_enabled
	$PlayerLight.enabled = has_light
	$PlayerSplitParticles.modulate = ProjectSettings.get("effects/split_line_color")
	$PlayerSplitParticles.emitting = false
	$PlayerSplitParticles.one_shot = true
	freeze_unfreeze_time = OS.get_ticks_msec()
	split_previous_y = position.y

func handle_split_particles():
	if is_camera_frozen and not has_just_frozen_unfrozen() and ((split_previous_y > SPLIT_Y and position.y <= SPLIT_Y) or (split_previous_y <= SPLIT_Y and position.y > SPLIT_Y)):
		$PlayerSplitParticles.position = Vector2(0, split_previous_y - SPLIT_Y)
		$PlayerSplitParticles.visible = true
		$PlayerSplitParticles.emitting = true
		$PlayerSplitParticles.restart()
	split_previous_y = position.y

func has_just_frozen_unfrozen():
	return OS.get_ticks_msec() < freeze_unfreeze_time + 61

func remove_frozen_colliders():
	frozen_view.remove_child(frozen_colliders)
	frozen_colliders.queue_free()

func create_foot_dust(offset_x = 0, offset_y = 0):
	if get_parent():
		var dust = FootDust.instance()
		dust.z_index = z_index
		dust.position = global_position + Vector2(offset_x, offset_y)
		get_parent().call_deferred("add_child", dust)

func create_tile_dust(offset_x = 0, offset_y = 0):
	if wall_dust_enabled:
		if get_parent():
			var dust = TileDust.instance()
			dust.z_index = z_index
			dust.position = global_position + Vector2(offset_x, offset_y)
			get_parent().call_deferred("add_child", dust)

func reset_walk_dust_timer():
	walk_dust_timer = 0
	walk_dust_every = rand_range(0.2, 0.6)
