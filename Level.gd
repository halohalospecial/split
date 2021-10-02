# Level
extends Node2D

onready var player1 = $Player1
onready var player2 = $Player2

func _ready():
	player1.reset()
	player2.reset()

func _physics_process(_delta):
	if Input.is_action_just_pressed("go_to_title"):
		if get_tree().change_scene("res://TitleScreen.tscn") != OK:
			print ("An unexpected error occured when trying to switch to the title screen scene")
	elif Input.is_action_just_pressed("restart_level"):
		if get_tree().reload_current_scene() != OK:
			print ("An unexpected error occured when trying to reload current scene")
