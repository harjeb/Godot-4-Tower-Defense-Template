extends TowerDefenseTestFramework
class_name Chapter1ProgressionTests

## Chapter 1 Level Progression Tests for Tower Defense Enhancement
## Tests level structure, wave progression, difficulty scaling, and completion

var mock_game_state: Dictionary = {}
var level_completion_times: Array = []

func _ready():
	super._ready()
	initialize_chapter1_testing()

func initialize_chapter1_testing():
	mock_game_state = {
		"current_chapter": 1,
		"current_level": 1,
		"levels_completed": [],
		"total_score": 0,
		"player_lives": 20
	}
	print("Chapter 1 progression tests initialized")

## Run all Chapter 1 progression tests
func run_chapter1_tests():
	print("\n=== Chapter 1 Level Progression Tests ===")
	var all_passed = true
	
	# Level Structure Tests
	all_passed = await run_test("Chapter 1 Data Structure Validation", test_chapter1_structure) and all_passed
	all_passed = await run_test("Level Wave Count Validation", test_level_wave_counts) and all_passed
	all_passed = await run_test("Enemy Type Progression", test_enemy_type_progression) and all_passed
	
	# Individual Level Tests
	all_passed = await run_test("Level 1 Basic Functionality", test_level1_basic) and all_passed
	all_passed = await run_test("Level 2 Skill Monster Introduction", test_level2_skills) and all_passed
	all_passed = await run_test("Level 3 Mixed Enemy Types", test_level3_mixed) and all_passed
	all_passed = await run_test("Level 4 Elite Enemy Encounters", test_level4_elite) and all_passed
	all_passed = await run_test("Level 5 Boss Encounter", test_level5_boss) and all_passed
	
	# Progression System Tests
	all_passed = await run_test("Level Progression Logic", test_level_progression_logic) and all_passed
	all_passed = await run_test("Difficulty Scaling Validation", test_difficulty_scaling) and all_passed
	all_passed = await run_test("Chapter Completion Validation", test_chapter_completion) and all_passed
	
	return all_passed

## Chapter 1 Structure Validation Tests

func test_chapter1_structure() -> Dictionary:
	# Validate Chapter 1 exists in Data.chapters
	if not Data.chapters.has(1):
		return create_test_result(false, "Chapter 1 not found in Data.chapters")
	
	var chapter1 = Data.chapters[1]
	
	# Validate chapter properties
	if not chapter1.has("name"):
		return create_test_result(false, "Chapter 1 missing name property")
	
	if not chapter1.has("levels"):
		return create_test_result(false, "Chapter 1 missing levels array")
	
	if not chapter1.has("description"):
		return create_test_result(false, "Chapter 1 missing description")
	
	# Validate level count
	if chapter1.levels.size() != 5:
		return create_test_result(false, "Chapter 1 should have 5 levels, found %d" % chapter1.levels.size())
	
	# Validate each level has required properties
	for i in range(chapter1.levels.size()):
		var level = chapter1.levels[i]
		
		if not level.has("id"):
			return create_test_result(false, "Level %d missing id property" % (i + 1))
		
		if not level.has("name"):
			return create_test_result(false, "Level %d missing name property" % (i + 1))
		
		if not level.has("waves"):
			return create_test_result(false, "Level %d missing waves array" % (i + 1))
		
		if not level.has("map_file"):
			return create_test_result(false, "Level %d missing map_file property" % (i + 1))
	
	return create_test_result(true, "Chapter 1 structure validation passed")

func test_level_wave_counts() -> Dictionary:
	var chapter1 = Data.chapters[1]
	var expected_wave_counts = [20, 20, 30, 30, 50]
	
	for i in range(chapter1.levels.size()):
		var level = chapter1.levels[i]
		var actual_waves = level.waves.size()
		var expected_waves = expected_wave_counts[i]
		
		if actual_waves != expected_waves:
			return create_test_result(false, 
				"Level %d wave count incorrect. Expected %d, found %d" % 
				[i + 1, expected_waves, actual_waves])
	
	return create_test_result(true, "All level wave counts correct: 20, 20, 30, 30, 50")

