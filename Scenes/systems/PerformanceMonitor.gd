class_name PerformanceMonitor
extends Node

## Performance Monitor for Tower Defense Enhancement System
## Tracks FPS, entity counts, and system performance metrics

signal performance_warning(metric: String, current_value: float, threshold: float)
signal performance_critical(metric: String, current_value: float)

# Performance targets and thresholds
const TARGET_FPS = 60.0
const WARNING_FPS = 45.0
const CRITICAL_FPS = 30.0
const MAX_TOWERS = 20
const MAX_MONSTERS = 50
const MAX_PROJECTILES = 100

# Monitoring variables
var fps_history: Array[float] = []
var fps_history_size = 30  # Track last 30 frames
var update_interval = 1.0
var update_timer = 0.0

# Current metrics
var current_fps = 0.0
var current_tower_count = 0
var current_monster_count = 0
var current_projectile_count = 0
var memory_usage_mb = 0.0

# Performance optimization flags
var performance_mode_enabled = false
var visual_effects_reduced = false
var update_frequency_reduced = false

func _ready():
	set_process(true)
	print("PerformanceMonitor initialized - Target: %d towers + %d monsters @ %d FPS" % [MAX_TOWERS, MAX_MONSTERS, TARGET_FPS])

func _process(delta):
	update_timer += delta
	
	# Update FPS tracking
	current_fps = Engine.get_frames_per_second()
	update_fps_history(current_fps)
	
	if update_timer >= update_interval:
		update_timer = 0.0
		update_performance_metrics()
		check_performance_thresholds()

## Update FPS history for smooth averaging
func update_fps_history(fps: float):
	fps_history.append(fps)
	if fps_history.size() > fps_history_size:
		fps_history.remove_at(0)

## Get average FPS over the history window
func get_average_fps() -> float:
	if fps_history.is_empty():
		return 0.0
	
	var sum = 0.0
	for fps in fps_history:
		sum += fps
	return sum / fps_history.size()

## Update all performance metrics
func update_performance_metrics():
	# Update entity counts
	current_tower_count = count_deployed_towers()
	current_monster_count = count_active_monsters()
	current_projectile_count = count_active_projectiles()
	
	# Update memory usage
	memory_usage_mb = OS.get_static_memory_usage() / (1024.0 * 1024.0)
	
	# Log performance data (can be disabled in release)
	if OS.is_debug_build():
		print_performance_stats()

## Count deployed towers in the scene
func count_deployed_towers() -> int:
	var count = 0
	# Use group-based approach for better flexibility
	var turret_nodes = get_tree().get_nodes_in_group("turret")
	for turret in turret_nodes:
		if turret is Turret and turret.deployed:
			count += 1
	return count

## Count active monsters in the scene
func count_active_monsters() -> int:
	var enemies = get_tree().get_nodes_in_group("enemy")
	return enemies.size()

## Count active projectiles in the scene
func count_active_projectiles() -> int:
	var count = 0
	var projectiles_node = get_tree().current_scene.get_node_or_null("Projectiles")
	if projectiles_node:
		count = projectiles_node.get_child_count()
	return count

## Check performance thresholds and trigger warnings
func check_performance_thresholds():
	var avg_fps = get_average_fps()
	
	# FPS warnings
	if avg_fps < CRITICAL_FPS:
		performance_critical.emit("FPS", avg_fps)
		enable_emergency_performance_mode()
	elif avg_fps < WARNING_FPS:
		performance_warning.emit("FPS", avg_fps, WARNING_FPS)
		enable_performance_optimizations()
	
	# Entity count warnings
	if current_tower_count > MAX_TOWERS:
		performance_warning.emit("Tower Count", current_tower_count, MAX_TOWERS)
	
	if current_monster_count > MAX_MONSTERS:
		performance_warning.emit("Monster Count", current_monster_count, MAX_MONSTERS)
	
	if current_projectile_count > MAX_PROJECTILES:
		performance_warning.emit("Projectile Count", current_projectile_count, MAX_PROJECTILES)
		limit_projectiles()

## Enable performance optimizations when FPS drops
func enable_performance_optimizations():
	if performance_mode_enabled:
		return
		
	performance_mode_enabled = true
	print("Performance mode enabled - reducing visual effects")
	
	# Reduce visual effects
	reduce_visual_effects()
	
	# Reduce update frequencies
	reduce_update_frequencies()

## Enable emergency performance mode for critical FPS drops
func enable_emergency_performance_mode():
	if visual_effects_reduced:
		return
		
	visual_effects_reduced = true
	print("Emergency performance mode - disabling non-essential effects")
	
	# Disable particle effects
	disable_particle_effects()
	
	# Reduce monster skill effect frequency
	reduce_monster_skill_frequency()
	
	# Limit concurrent effects
	limit_concurrent_effects()

