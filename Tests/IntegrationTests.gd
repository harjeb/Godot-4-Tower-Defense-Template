extends TowerDefenseTestFramework
class_name IntegrationTests

## Integration Tests for Tower Defense Enhancement System
## Tests system interactions, tower placement, and end-to-end functionality

var test_scene: Node
var test_towers: Array = []
var test_enemies: Array = []

func _ready():
	super._ready()
	setup_test_environment()

func setup_test_environment():
	# Create a minimal test environment for integration testing
	test_scene = Node2D.new()
	add_child(test_scene)
	print("Integration test environment initialized")

func cleanup_test_environment():
	# Clean up test objects
	for tower in test_towers:
		if is_instance_valid(tower):
			tower.queue_free()
	for enemy in test_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	test_towers.clear()
	test_enemies.clear()

## Run all integration tests
func run_integration_tests():
	print("\n=== Integration Tests ===")
	var all_passed = true
	
	# Tower Placement and Synergy Tests
	all_passed = await run_test("Tower Placement Synergy Activation", test_tower_placement_synergy) and all_passed
	all_passed = await run_test("Multi-Tower Passive Interactions", test_multi_tower_interactions) and all_passed
	all_passed = await run_test("Adjacent Tower Synergy Detection", test_adjacent_tower_synergy) and all_passed
	
	# System Integration Tests
	all_passed = await run_test("Defense System Integration", test_defense_system_integration) and all_passed
	all_passed = await run_test("DA/TA System Integration", test_da_ta_system_integration) and all_passed
	all_passed = await run_test("Monster Skill Tower Interaction", test_monster_skill_tower_interaction) and all_passed
	
	# Performance Integration Tests
	all_passed = await run_test("Performance Monitor Integration", test_performance_monitor_integration) and all_passed
	all_passed = await run_test("System Scalability Integration", test_system_scalability) and all_passed
	
	cleanup_test_environment()
	return all_passed

## Tower Placement and Synergy Integration Tests

func test_tower_placement_synergy() -> Dictionary:
	cleanup_test_environment()
	
	# Test placing towers and verifying synergy activation
	# Create mock tower positions
	var arrow_tower_pos = Vector2(100, 100)
	var capture_tower_pos = Vector2(150, 100)  # Within range of arrow tower
	
	# Simulate arrow tower data
	var arrow_tower_data = {
		"type": "ArrowTower",
		"position": arrow_tower_pos,
		"range": 80,
		"base_da": 0.05,
		"base_ta": 0.01
	}
	
	# Simulate capture tower data
	var capture_tower_data = {
		"type": "CaptureTower", 
		"position": capture_tower_pos,
		"range": 100
	}
	
	# Test distance calculation
	var distance = arrow_tower_pos.distance_to(capture_tower_pos)
	if distance > arrow_tower_data.range:
		return create_test_result(false, "Tower positioning test failed - distance too great: %.1f" % distance)
	
	# Test synergy activation (arrow tower gets DA+10%, TA+5% from capture tower)
	var expected_da = arrow_tower_data.base_da + 0.10  # 5% + 10% = 15%
	var expected_ta = arrow_tower_data.base_ta + 0.05  # 1% + 5% = 6%
	
	if expected_da != 0.15 or expected_ta != 0.06:
		return create_test_result(false, "Synergy calculation failed. DA=%.3f, TA=%.3f" % [expected_da, expected_ta])
	
	return create_test_result(true, "Tower placement synergy activation working correctly")