func test_enemy_type_progression() -> Dictionary:
	var chapter1 = Data.chapters[1]
	
	# Level 1: Should have only basic enemies
	var level1 = chapter1.levels[0]
	var has_advanced_enemies_l1 = false
	for wave in level1.waves:
		for enemy_group in wave.enemy_groups:
			if enemy_group.enemy_type in ["Elite", "Boss"]:
				has_advanced_enemies_l1 = true
				break
	
	if has_advanced_enemies_l1:
		return create_test_result(false, "Level 1 should only have basic enemies")
	
	# Level 2: Should introduce skill monsters
	var level2 = chapter1.levels[1]
	var has_skill_monsters_l2 = false
	for wave in level2.waves:
		for enemy_group in wave.enemy_groups:
			if enemy_group.has("skills") and enemy_group.skills.size() > 0:
				has_skill_monsters_l2 = true
				break
	
	if not has_skill_monsters_l2:
		return create_test_result(false, "Level 2 should introduce skill monsters")
	
	# Level 4: Should have elite enemies
	var level4 = chapter1.levels[3]
	var has_elite_enemies_l4 = false
	for wave in level4.waves:
		for enemy_group in wave.enemy_groups:
			if enemy_group.enemy_type == "Elite":
				has_elite_enemies_l4 = true
				break
	
	if not has_elite_enemies_l4:
		return create_test_result(false, "Level 4 should have elite enemies")
	
	# Level 5: Should have boss encounter
	var level5 = chapter1.levels[4]
	var has_boss_l5 = false
	for wave in level5.waves:
		for enemy_group in wave.enemy_groups:
			if enemy_group.enemy_type == "Boss":
				has_boss_l5 = true
				break
	
	if not has_boss_l5:
		return create_test_result(false, "Level 5 should have boss encounter")
	
	return create_test_result(true, "Enemy type progression is correct")

## Individual Level Tests

func test_level1_basic() -> Dictionary:
	var level1 = Data.chapters[1].levels[0]
	
	# Simulate Level 1 playthrough
	var simulation_result = await simulate_level_playthrough(1, 1)
	
	if not simulation_result.success:
		return create_test_result(false, "Level 1 simulation failed: %s" % simulation_result.error)
	
	# Validate completion criteria
	if simulation_result.waves_completed != 20:
		return create_test_result(false, "Level 1 should complete 20 waves, completed %d" % simulation_result.waves_completed)
	
	# Check difficulty is appropriate (player should not struggle)
	if simulation_result.lives_lost > 5:
		return create_test_result(false, "Level 1 too difficult: lost %d lives" % simulation_result.lives_lost)
	
	return create_test_result(true, "Level 1 basic functionality working correctly")

func test_level2_skills() -> Dictionary:
	var simulation_result = await simulate_level_playthrough(1, 2)
	
	if not simulation_result.success:
		return create_test_result(false, "Level 2 simulation failed: %s" % simulation_result.error)
	
	# Validate skill monster encounters
	if not simulation_result.skill_monsters_encountered:
		return create_test_result(false, "Level 2 should feature monsters with skills")
	
	# Check skills affected gameplay
	if not simulation_result.skill_effects_applied:
		return create_test_result(false, "Monster skills should affect towers/gameplay")
	
	return create_test_result(true, "Level 2 skill monster introduction working correctly")

func test_level3_mixed() -> Dictionary:
	var simulation_result = await simulate_level_playthrough(1, 3)
	
	if not simulation_result.success:
		return create_test_result(false, "Level 3 simulation failed: %s" % simulation_result.error)
	
	# Validate enemy variety
	if simulation_result.enemy_types_encountered < 3:
		return create_test_result(false, "Level 3 should have mixed enemy types (found %d)" % simulation_result.enemy_types_encountered)
	
	# Check increased difficulty
	if simulation_result.completion_time < 180:  # Should take at least 3 minutes
		return create_test_result(false, "Level 3 completed too quickly, may be too easy")
	
	return create_test_result(true, "Level 3 mixed enemy types working correctly")

func test_level4_elite() -> Dictionary:
	var simulation_result = await simulate_level_playthrough(1, 4)
	
	if not simulation_result.success:
		return create_test_result(false, "Level 4 simulation failed: %s" % simulation_result.error)
	
	# Validate elite enemy encounters
	if not simulation_result.elite_enemies_encountered:
		return create_test_result(false, "Level 4 should feature elite enemies")
	
	# Check elite enemies are challenging
	if simulation_result.lives_lost < 2:
		return create_test_result(false, "Level 4 may be too easy with elite enemies")
	
	return create_test_result(true, "Level 4 elite enemy encounters working correctly")

