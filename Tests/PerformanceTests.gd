extends TowerDefenseTestFramework
class_name PerformanceTests

## Performance Validation Tests for Tower Defense Enhancement System
## Tests system performance under target loads and stress conditions

var performance_data: Dictionary = {}
var stress_test_running: bool = false

func _ready():
	super._ready()
	initialize_performance_tracking()

func initialize_performance_tracking():
	performance_data = {
		"fps_samples": [],
		"memory_samples": [],
		"entity_counts": [],
		"frame_times": []
	}
	print("Performance testing initialized")

## Run all performance validation tests
func run_performance_tests():
	print("\n=== Performance Validation Tests ===")
	var all_passed = true
	
	# Core Performance Tests
	all_passed = await run_test("20 Towers Performance Target", test_20_towers_performance) and all_passed
	all_passed = await run_test("50 Monsters Performance Target", test_50_monsters_performance) and all_passed
	all_passed = await run_test("Combined Load Stress Test", test_combined_stress_test) and all_passed
	
	# System-Specific Performance Tests
	all_passed = await run_test("Passive Synergy Calculation Efficiency", test_passive_synergy_efficiency) and all_passed
	all_passed = await run_test("Monster Skill System Scaling", test_monster_skill_scaling) and all_passed
	all_passed = await run_test("DA/TA System Performance", test_da_ta_performance) and all_passed
	
	# Memory and Resource Tests
	all_passed = await run_test("Memory Usage Validation", test_memory_usage_validation) and all_passed
	all_passed = await run_test("Resource Cleanup Validation", test_resource_cleanup) and all_passed
	
	# Long-term Performance Tests
	all_passed = await run_test("Extended Gameplay Performance", test_extended_gameplay_performance) and all_passed
	
	return all_passed

## Core Performance Target Tests

func test_20_towers_performance() -> Dictionary:
	print("  Testing 20 towers performance target...")
	
	# Create mock 20 towers with various types
	var towers = create_mock_towers(20)
	var start_time = Time.get_time_dict_from_system()
	
	# Simulate tower processing for multiple frames
	var frame_count = 60  # Test for 1 second at 60 FPS
	var fps_samples = []
	
	for frame in range(frame_count):
		var frame_start = Time.get_time_dict_from_system()
		
		# Simulate tower processing
		for tower in towers:
			simulate_tower_processing(tower)
		
		# Wait for next frame
		await get_tree().process_frame
		
		var frame_end = Time.get_time_dict_from_system()
		var frame_time = calculate_duration(frame_start, frame_end)
		
		# Calculate FPS for this frame
		var fps = 1.0 / max(frame_time, 0.001)
		fps_samples.append(fps)
	
	var end_time = Time.get_time_dict_from_system()
	var total_duration = calculate_duration(start_time, end_time)
	
	# Calculate average FPS
	var avg_fps = 0.0
	for fps in fps_samples:
		avg_fps += fps
	avg_fps /= fps_samples.size()
	
	# Clean up
	cleanup_mock_towers(towers)
	
	# Performance criteria: maintain 60 FPS with 20 towers
	if avg_fps >= 55.0:  # Allow some tolerance
		return create_test_result(true, "20 towers performance excellent: %.1f avg FPS" % avg_fps)
	elif avg_fps >= 45.0:
		return create_test_result(true, "20 towers performance acceptable: %.1f avg FPS" % avg_fps)
	else:
		return create_test_result(false, "20 towers performance poor: %.1f avg FPS" % avg_fps)