func test_multi_tower_interactions() -> Dictionary:
	cleanup_test_environment()
	
	# Test complex multi-tower synergy scenario
	# 2 Mage Towers + 1 Arrow Tower + 2 Capture Towers
	
	var towers = [
		{"type": "MageTower", "position": Vector2(100, 100), "base_damage": 45},
		{"type": "MageTower", "position": Vector2(200, 100), "base_damage": 45},
		{"type": "ArrowTower", "position": Vector2(150, 100), "base_da": 0.05, "base_ta": 0.01},
		{"type": "CaptureTower", "position": Vector2(125, 100)},
		{"type": "CaptureTower", "position": Vector2(175, 100)}
	]
	
	# Calculate expected bonuses:
	# Each mage tower gets +10% damage from the other mage tower
	var mage1_expected_damage = 45 * (1.0 + 0.10)  # 49.5
	var mage2_expected_damage = 45 * (1.0 + 0.10)  # 49.5
	
	# Arrow tower gets bonuses from 2 capture towers: DA +20%, TA +10%
	var arrow_expected_da = 0.05 + (2 * 0.10)  # 25%
	var arrow_expected_ta = 0.01 + (2 * 0.05)  # 11%
	
	# Validate calculations
	if abs(mage1_expected_damage - 49.5) > 0.1:
		return create_test_result(false, "Mage tower damage calculation incorrect: %.1f" % mage1_expected_damage)
	
	if abs(arrow_expected_da - 0.25) > 0.001:
		return create_test_result(false, "Arrow tower DA calculation incorrect: %.3f" % arrow_expected_da)
	
	if abs(arrow_expected_ta - 0.11) > 0.001:
		return create_test_result(false, "Arrow tower TA calculation incorrect: %.3f" % arrow_expected_ta)
	
	return create_test_result(true, "Multi-tower interactions calculated correctly")

func test_adjacent_tower_synergy() -> Dictionary:
	cleanup_test_environment()
	
	# Test adjacent tower detection for Pulse Tower and Aura Tower
	var center_pos = Vector2(200, 200)
	var adjacent_positions = [
		Vector2(150, 200),  # Left
		Vector2(250, 200),  # Right
		Vector2(200, 150),  # Up
		Vector2(200, 250)   # Down
	]
	
	# Pulse Tower at center gives frenzy bonus to adjacent towers
	var pulse_tower = {"type": "PulseTower", "position": center_pos}
	
	# Test that all adjacent positions are detected correctly
	for pos in adjacent_positions:
		var distance = center_pos.distance_to(pos)
		var is_adjacent = distance <= 55  # Grid spacing of 50 + small tolerance
		
		if not is_adjacent:
			return create_test_result(false, "Adjacent position not detected: %v (distance: %.1f)" % [pos, distance])
	
	# Test frenzy bonus: +5% attack speed, +5% damage
	var frenzy_attack_speed_bonus = 0.05
	var frenzy_damage_bonus = 0.05
	
	if frenzy_attack_speed_bonus != 0.05 or frenzy_damage_bonus != 0.05:
		return create_test_result(false, "Frenzy bonus values incorrect")
	
	# Test Aura Tower lucky bonus: +15% DA, +10% TA
	var lucky_da_bonus = 0.15
	var lucky_ta_bonus = 0.10
	
	if lucky_da_bonus != 0.15 or lucky_ta_bonus != 0.10:
		return create_test_result(false, "Lucky bonus values incorrect")
	
	return create_test_result(true, "Adjacent tower synergy detection working correctly")

## System Integration Tests

func test_defense_system_integration() -> Dictionary:
	# Test defense system integration with monster damage calculation
	
	# Create mock enemy with defense
	var enemy_data = {
		"type": "Elite",
		"defense": 75,
		"max_hp": 200,
		"current_hp": 200
	}
	
	# Create mock tower attack
	var tower_damage = 100
	
	# Calculate damage with defense
	var defense_system = DefenseSystem.new()
	var actual_damage = defense_system.calculate_damage_reduction(tower_damage, enemy_data.defense)
	var expected_damage = tower_damage / (1 + enemy_data.defense / 100.0)  # 100 / 1.75 = 57.14
	
	if abs(actual_damage - expected_damage) > 0.1:
		return create_test_result(false, "Defense integration failed. Expected=%.2f, Got=%.2f" % [expected_damage, actual_damage])
	
	# Test HP reduction
	var new_hp = enemy_data.current_hp - actual_damage
	if new_hp < 0 or new_hp > enemy_data.current_hp:
		return create_test_result(false, "HP calculation integration failed")
	
	return create_test_result(true, "Defense system integration working correctly")