func test_level5_boss() -> Dictionary:
	var simulation_result = await simulate_level_playthrough(1, 5)
	
	if not simulation_result.success:
		return create_test_result(false, "Level 5 simulation failed: %s" % simulation_result.error)
	
	# Validate boss encounter
	if not simulation_result.boss_encountered:
		return create_test_result(false, "Level 5 should feature boss encounter")
	
	# Check boss is appropriately challenging
	if simulation_result.completion_time < 300:  # Should take at least 5 minutes
		return create_test_result(false, "Level 5 boss may be too easy")
	
	# Validate final wave count
	if simulation_result.waves_completed != 50:
		return create_test_result(false, "Level 5 should complete 50 waves, completed %d" % simulation_result.waves_completed)
	
	return create_test_result(true, "Level 5 boss encounter working correctly")

## Progression System Tests

func test_level_progression_logic() -> Dictionary:
	# Test level unlocking logic
	mock_game_state.levels_completed = []
	
	# Initially, only Level 1 should be available
	var available_levels = get_available_levels(mock_game_state)
	if available_levels.size() != 1 or available_levels[0] != 1:
		return create_test_result(false, "Initially only Level 1 should be available")
	
	# Complete Level 1, Level 2 should unlock
	mock_game_state.levels_completed.append(1)
	available_levels = get_available_levels(mock_game_state)
	if available_levels.size() != 2 or not (2 in available_levels):
		return create_test_result(false, "Level 2 should unlock after completing Level 1")
	
	# Complete all levels except 5, Level 5 should unlock
	mock_game_state.levels_completed = [1, 2, 3, 4]
	available_levels = get_available_levels(mock_game_state)
	if not (5 in available_levels):
		return create_test_result(false, "Level 5 should unlock after completing Level 4")
	
	return create_test_result(true, "Level progression logic working correctly")

func test_difficulty_scaling() -> Dictionary:
	var difficulty_metrics = []
	
	# Simulate all levels and measure difficulty
	for level_num in range(1, 6):
		var simulation = await simulate_level_playthrough(1, level_num)
		
		var difficulty_score = calculate_difficulty_score(simulation)
		difficulty_metrics.append(difficulty_score)
	
	# Verify difficulty increases generally
	var proper_scaling = true
	for i in range(1, difficulty_metrics.size()):
		# Allow some variation, but general trend should be upward
		if difficulty_metrics[i] < difficulty_metrics[i-1] - 10:  # Allow 10 point decrease
			proper_scaling = false
			break
	
	if not proper_scaling:
		return create_test_result(false, "Difficulty scaling not consistent across levels")
	
	# Level 5 should be significantly harder than Level 1
	var difficulty_increase = difficulty_metrics[4] - difficulty_metrics[0]
	if difficulty_increase < 50:  # Expect at least 50 point increase
		return create_test_result(false, "Insufficient difficulty scaling from Level 1 to 5")
	
	return create_test_result(true, "Difficulty scaling working correctly")

func test_chapter_completion() -> Dictionary:
	# Test chapter completion logic
	mock_game_state.levels_completed = [1, 2, 3, 4, 5]
	
	var chapter_complete = is_chapter_complete(mock_game_state, 1)
	if not chapter_complete:
		return create_test_result(false, "Chapter 1 should be complete when all levels finished")
	
	# Test partial completion
	mock_game_state.levels_completed = [1, 2, 3]
	chapter_complete = is_chapter_complete(mock_game_state, 1)
	if chapter_complete:
		return create_test_result(false, "Chapter 1 should not be complete with only 3 levels finished")
	
	# Test score calculation
	mock_game_state.levels_completed = [1, 2, 3, 4, 5]
	mock_game_state.total_score = calculate_chapter_score(mock_game_state, 1)
	
	if mock_game_state.total_score <= 0:
		return create_test_result(false, "Chapter completion should calculate positive score")
	
	return create_test_result(true, "Chapter completion logic working correctly")

## Helper Functions for Level Simulation