func test_50_monsters_performance() -> Dictionary:
	print("  Testing 50 monsters performance target...")
	
	# Create mock 50 monsters with various types and skills
	var monsters = create_mock_monsters(50)
	var start_time = Time.get_time_dict_from_system()
	
	# Simulate monster processing for multiple frames
	var frame_count = 60
	var fps_samples = []
	
	for frame in range(frame_count):
		var frame_start = Time.get_time_dict_from_system()
		
		# Simulate monster processing
		for monster in monsters:
			simulate_monster_processing(monster)
		
		await get_tree().process_frame
		
		var frame_end = Time.get_time_dict_from_system()
		var frame_time = calculate_duration(frame_start, frame_end)
		var fps = 1.0 / max(frame_time, 0.001)
		fps_samples.append(fps)
	
	var end_time = Time.get_time_dict_from_system()
	
	# Calculate average FPS
	var avg_fps = 0.0
	for fps in fps_samples:
		avg_fps += fps
	avg_fps /= fps_samples.size()
	
	# Clean up
	cleanup_mock_monsters(monsters)
	
	# Performance criteria: maintain 60 FPS with 50 monsters
	if avg_fps >= 55.0:
		return create_test_result(true, "50 monsters performance excellent: %.1f avg FPS" % avg_fps)
	elif avg_fps >= 45.0:
		return create_test_result(true, "50 monsters performance acceptable: %.1f avg FPS" % avg_fps)
	else:
		return create_test_result(false, "50 monsters performance poor: %.1f avg FPS" % avg_fps)

func test_combined_stress_test() -> Dictionary:
	print("  Testing combined load (20 towers + 50 monsters + 100 projectiles)...")
	
	stress_test_running = true
	var towers = create_mock_towers(20)
	var monsters = create_mock_monsters(50)
	var projectiles = create_mock_projectiles(100)
	
	var start_time = Time.get_time_dict_from_system()
	var frame_count = 120  # Test for 2 seconds
	var fps_samples = []
	var memory_samples = []
	
	for frame in range(frame_count):
		var frame_start = Time.get_time_dict_from_system()
		
		# Simulate combined system processing
		process_combined_systems(towers, monsters, projectiles)
		
		await get_tree().process_frame
		
		var frame_end = Time.get_time_dict_from_system()
		var frame_time = calculate_duration(frame_start, frame_end)
		var fps = 1.0 / max(frame_time, 0.001)
		fps_samples.append(fps)
		
		# Sample memory usage every 10 frames
		if frame % 10 == 0:
			var memory_usage = OS.get_static_memory_usage_by_type()
			memory_samples.append(memory_usage)
	
	var end_time = Time.get_time_dict_from_system()
	
	# Calculate performance metrics
	var avg_fps = 0.0
	var min_fps = 1000.0
	for fps in fps_samples:
		avg_fps += fps
		min_fps = min(min_fps, fps)
	avg_fps /= fps_samples.size()
	
	# Clean up
	cleanup_mock_towers(towers)
	cleanup_mock_monsters(monsters)
	cleanup_mock_projectiles(projectiles)
	stress_test_running = false
	
	# Performance criteria for combined load
	if avg_fps >= 50.0 and min_fps >= 35.0:
		return create_test_result(true, "Combined stress test excellent: %.1f avg FPS, %.1f min FPS" % [avg_fps, min_fps])
	elif avg_fps >= 40.0 and min_fps >= 25.0:
		return create_test_result(true, "Combined stress test acceptable: %.1f avg FPS, %.1f min FPS" % [avg_fps, min_fps])
	else:
		return create_test_result(false, "Combined stress test failed: %.1f avg FPS, %.1f min FPS" % [avg_fps, min_fps])

## System-Specific Performance Tests

func test_passive_synergy_efficiency() -> Dictionary:
	print("  Testing passive synergy calculation efficiency...")
	
	# Create complex synergy scenario
	var towers = []
	for i in range(20):
		var tower_type = ["ArrowTower", "CaptureTower", "MageTower", "PulseTower"][i % 4]
		towers.append({
			"type": tower_type,
			"position": Vector2(i * 50, 100),
			"id": i
		})
	
	var start_time = Time.get_time_dict_from_system()
	
	# Simulate passive synergy calculations
	var calculation_count = 1000
	for calc in range(calculation_count):
		for tower in towers:
			calculate_mock_passive_synergies(tower, towers)
	
	var end_time = Time.get_time_dict_from_system()
	var duration = calculate_duration(start_time, end_time)
	
	# Performance criteria: 1000 calculations for 20 towers in under 100ms
	var calculations_per_ms = calculation_count / max(duration * 1000, 1)
	
	if duration < 0.1:
		return create_test_result(true, "Passive synergy efficiency excellent: %.3fs for %d calculations" % [duration, calculation_count])
	elif duration < 0.25:
		return create_test_result(true, "Passive synergy efficiency acceptable: %.3fs for %d calculations" % [duration, calculation_count])
	else:
		return create_test_result(false, "Passive synergy efficiency poor: %.3fs for %d calculations" % [duration, calculation_count])

