# TitleScreen
extends Node2D

onready var buttons1 = $Buttons/VBoxContainer
onready var buttons2 = $Buttons/VBoxContainer2
onready var buttons3 = $Buttons/VBoxContainer3
onready var buttons4 = $Buttons/VBoxContainer4
onready var buttons5 = $Buttons/VBoxContainer5

const ENDING_LEVEL = -1

func _ready():
	$EndingButton.visible = Global.all_completed
	$EndingButton.disabled = not $EndingButton.visible
	
	var completed_levels = Global.completed_levels
	if completed_levels:
		for i in Global.MAX_LEVEL:
			set_button_color(get_level_button(i+1), completed_levels[i])
		set_button_color(get_level_button(Global.ENDING_LEVEL), completed_levels[Global.ENDING_LEVEL])
	else:
		completed_levels = {}
		for i in Global.MAX_LEVEL:
			completed_levels[i] = false
		completed_levels[Global.ENDING_LEVEL] = false
		Global.completed_levels = completed_levels
	var next_level = Global.next_level
	if next_level > Global.MAX_LEVEL or next_level == ENDING_LEVEL:
		next_level = 1
	get_level_button(next_level).grab_focus()

func set_button_color(button, is_completed):
		button.modulate = Color(103/255.0, 237/255.0, 255/255.0, 1.0) if is_completed else Color(1, 1, 1, 1)

func get_level_button(level):
	if level == Global.ENDING_LEVEL:
		return $EndingButton
	elif level >= 1 and level < 6:
		return buttons1.get_node("Button" + str(level))
	elif level >= 6 and level < 11:
		return buttons2.get_node("Button" + str(level))
	elif level >= 11 and level < 16:
		return buttons3.get_node("Button" + str(level))
	elif level >= 16 and level < 21:
		return buttons4.get_node("Button" + str(level))
	else:
		return buttons5.get_node("Button" + str(level))

func _unhandled_key_input(_event):
	if Input.is_key_pressed(KEY_DOWN):
		if $Buttons/VBoxContainer/Button5.has_focus():
			buttons2.get_node("Button6").grab_focus()
		elif $Buttons/VBoxContainer2/Button10.has_focus():
			buttons3.get_node("Button11").grab_focus()
		elif $Buttons/VBoxContainer3/Button15.has_focus():
			buttons4.get_node("Button16").grab_focus()
		elif $Buttons/VBoxContainer4/Button20.has_focus():
			if Global.MAX_LEVEL == 20:
				buttons1.get_node("Button1").grab_focus()
			else:
				buttons5.get_node("Button21").grab_focus()
		elif $Buttons/VBoxContainer5/Button25.has_focus():
			buttons1.get_node("Button1").grab_focus()
	elif Input.is_key_pressed(KEY_UP):
		if $Buttons/VBoxContainer/Button1.has_focus():
			if Global.MAX_LEVEL == 20:
				buttons4.get_node("Button20").grab_focus()
			else:
				buttons5.get_node("Button25").grab_focus()
		elif $Buttons/VBoxContainer2/Button6.has_focus():
			buttons1.get_node("Button5").grab_focus()
		elif $Buttons/VBoxContainer3/Button11.has_focus():
			buttons2.get_node("Button10").grab_focus()
		elif $Buttons/VBoxContainer4/Button16.has_focus():
			buttons3.get_node("Button15").grab_focus()
		elif $Buttons/VBoxContainer5/Button21.has_focus():
			buttons4.get_node("Button20").grab_focus()

func go_to_level(level):
	Global.next_level = level
	if get_tree().change_scene("res://LevelContainer.tscn") != OK:
		print ("An unexpected error occured when trying to switch to the LevelContainer scene")

func _on_Button1_pressed():
	go_to_level(1)

func _on_Button2_pressed():
	go_to_level(2)

func _on_Button3_pressed():
	go_to_level(3)

func _on_Button4_pressed():
	go_to_level(4)

func _on_Button5_pressed():
	go_to_level(5)

func _on_Button6_pressed():
	go_to_level(6)

func _on_Button7_pressed():
	go_to_level(7)

func _on_Button8_pressed():
	go_to_level(8)

func _on_Button9_pressed():
	go_to_level(9)

func _on_Button10_pressed():
	go_to_level(10)
	
func _on_Button11_pressed():
	go_to_level(11)

func _on_Button12_pressed():
	go_to_level(12)

func _on_Button13_pressed():
	go_to_level(13)

func _on_Button14_pressed():
	go_to_level(14)

func _on_Button15_pressed():
	go_to_level(15)

func _on_Button16_pressed():
	go_to_level(16)

func _on_Button17_pressed():
	go_to_level(17)

func _on_Button18_pressed():
	go_to_level(18)

func _on_Button19_pressed():
	go_to_level(19)

func _on_Button20_pressed():
	go_to_level(20)

func _on_Button21_pressed():
	go_to_level(21)

func _on_Button22_pressed():
	go_to_level(22)

func _on_Button23_pressed():
	go_to_level(23)

func _on_Button24_pressed():
	go_to_level(24)

func _on_Button25_pressed():
	go_to_level(25)

func _on_EndingButton_pressed():
	go_to_level(-1)
