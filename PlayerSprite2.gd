# PlayerSprite2
extends AnimatedSprite

var is_trail = false setget set_is_trail, get_is_trail
var tween = null

func set_is_trail(value):
	if is_trail == false and value == true:
		tween = Tween.new()
		add_child(tween)
		var r = 44/255
		var g = 107/255
		var b = 116/255
		tween.interpolate_property(self, "modulate", Color(1, 1, 1, 0.8), Color(r, g, b, 0), 1.0, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_all_completed")
		queue_free()
		
	elif is_trail == true and value == false:
		tween.stop()
		tween = null

	is_trail = value

func get_is_trail():
	return is_trail