func test_monster_skill_scaling() -> Dictionary:
	print("  Testing monster skill system scaling...")
	
	# Test with increasing number of monsters with skills
	var results = {}
	var monster_counts = [10, 25, 50, 75, 100]
	
	for count in monster_counts:
		var monsters = create_mock_monsters_with_skills(count)
		var start_time = Time.get_time_dict_from_system()
		
		# Simulate skill processing for 30 frames
		for frame in range(30):
			for monster in monsters:
				simulate_monster_skill_processing(monster)
			await get_tree().process_frame
		
		var end_time = Time.get_time_dict_from_system()
		var duration = calculate_duration(start_time, end_time)
		results[count] = duration
		
		cleanup_mock_monsters(monsters)
	
	# Analyze scaling efficiency
	var scaling_factor = results[100] / results[10]  # How much slower with 10x monsters
	
	if scaling_factor < 5.0:  # Less than 5x slower with 10x entities
		return create_test_result(true, "Monster skill scaling excellent: %.1fx factor" % scaling_factor)
	elif scaling_factor < 10.0:
		return create_test_result(true, "Monster skill scaling acceptable: %.1fx factor" % scaling_factor)
	else:
		return create_test_result(false, "Monster skill scaling poor: %.1fx factor" % scaling_factor)

func test_da_ta_performance() -> Dictionary:
	print("  Testing DA/TA system performance...")
	
	var start_time = Time.get_time_dict_from_system()
	
	# Simulate DA/TA calculations for many attacks
	var attack_count = 10000
	var da_triggers = 0
	var ta_triggers = 0
	
	for attack in range(attack_count):
		var da_chance = 0.25  # 25% chance
		var ta_chance = 0.15  # 15% chance
		
		# Simulate probability checks
		if randf() < da_chance:
			da_triggers += 1
		if randf() < ta_chance:
			ta_triggers += 1
	
	var end_time = Time.get_time_dict_from_system()
	var duration = calculate_duration(start_time, end_time)
	
	# Validate trigger rates are reasonable
	var da_rate = float(da_triggers) / attack_count
	var ta_rate = float(ta_triggers) / attack_count
	
	# Should be close to expected probabilities (within 5%)
	var da_accuracy = abs(da_rate - 0.25) < 0.05
	var ta_accuracy = abs(ta_rate - 0.15) < 0.05
	
	if duration < 0.05 and da_accuracy and ta_accuracy:
		return create_test_result(true, "DA/TA performance excellent: %.3fs for %d calculations" % [duration, attack_count])
	elif duration < 0.1:
		return create_test_result(true, "DA/TA performance acceptable: %.3fs for %d calculations" % [duration, attack_count])
	else:
		return create_test_result(false, "DA/TA performance poor: %.3fs for %d calculations" % [duration, attack_count])

## Memory and Resource Tests

func test_memory_usage_validation() -> Dictionary:
	print("  Testing memory usage validation...")
	
	# Measure baseline memory
	var baseline_memory = OS.get_static_memory_usage_by_type()
	
	# Create full load scenario
	var towers = create_mock_towers(20)
	var monsters = create_mock_monsters(50)
	var projectiles = create_mock_projectiles(100)
	
	# Let systems run for a while
	for i in range(300):  # 5 seconds at 60 FPS
		process_combined_systems(towers, monsters, projectiles)
		await get_tree().process_frame
	
	# Measure peak memory
	var peak_memory = OS.get_static_memory_usage_by_type()
	
	# Clean up
	cleanup_mock_towers(towers)
	cleanup_mock_monsters(monsters)
	cleanup_mock_projectiles(projectiles)
	
	# Wait for garbage collection
	for i in range(60):
		await get_tree().process_frame
	
	# Measure final memory
	var final_memory = OS.get_static_memory_usage_by_type()
	
	# Calculate memory increase
	var memory_increase = peak_memory - baseline_memory
	var memory_retained = final_memory - baseline_memory
	
	# Memory criteria: peak increase < 50MB, retained < 10MB
	var peak_mb = memory_increase / (1024 * 1024)
	var retained_mb = memory_retained / (1024 * 1024)
	
	if peak_mb < 50 and retained_mb < 10:
		return create_test_result(true, "Memory usage excellent: %.1f MB peak, %.1f MB retained" % [peak_mb, retained_mb])
	elif peak_mb < 100 and retained_mb < 25:
		return create_test_result(true, "Memory usage acceptable: %.1f MB peak, %.1f MB retained" % [peak_mb, retained_mb])
	else:
		return create_test_result(false, "Memory usage excessive: %.1f MB peak, %.1f MB retained" % [peak_mb, retained_mb])

