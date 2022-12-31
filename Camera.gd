# Camera
extends Camera2D

var target = null
var original_offset = Vector2.ZERO

# From https://kidscancode.org/godot_recipes/2d/screen_shake
export var decay = 0.8
export var max_offset = Vector2(100, 50)
export var max_roll = 0.1
var trauma = 0.0
var trauma_power = 2
onready var noise = OpenSimplexNoise.new()
var noise_y = 0

func _ready():
	original_offset = offset
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

func _physics_process(delta):
	if not smoothing_enabled:
		smoothing_enabled = true

	if target:
		position = target.position

	if trauma > 0.0:
		trauma = max(trauma - decay * delta, 0)
		var amount = pow(trauma, trauma_power)
		noise_y += 1
		rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
		offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
		offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)
	
func shake(amount):
	trauma = min(trauma + amount, 1.0)

func stop_shake():
	trauma = 0.0
	offset = original_offset