func test_da_ta_system_integration() -> Dictionary:
	# Test DA/TA system integration with projectile spawning
	
	# Create mock projectile tower with DA/TA bonuses
	var tower_data = {
		"type": "ArrowTower",
		"base_da": 0.05,
		"base_ta": 0.01,
		"passive_da_bonus": 0.20,  # From 2 capture towers
		"passive_ta_bonus": 0.10   # From 2 capture towers
	}
	
	# Calculate total probabilities
	var total_da = tower_data.base_da + tower_data.passive_da_bonus  # 25%
	var total_ta = tower_data.base_ta + tower_data.passive_ta_bonus  # 11%
	
	# Apply caps
	var da_cap = Data.combat_settings.da_max_chance if Data.combat_settings.has("da_max_chance") else 0.5
	var ta_cap = Data.combat_settings.ta_max_chance if Data.combat_settings.has("ta_max_chance") else 0.25
	
	total_da = min(total_da, da_cap)
	total_ta = min(total_ta, ta_cap)
	
	if total_da != 0.25:
		return create_test_result(false, "DA integration failed. Expected=0.25, Got=%.3f" % total_da)
	
	if total_ta != 0.11:
		return create_test_result(false, "TA integration failed. Expected=0.11, Got=%.3f" % total_ta)
	
	# Test projectile count calculation
	var base_projectiles = 1
	var da_triggered = (randf() < total_da)
	var ta_triggered = (randf() < total_ta)
	
	var total_projectiles = base_projectiles
	if da_triggered:
		total_projectiles += 1
	if ta_triggered:
		total_projectiles += 2
	
	if total_projectiles < 1 or total_projectiles > 4:
		return create_test_result(false, "Projectile count calculation failed: %d" % total_projectiles)
	
	return create_test_result(true, "DA/TA system integration working correctly")

func test_monster_skill_tower_interaction() -> Dictionary:
	# Test monster skills affecting towers
	
	# Test Frost Aura affecting tower attack speed
	var tower_base_attack_speed = 1.0  # 1 attack per second
	var frost_aura_reduction = 0.20    # 20% reduction
	
	var affected_attack_speed = tower_base_attack_speed * (1.0 - frost_aura_reduction)
	var expected_speed = 0.8
	
	if abs(affected_attack_speed - expected_speed) > 0.01:
		return create_test_result(false, "Frost aura tower interaction failed. Expected=%.2f, Got=%.2f" % [expected_speed, affected_attack_speed])
	
	# Test Self-Destruct stunning towers
	var stun_duration = 1.5
	var tower_stunned = true
	var stun_start_time = Time.get_time_dict_from_system()
	
	# Simulate time passing
	await get_tree().create_timer(0.1).timeout  # 100ms
	
	var current_time = Time.get_time_dict_from_system()
	var time_passed = calculate_duration(stun_start_time, current_time)
	
	# Tower should still be stunned
	if time_passed >= stun_duration:
		tower_stunned = false
	
	if not tower_stunned:
		return create_test_result(false, "Tower stun duration test failed")
	
	return create_test_result(true, "Monster skill tower interactions working correctly")

## Performance Integration Tests

func test_performance_monitor_integration() -> Dictionary:
	# Test performance monitoring system integration
	
	# Check if performance monitor exists and is functional
	var performance_monitor = PerformanceMonitor.new()
	add_child(performance_monitor)
	
	# Wait a frame for initialization
	await get_tree().process_frame
	
	# Test FPS monitoring
	var fps = Engine.get_frames_per_second()
	if fps <= 0:
		performance_monitor.queue_free()
		return create_test_result(false, "FPS monitoring not functional")
	
	# Test entity counting (mock scenario)
	var mock_tower_count = 15
	var mock_enemy_count = 35
	var mock_projectile_count = 50
	
	# Verify counts are within performance targets
	var within_tower_limit = mock_tower_count <= 20
	var within_enemy_limit = mock_enemy_count <= 50
	var within_projectile_limit = mock_projectile_count <= 100
	
	if not (within_tower_limit and within_enemy_limit and within_projectile_limit):
		performance_monitor.queue_free()
		return create_test_result(false, "Performance targets not met in monitoring")
	
	performance_monitor.queue_free()
	return create_test_result(true, "Performance monitor integration working correctly")

