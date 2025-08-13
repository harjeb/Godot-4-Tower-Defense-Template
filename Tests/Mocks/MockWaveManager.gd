extends Node
class_name MockWaveManager

## Mock Wave Manager for testing
## Simulates wave manager functionality

var current_wave: int = 1
var max_waves: int = 50
var wave_in_progress: bool = false
var enemies_spawned: int = 0
var enemies_defeated: int = 0

func _ready():
	pass

func start_wave(wave_number: int):
	"""Start a specific wave"""
	current_wave = wave_number
	wave_in_progress = true
	enemies_spawned = 0
	enemies_defeated = 0

func complete_wave():
	"""Complete current wave"""
	wave_in_progress = false

func get_current_wave() -> int:
	"""Get current wave number"""
	return current_wave

func is_wave_complete() -> bool:
	"""Check if current wave is complete"""
	return not wave_in_progress and enemies_spawned > 0

func get_wave_progress() -> float:
	"""Get wave completion progress"""
	if enemies_spawned == 0:
		return 0.0
	return float(enemies_defeated) / float(enemies_spawned)

func spawn_enemy_count(count: int):
	"""Simulate spawning enemies"""
	enemies_spawned += count

func defeat_enemy_count(count: int):
	"""Simulate defeating enemies"""
	enemies_defeated += count

func reset():
	"""Reset wave manager state"""
	current_wave = 1
	wave_in_progress = false
	enemies_spawned = 0
	enemies_defeated = 0