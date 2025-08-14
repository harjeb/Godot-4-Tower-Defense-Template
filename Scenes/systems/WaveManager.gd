class_name WaveManager
extends Node

## Wave Manager System for controlling wave flow and countdown
## Handles wave countdown, manual start, tech point rewards

signal wave_countdown_started(countdown_time: float)
signal wave_countdown_updated(remaining_time: float)
signal wave_start_requested()
signal wave_completed(wave_number: int, tech_points_earned: int)
signal all_waves_completed()

var default_countdown_time: float = 30.0
var current_countdown_time: float = 0.0
var is_counting_down: bool = false
var is_wave_active: bool = false
var current_wave: int = 0
var countdown_timer: Timer

var tech_point_system: Node

func _ready():
	setup_countdown_timer()
	find_tech_point_system()
	
	# Connect to global wave events if available
	if Globals.has_signal("waveStarted"):
		Globals.waveStarted.connect(_on_wave_started)
	if Globals.has_signal("waveCleared"):
		Globals.waveCleared.connect(_on_wave_cleared)

func setup_countdown_timer():
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0  # Update every second
	countdown_timer.autostart = false
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)

func find_tech_point_system():
	tech_point_system = get_tree().current_scene.get_node_or_null("TechPointSystem")

## Start wave countdown
func start_wave_countdown():
	if is_wave_active or is_counting_down:
		return
	
	# Apply wave preparation talent bonus
	var base_time = default_countdown_time
	var bonus_time = Globals.get("wave_preparation_bonus") if Globals.has_method("get") else 0.0
	current_countdown_time = base_time + bonus_time
	
	is_counting_down = true
	countdown_timer.start()
	wave_countdown_started.emit(current_countdown_time)

## Manual start wave (skip countdown)
func start_wave_immediately():
	if not is_counting_down:
		return
	
	stop_countdown()
	request_wave_start()

## Stop countdown
func stop_countdown():
	is_counting_down = false
	countdown_timer.stop()
	current_countdown_time = 0.0

## Request wave to start
func request_wave_start():
	if is_wave_active:
		return
	
	is_wave_active = true
	wave_start_requested.emit()
	
	# Trigger wave start in game systems
	if Globals.has_method("start_next_wave"):
		Globals.start_next_wave()

## Handle countdown tick
func _on_countdown_tick():
	if not is_counting_down:
		return
	
	current_countdown_time -= 1.0
	wave_countdown_updated.emit(current_countdown_time)
	
	if current_countdown_time <= 0:
		stop_countdown()
		request_wave_start()

## Called when wave actually starts
func _on_wave_started(wave_number: int, enemy_count: int):
	current_wave = wave_number
	is_wave_active = true

## Called when wave is completed
func _on_wave_cleared(wait_time: float):
	is_wave_active = false
	
	# Award tech points (1 point per wave completed)
	var tech_points_earned = 1
	if tech_point_system:
		tech_point_system.award_tech_points(tech_points_earned)
	
	wave_completed.emit(current_wave, tech_points_earned)
	
	# Check if this was the last wave
	var current_map_data = Data.maps.get(Globals.selected_map) if Data.maps.has(Globals.selected_map) else {}
	var spawner_settings = current_map_data.get("spawner_settings") if current_map_data.has("spawner_settings") else {}
	var max_waves = spawner_settings.get("max_waves") if spawner_settings.has("max_waves") else 10
	
	if current_wave >= max_waves:
		all_waves_completed.emit()
	else:
		# Start countdown for next wave
		call_deferred("start_wave_countdown")

## Get current countdown status
func get_countdown_status() -> Dictionary:
	return {
		"is_counting_down": is_counting_down,
		"remaining_time": current_countdown_time,
		"is_wave_active": is_wave_active,
		"current_wave": current_wave
	}

## Check if we can start the next wave manually
func can_start_wave_manually() -> bool:
	return is_counting_down and not is_wave_active