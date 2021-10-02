extends RigidBody2D

var duration = 2.0
var elapsed = 0

func _physics_process(delta):
	if elapsed < duration:
		elapsed += delta
		modulate = Color(1, 1, 1, 1.0 - (elapsed / duration))
	else:
		queue_free()
