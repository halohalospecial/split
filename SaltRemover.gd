# SaltRemover
extends Sprite

var original_position = null
var initial_frozen_position = null
var clone = null
var is_active = true

func destroy():
	if is_active:
		is_active = false
		$AnimationPlayer.play("Destroy")