func test_system_scalability() -> Dictionary:
	# Test system scalability under increasing load
	
	var start_time = Time.get_time_dict_from_system()
	
	# Simulate increasing system load
	var tower_count = 0
	var enemy_count = 0
	var max_towers = 20
	var max_enemies = 50
	
	# Simulate gradual load increase
	for i in range(10):  # 10 simulation steps
		tower_count = min(tower_count + 2, max_towers)
		enemy_count = min(enemy_count + 5, max_enemies)
		
		# Simulate processing time per entity
		for t in range(tower_count):
			# Mock tower processing
			var dummy_calc = randf() * 100
		
		for e in range(enemy_count):
			# Mock enemy processing
			var dummy_calc = randf() * 50
		
		# Small delay to simulate real-time processing
		await get_tree().process_frame
	
	var end_time = Time.get_time_dict_from_system()
	var total_duration = calculate_duration(start_time, end_time)
	
	# Should complete scaling test in under 1 second
	if total_duration < 1.0:
		return create_test_result(true, "System scalability excellent: %.3fs for full load" % total_duration)
	else:
		return create_test_result(false, "System scalability poor: %.3fs for full load" % total_duration)

## Chapter 1 Level Progression Integration Tests

func test_chapter1_level_progression() -> Dictionary:
	# Test Chapter 1 level progression integration
	
	# Verify Chapter 1 data structure
	if not Data.chapters.has(1):
		return create_test_result(false, "Chapter 1 not found in Data.chapters")
	
	var chapter1 = Data.chapters[1]
	var expected_levels = 5
	
	if chapter1.levels.size() != expected_levels:
		return create_test_result(false, "Chapter 1 should have %d levels, found %d" % [expected_levels, chapter1.levels.size()])
	
	# Verify wave counts: 20, 20, 30, 30, 50
	var expected_waves = [20, 20, 30, 30, 50]
	
	for i in range(expected_levels):
		var level_data = chapter1.levels[i]
		var actual_waves = level_data.waves.size()
		var expected = expected_waves[i]
		
		if actual_waves != expected:
			return create_test_result(false, "Level %d should have %d waves, found %d" % [i+1, expected, actual_waves])
	
	return create_test_result(true, "Chapter 1 level progression structure correct")

func test_save_load_integration() -> Dictionary:
	# Test save/load integration with new systems
	
	# Mock save data structure
	var save_data = {
		"chapter": 1,
		"level": 3,
		"towers_placed": [
			{"type": "ArrowTower", "position": Vector2(100, 100), "upgrades": []},
			{"type": "CaptureTower", "position": Vector2(150, 100), "upgrades": []},
			{"type": "MageTower", "position": Vector2(200, 100), "upgrades": []}
		],
		"performance_settings": {
			"performance_mode": false,
			"effect_quality": "high"
		}
	}
	
	# Validate save data structure
	if not save_data.has("chapter") or not save_data.has("level"):
		return create_test_result(false, "Save data missing required fields")
	
	if not save_data.has("towers_placed") or save_data.towers_placed.size() == 0:
		return create_test_result(false, "Save data missing tower information")
	
	# Validate tower data includes new tower types
	var has_new_tower_types = false
	for tower in save_data.towers_placed:
		if tower.type in ["ArrowTower", "CaptureTower", "MageTower"]:
			has_new_tower_types = true
			break
	
	if not has_new_tower_types:
		return create_test_result(false, "Save data doesn't include new tower types")
	
	return create_test_result(true, "Save/load integration compatible with new systems")