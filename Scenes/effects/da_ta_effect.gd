extends Node2D
class_name DATAEffect

## Visual effect for Double Attack (DA) and Triple Attack (TA) 
## Shows enhanced projectile trails and visual feedback

var effect_duration: float = 1.0
var effect_type: String = "DA"  # "DA" or "TA"

func _ready():
	setup_visual_effect()
	# Auto-remove after duration
	get_tree().create_timer(effect_duration).timeout.connect(queue_free)

func setup_visual_effect():
	match effect_type:
		"DA":
			modulate = Color(1, 1, 0)
			scale = Vector2(1.2, 1.2)
		"TA":
			modulate = Color(1, 0, 0)
			scale = Vector2(1.5, 1.5)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", scale * 1.5, effect_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, effect_duration)

func set_effect_type(type: String):
	effect_type = type
	if is_node_ready():
		setup_visual_effect()