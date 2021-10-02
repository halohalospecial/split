# Dust
extends Particles2D

var elapsed = 0

func _ready():
	emitting = true
	one_shot = true

func _process(delta):
	elapsed += delta
	if elapsed > lifetime:
		queue_free()