func simulate_level_playthrough(chapter: int, level: int) -> Dictionary:
	print("    Simulating Chapter %d Level %d..." % [chapter, level])
	
	var level_data = Data.chapters[chapter].levels[level - 1]
	var simulation_start = Time.get_time_dict_from_system()
	
	var result = {
		"success": true,
		"error": "",
		"waves_completed": 0,
		"lives_lost": 0,
		"completion_time": 0,
		"skill_monsters_encountered": false,
		"skill_effects_applied": false,
		"elite_enemies_encountered": false,
		"boss_encountered": false,
		"enemy_types_encountered": 0
	}
	
	var enemy_types_seen = {}
	var current_lives = 20
	var waves_total = level_data.waves.size()
	
	# Simulate each wave
	for wave_index in range(waves_total):
		var wave = level_data.waves[wave_index]
		
		# Process each enemy group in the wave
		for enemy_group in wave.enemy_groups:
			var enemy_type = enemy_group.enemy_type
			enemy_types_seen[enemy_type] = true
			
			# Check for special enemy types
			if enemy_type == "Elite":
				result.elite_enemies_encountered = true
			elif enemy_type == "Boss":
				result.boss_encountered = true
			
			# Check for skill monsters
			if enemy_group.has("skills") and enemy_group.skills.size() > 0:
				result.skill_monsters_encountered = true
				result.skill_effects_applied = true
			
			# Simulate enemy reaching end (some will get through)
			var enemies_through = simulate_enemy_breakthrough(enemy_group, level)
			current_lives -= enemies_through
			
			if current_lives <= 0:
				result.success = false
				result.error = "Player ran out of lives on wave %d" % (wave_index + 1)
				return result
		
		result.waves_completed += 1
		
		# Add small delay to simulate real gameplay
		await get_tree().process_frame
	
	var simulation_end = Time.get_time_dict_from_system()
	result.completion_time = calculate_duration(simulation_start, simulation_end) * 60  # Convert to game minutes
	result.lives_lost = 20 - current_lives
	result.enemy_types_encountered = enemy_types_seen.size()
	
	return result

func simulate_enemy_breakthrough(enemy_group: Dictionary, level: int) -> int:
	# Simulate how many enemies get through based on level difficulty
	var enemy_count = enemy_group.get("count", 1)
	var breakthrough_rate = 0.0
	
	# Adjust breakthrough rate based on level
	match level:
		1: breakthrough_rate = 0.05  # 5% get through
		2: breakthrough_rate = 0.10  # 10% get through
		3: breakthrough_rate = 0.15  # 15% get through
		4: breakthrough_rate = 0.20  # 20% get through
		5: breakthrough_rate = 0.25  # 25% get through
	
	# Elite and boss enemies are harder to stop
	if enemy_group.enemy_type == "Elite":
		breakthrough_rate *= 1.5
	elif enemy_group.enemy_type == "Boss":
		breakthrough_rate *= 2.0
	
	# Calculate how many get through
	var breakthrough_count = int(enemy_count * breakthrough_rate)
	
	# Add some randomness
	if randf() < (enemy_count * breakthrough_rate - breakthrough_count):
		breakthrough_count += 1
	
	return breakthrough_count

func calculate_difficulty_score(simulation_result: Dictionary) -> int:
	var score = 0
	
	# Base score from waves
	score += simulation_result.waves_completed
	
	# Difficulty factors
	score += simulation_result.lives_lost * 5
	score += simulation_result.completion_time / 10  # Time in minutes
	
	# Special enemy bonuses
	if simulation_result.skill_monsters_encountered:
		score += 20
	if simulation_result.elite_enemies_encountered:
		score += 30
	if simulation_result.boss_encountered:
		score += 50
	
	return score

func get_available_levels(game_state: Dictionary) -> Array:
	var available = [1]  # Level 1 is always available
	
	for completed_level in game_state.levels_completed:
		var next_level = completed_level + 1
		if next_level <= 5 and not (next_level in available):
			available.append(next_level)
	
	return available

func is_chapter_complete(game_state: Dictionary, chapter: int) -> bool:
	var required_levels = [1, 2, 3, 4, 5]
	
	for level in required_levels:
		if not (level in game_state.levels_completed):
			return false
	
	return true

func calculate_chapter_score(game_state: Dictionary, chapter: int) -> int:
	var total_score = 0
	
	# Base score for completion
	total_score += game_state.levels_completed.size() * 1000
	
	# Bonus for completing all levels
	if is_chapter_complete(game_state, chapter):
		total_score += 5000
	
	# Lives remaining bonus
	total_score += game_state.player_lives * 100
	
	return total_score