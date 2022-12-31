# BackgroundMusic
extends Node

onready var audio_player = $AudioStreamPlayer
var should_play = true
var play_position = 0
var is_ending = false

const volume_db = -12

func _ready():
	$AudioStreamPlayer.volume_db = volume_db
	$AudioStreamPlayer2.volume_db = volume_db

func set_is_ending(value):
	is_ending = value
	if audio_player.playing:
		audio_player.stop()
		yield(audio_player, "finished")
	if is_ending:
		audio_player = $AudioStreamPlayer2
	else:
		audio_player = $AudioStreamPlayer
	if should_play:
		audio_player.volume_db = volume_db
		audio_player.play()
	else:
		play_position = 0
		audio_player.stop()

func _process(_delta):
	if Input.is_action_just_pressed("toggle_music"):
		if audio_player.playing:
			pause()
			should_play = false
		else:
			resume()
			should_play = true

func maybe_pause():
	if should_play:
		pause()

func pause():
	play_position = audio_player.get_playback_position()
	do_stop()

func maybe_resume():
	if should_play:
		audio_player.volume_db = volume_db
		resume()

func resume():
	audio_player.volume_db = volume_db
	audio_player.play(play_position)

func stop():
	do_stop()

func do_stop():
	if audio_player.playing:
		audio_player.stop()