## Reduce visual effects for better performance
func reduce_visual_effects():
	# Reduce DA/TA visual effect duration
	var all_towers = get_deployed_towers()
	for tower in all_towers:
		if tower.has_method("set_effect_quality"):
			tower.set_effect_quality(0.5)  # 50% quality

## Reduce update frequencies for non-critical systems
func reduce_update_frequencies():
	if update_frequency_reduced:
		return
		
	update_frequency_reduced = true
	
	# Reduce PassiveSynergyManager update frequency
	var synergy_manager = get_tree().current_scene.get_node_or_null("PassiveSynergyManager")
	if synergy_manager and synergy_manager.has_method("set_update_interval"):
		synergy_manager.set_update_interval(2.0)  # Update every 2 seconds instead of 1

## Disable particle effects system-wide
func disable_particle_effects():
	# This would disable particle systems if they exist
	var particle_nodes = get_tree().get_nodes_in_group("particles")
	for particle in particle_nodes:
		if particle.has_method("set_emitting"):
			particle.set_emitting(false)

## Reduce monster skill effect frequency
func reduce_monster_skill_frequency():
	var monster_skill_system = get_tree().current_scene.get_node_or_null("MonsterSkillSystem")
	if monster_skill_system and monster_skill_system.has_method("set_max_concurrent_effects"):
		monster_skill_system.set_max_concurrent_effects(5)  # Reduce from 10 to 5

## Limit concurrent effects for performance
func limit_concurrent_effects():
	var monster_skill_system = get_tree().current_scene.get_node_or_null("MonsterSkillSystem")
	if monster_skill_system:
		monster_skill_system.max_concurrent_effects = min(monster_skill_system.max_concurrent_effects, 5)

## Limit projectiles by removing oldest ones
func limit_projectiles():
	var projectiles_node = get_tree().current_scene.get_node_or_null("Projectiles")
	if not projectiles_node:
		return
		
	var projectiles = projectiles_node.get_children()
	if projectiles.size() > MAX_PROJECTILES:
		var excess_count = projectiles.size() - MAX_PROJECTILES
		# Remove oldest projectiles
		for i in range(excess_count):
			if i < projectiles.size() and is_instance_valid(projectiles[i]):
				projectiles[i].queue_free()

## Get all deployed towers
func get_deployed_towers() -> Array:
	var towers: Array = []
	# Use group-based approach for better flexibility
	var turret_nodes = get_tree().get_nodes_in_group("turret")
	for turret in turret_nodes:
		if turret is Turret and turret.deployed:
			towers.append(turret)
	return towers

## Print performance statistics (debug only)
func print_performance_stats():
	print("=== Performance Stats ===")
	print("FPS: %.1f (avg: %.1f)" % [current_fps, get_average_fps()])
	print("Towers: %d/%d" % [current_tower_count, MAX_TOWERS])
	print("Monsters: %d/%d" % [current_monster_count, MAX_MONSTERS])
	print("Projectiles: %d/%d" % [current_projectile_count, MAX_PROJECTILES])
	print("Memory: %.1f MB" % memory_usage_mb)
	print("Performance Mode: %s" % ("ON" if performance_mode_enabled else "OFF"))
	print("=======================")

## Get current performance metrics as dictionary
func get_performance_metrics() -> Dictionary:
	return {
		"fps": current_fps,
		"avg_fps": get_average_fps(),
		"tower_count": current_tower_count,
		"monster_count": current_monster_count,
		"projectile_count": current_projectile_count,
		"memory_mb": memory_usage_mb,
		"performance_mode": performance_mode_enabled,
		"meets_target": get_average_fps() >= WARNING_FPS and current_tower_count <= MAX_TOWERS and current_monster_count <= MAX_MONSTERS
	}

## Check if performance targets are being met
func meets_performance_targets() -> bool:
	var metrics = get_performance_metrics()
	return metrics.meets_target

## Reset performance optimizations (when performance improves)
func reset_performance_optimizations():
	if not performance_mode_enabled:
		return
		
	var avg_fps = get_average_fps()
	if avg_fps >= TARGET_FPS:
		performance_mode_enabled = false
		visual_effects_reduced = false
		update_frequency_reduced = false
		print("Performance mode disabled - FPS restored")
		
		# Re-enable effects
		restore_visual_effects()

## Restore visual effects when performance improves
func restore_visual_effects():
	# Re-enable particle effects
	var particle_nodes = get_tree().get_nodes_in_group("particles")
	for particle in particle_nodes:
		if particle.has_method("set_emitting"):
			particle.set_emitting(true)
	
	# Restore PassiveSynergyManager update frequency
	var synergy_manager = get_tree().current_scene.get_node_or_null("PassiveSynergyManager")
	if synergy_manager and synergy_manager.has_method("set_update_interval"):
		synergy_manager.set_update_interval(1.0)  # Back to 1 second updates
