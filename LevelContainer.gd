# LevelContainer
extends Node2D

onready var viewport1 = $SplitScreen/ViewportContainer1/Viewport1
onready var viewport2 = $SplitScreen/ViewportContainer2/Viewport2
onready var camera1 = $SplitScreen/ViewportContainer1/Viewport1/Camera1
onready var camera2 = $SplitScreen/ViewportContainer2/Viewport2/Camera2
onready var level_complete_view = $LevelCompleteView
onready var frozen_view = $FrozenView

var split_line_alpha = 1

var level = null
var split_line_color = null
var is_screen_split = true

func clamped_color(color):
	var adjusted_color = color
	adjusted_color.r = clamp(color.r, 0.0, 1.0)
	adjusted_color.g = clamp(color.g, 0.0, 1.0)
	adjusted_color.b = clamp(color.b, 0.0, 1.0)
	return adjusted_color

func _ready():
	split_line_color = ProjectSettings.get("effects/split_line_color")	
	$SplitLine.modulate = clamped_color(split_line_color)
	$SplitParticles.modulate = clamped_color(split_line_color)
	$SplitParticles2.modulate = split_line_color

	$SplitParticles.visible = false
	$SplitParticles.emitting = false
	$SplitParticles2.visible = false
	$SplitParticles2.emitting = false

	var level_number = Global.next_level
	level = Global.levels[level_number].instance()
	viewport1.call_deferred("add_child", level)
	
	$SplitParticles.emitting = false
	$SplitParticles.one_shot = true

	viewport2.world_2d = viewport1.world_2d
	var player1 = level.get_node("Player1")
	var player2 = level.get_node("Player2")
	
	camera1.target = player1
	camera1.position = player1.position
	camera2.target = player2
	camera2.position = player2.position

	player1.camera = camera1
	player1.other_player = player2
	player1.frozen_view = frozen_view
	
	player2.camera = camera2
	player2.other_player = player1
	player2.frozen_view = frozen_view
	
	player2.level_index = Global.ENDING_LEVEL if level_number == Global.ENDING_LEVEL else level_number - 1
	player2.level_container = self
	player2.level_complete_view = level_complete_view
	level_complete_view.get_node("AnimationPlayer").play("Lighten")

func unsplit_screen():
	is_screen_split = false
	$SplitLine.visible = true

	$SplitParticles2.emitting = true
	$SplitParticles2.visible = true
	$SplitParticles2.restart()

	$SplitTween.interpolate_property($SplitLine, "scale", Vector2(1, 1), Vector2(1, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	var adjusted_color = clamped_color(split_line_color)
	$SplitTween.interpolate_property($SplitLine, "modulate", Color(adjusted_color.r, adjusted_color.g, adjusted_color.b, split_line_alpha), Color(adjusted_color.r, adjusted_color.g, adjusted_color.b, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$SplitTween.start()

	yield(get_tree().create_timer(0.1), "timeout")
	if is_instance_valid(self):
		$SplitParticles.visible = true
		$SplitParticles.emitting = true
		$SplitParticles.lifetime = 1.25
		$SplitParticles.process_material.gravity = Vector3(0, 98, 0)
		$SplitParticles.process_material.initial_velocity = 360
		$SplitParticles.process_material.scale = 0.05
		$SplitParticles.restart()

func split_screen():
	is_screen_split = true
	$SplitLine.visible = true
		
	$SplitParticles2.visible = false
	$SplitParticles2.emitting = false
	
	$SplitTween.interpolate_property($SplitLine, "scale", Vector2(1, 0), Vector2(1, 1), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	var adjusted_color = clamped_color(split_line_color)
	$SplitTween.interpolate_property($SplitLine, "modulate", Color(adjusted_color.r, adjusted_color.g, adjusted_color.b, 0), Color(adjusted_color.r, adjusted_color.g, adjusted_color.b, split_line_alpha), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$SplitTween.start()
	
	yield(get_tree().create_timer(0.1), "timeout")
	if is_instance_valid(self):
		$SplitParticles.visible = true
		$SplitParticles.emitting = true
		$SplitParticles.lifetime = 1.0
		$SplitParticles.process_material.gravity = Vector3.ZERO
		$SplitParticles.process_material.initial_velocity = 0
		$SplitParticles.process_material.scale = 0.1
		$SplitParticles.process_material.radial_accel = 30
		$SplitParticles.restart()

func fade_out_split_particles():
	$SplitTween.interpolate_property($SplitParticles2, "modulate", Color(split_line_color.r, split_line_color.g, split_line_color.b, split_line_alpha), Color(split_line_color.r, split_line_color.g, split_line_color.b, 0), 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$SplitTween.start()

func go_to_next_level():
	var has_played_ending = Global.has_played_ending
	if not has_played_ending:
		var completed_levels = Global.completed_levels
		var all_completed = true
		for i in Global.MAX_LEVEL:
			if not completed_levels[i]:
				all_completed = false
				break
		if all_completed:
			Global.all_completed = true
			go_to_ending()
			return

	var current_level_number = Global.next_level
	var next_level_number = current_level_number + 1
	if next_level_number > Global.MAX_LEVEL or current_level_number == Global.ENDING_LEVEL:
		Global.next_level = 1
		if get_tree().change_scene("res://TitleScreen.tscn") != OK:
			print ("An unexpected error occured when trying to switch to the TitleScreen scene")
	else:
		Global.next_level = next_level_number
		if get_tree().change_scene("res://LevelContainer.tscn") != OK:
			print ("An unexpected error occured when trying to switch to the LevelContainer scene")

func _on_SplitTween_tween_all_completed():
	$SplitLine.visible = is_screen_split

func go_to_ending():
	Global.next_level = Global.ENDING_LEVEL
	if get_tree().change_scene("res://LevelContainer.tscn") != OK:
		print ("An unexpected error occured when trying to switch to the LevelContainer scene")
