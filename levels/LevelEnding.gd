# LevelEnding
extends "res://Level.gd"

var play_position = 0

func _enter_tree():
	BackgroundMusic.set_is_ending(true)

func _exit_tree():
	BackgroundMusic.set_is_ending(false)