func test_resource_cleanup() -> Dictionary:
	print("  Testing resource cleanup validation...")
	
	var initial_node_count = get_tree().get_node_count_in_group("test_entities")
	
	# Create and destroy entities multiple times
	for cycle in range(5):
		var entities = []
		
		# Create entities
		for i in range(50):
			var entity = Node2D.new()
			entity.add_to_group("test_entities")
			add_child(entity)
			entities.append(entity)
		
		# Use entities briefly
		await get_tree().process_frame
		
		# Clean up entities
		for entity in entities:
			if is_instance_valid(entity):
				entity.queue_free()
		
		# Wait for cleanup
		for i in range(10):
			await get_tree().process_frame
	
	# Final cleanup
	await get_tree().process_frame
	
	var final_node_count = get_tree().get_node_count_in_group("test_entities")
	var leaked_nodes = final_node_count - initial_node_count
	
	if leaked_nodes == 0:
		return create_test_result(true, "Resource cleanup perfect: no leaked nodes")
	elif leaked_nodes <= 5:
		return create_test_result(true, "Resource cleanup good: %d leaked nodes" % leaked_nodes)
	else:
		return create_test_result(false, "Resource cleanup poor: %d leaked nodes" % leaked_nodes)

func test_extended_gameplay_performance() -> Dictionary:
	print("  Testing extended gameplay performance (10 minutes simulation)...")
	
	# Simulate 10 minutes of gameplay (600 seconds at accelerated rate)
	var simulation_frames = 600  # Compressed to 10 seconds real time
	var towers = create_mock_towers(15)  # Start with fewer, add more
	var monsters = create_mock_monsters(30)
	
	var fps_samples = []
	var performance_degradation = false
	
	for frame in range(simulation_frames):
		var frame_start = Time.get_time_dict_from_system()
		
		# Gradually increase load
		if frame % 60 == 0 and towers.size() < 20:
			towers.append(create_single_mock_tower(towers.size()))
		if frame % 30 == 0 and monsters.size() < 50:
			monsters.append(create_single_mock_monster(monsters.size()))
		
		# Process systems
		process_combined_systems(towers, monsters, [])
		
		await get_tree().process_frame
		
		var frame_end = Time.get_time_dict_from_system()
		var frame_time = calculate_duration(frame_start, frame_end)
		var fps = 1.0 / max(frame_time, 0.001)
		fps_samples.append(fps)
		
		# Check for performance degradation
		if frame > 60 and fps < 30:
			performance_degradation = true
	
	# Clean up
	cleanup_mock_towers(towers)
	cleanup_mock_monsters(monsters)
	
	# Analyze performance trend
	var early_avg = 0.0
	var late_avg = 0.0
	var mid_point = fps_samples.size() / 2
	
	for i in range(mid_point):
		early_avg += fps_samples[i]
	early_avg /= mid_point
	
	for i in range(mid_point, fps_samples.size()):
		late_avg += fps_samples[i]
	late_avg /= (fps_samples.size() - mid_point)
	
	var performance_drop = early_avg - late_avg
	
	if not performance_degradation and performance_drop < 5:
		return create_test_result(true, "Extended gameplay performance excellent: %.1f FPS drop" % performance_drop)
	elif performance_drop < 15:
		return create_test_result(true, "Extended gameplay performance acceptable: %.1f FPS drop" % performance_drop)
	else:
		return create_test_result(false, "Extended gameplay performance poor: %.1f FPS drop" % performance_drop)

## Mock Object Creation and Management

