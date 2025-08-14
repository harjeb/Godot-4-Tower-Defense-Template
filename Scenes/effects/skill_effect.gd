extends Node2D
class_name SkillEffect

## Basic skill effect for monster skills
## This is a placeholder that can be enhanced with proper visual effects

var effect_type: String = ""
var duration: float = 1.0
var remaining_time: float = 0.0

func _ready():
	remaining_time = duration
	set_process(true)

func _process(delta):
	remaining_time -= delta
	if remaining_time <= 0:
		queue_free()

func setup_effect(type: String, duration_time: float):
	effect_type = type
	duration = duration_time
	remaining_time = duration_time
	
	# Basic visual setup based on effect type
	match type:
		"frost":
			modulate = Color(0, 1, 1)
		"acceleration":
			modulate = Color(1, 1, 0)
		"explosion":
			modulate = Color(1, 0.5, 0)
		"petrification":
			modulate = Color(0.5, 0.5, 0.5)