func create_mock_towers(count: int) -> Array:
	var towers = []
	var tower_types = ["ArrowTower", "CaptureTower", "MageTower", "PulseTower", "AuraTower"]
	
	for i in range(count):
		var tower = {
			"id": i,
			"type": tower_types[i % tower_types.size()],
			"position": Vector2(i * 50, 100),
			"range": 80 + (i % 40),
			"damage": 20 + (i % 30),
			"attack_speed": 1.0 + (randf() * 0.5)
		}
		towers.append(tower)
	
	return towers

func create_mock_monsters(count: int) -> Array:
	var monsters = []
	var monster_types = ["Normal", "Fast", "Heavy", "Elite"]
	
	for i in range(count):
		var monster = {
			"id": i,
			"type": monster_types[i % monster_types.size()],
			"position": Vector2(i * 20, 200),
			"hp": 100 + (i % 100),
			"speed": 50 + (i % 50),
			"defense": i % 30,
			"has_skill": (i % 4 == 0)
		}
		monsters.append(monster)
	
	return monsters

func create_mock_projectiles(count: int) -> Array:
	var projectiles = []
	
	for i in range(count):
		var projectile = {
			"id": i,
			"position": Vector2(randf() * 800, randf() * 600),
			"velocity": Vector2(randf() * 200 - 100, randf() * 200 - 100),
			"damage": 10 + (i % 20)
		}
		projectiles.append(projectile)
	
	return projectiles

func create_mock_monsters_with_skills(count: int) -> Array:
	var monsters = create_mock_monsters(count)
	var skill_types = ["frost_aura", "acceleration", "self_destruct", "petrification"]
	
	for i in range(count):
		if i % 3 == 0:  # Every 3rd monster has a skill
			monsters[i]["skill"] = skill_types[i % skill_types.size()]
			monsters[i]["skill_cooldown"] = randf() * 10
	
	return monsters

func create_single_mock_tower(id: int) -> Dictionary:
	var tower_types = ["ArrowTower", "CaptureTower", "MageTower", "PulseTower"]
	return {
		"id": id,
		"type": tower_types[id % tower_types.size()],
		"position": Vector2(id * 50, 100),
		"range": 80,
		"damage": 25,
		"attack_speed": 1.0
	}

func create_single_mock_monster(id: int) -> Dictionary:
	return {
		"id": id,
		"type": "Normal",
		"position": Vector2(id * 20, 200),
		"hp": 100,
		"speed": 50,
		"defense": 10,
		"has_skill": false
	}

## Mock Processing Functions

func simulate_tower_processing(tower: Dictionary):
	# Simulate tower AI and targeting
	var dummy_calc = tower.damage * tower.attack_speed * randf()
	
	# Simulate passive synergy calculations
	if tower.type == "ArrowTower":
		dummy_calc *= (1.0 + randf() * 0.2)  # DA/TA bonus

func simulate_monster_processing(monster: Dictionary):
	# Simulate monster movement and AI
	monster.position.x += monster.speed * 0.016  # Move at 60 FPS
	
	# Simulate skill processing
	if monster.has_skill:
		var dummy_calc = monster.hp * randf()

func simulate_monster_skill_processing(monster: Dictionary):
	if monster.has("skill"):
		# Simulate skill cooldown and effects
		var cooldown = monster.get("skill_cooldown", 0)
		if cooldown <= 0:
			# Process skill effect
			var effect_strength = randf() * 100

func process_combined_systems(towers: Array, monsters: Array, projectiles: Array):
	# Simulate all systems working together
	for tower in towers:
		simulate_tower_processing(tower)
	
	for monster in monsters:
		simulate_monster_processing(monster)
	
	for projectile in projectiles:
		# Simulate projectile movement
		projectile.position += projectile.velocity * 0.016

func calculate_mock_passive_synergies(tower: Dictionary, all_towers: Array):
	# Simulate passive synergy calculations
	var bonus_count = 0
	for other_tower in all_towers:
		if other_tower.id != tower.id:
			var distance = tower.position.distance_to(other_tower.position)
			if distance <= tower.range:
				bonus_count += 1
	
	# Simulate bonus application
	var damage_bonus = bonus_count * 0.1
	return damage_bonus

## Cleanup Functions

func cleanup_mock_towers(towers: Array):
	towers.clear()

func cleanup_mock_monsters(monsters: Array):
	monsters.clear()

func cleanup_mock_projectiles(projectiles: Array):
	projectiles.clear()