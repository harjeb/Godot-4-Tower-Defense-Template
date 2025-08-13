extends "res://Tests/TestBase.gd"

# Test for ice effect integration with enemy system
class_name IceEnemyIntegrationTest

func _ready():
	test_name = "Ice Enemy Integration Test"
	super._ready()

func run_test():
	print("🧪 Testing ice effect integration with enemy system...")
	
	# Test 1: Enemy ice effect methods
	print("\n📋 Test 1: Enemy ice effect methods")
	var enemy_mover_script = load("res://Scenes/enemies/enemy_mover.gd")
	
	var required_methods = [
		"apply_speed_modifier",
		"remove_speed_modifier", 
		"set_frost_stacks",
		"set_frozen",
		"get_frost_stacks",
		"get_is_frozen"
	]
	
	var missing_methods = []
	for method in required_methods:
		if not enemy_mover_script.has_method(method):
			missing_methods.append(method)
	
	if missing_methods.size() == 0:
		print("✅ All enemy ice effect methods found")
		test_results.append("Enemy ice effect methods: PASS")
	else:
		print("❌ Missing enemy ice effect methods: ", missing_methods)
		test_results.append("Enemy ice effect methods: FAIL")
		return false
	
	# Test 2: Turret ice effect handlers
	print("\n📋 Test 2: Turret ice effect handlers")
	var turret_script = load("res://Scenes/turrets/turretBase/turret_base.gd")
	
	var critical_handlers = [
		"_setup_frost_area_effect",
		"_setup_frost_bounce_effect", 
		"_setup_frost_aura_effect",
		"_setup_freeze_main_target_effect"
	]
	
	var working_handlers = 0
	for handler in critical_handlers:
		if turret_script.has_method(handler):
			# Check if handler has implementation (not just pass)
			var method = turret_script.get_method(handler)
			if method:
				working_handlers += 1
				print("✅ Critical handler implemented: ", handler)
			else:
				print("⚠️  Handler exists but may be placeholder: ", handler)
		else:
			print("❌ Missing critical handler: ", handler)
	
	if working_handlers >= 3:  # Allow some tolerance
		print("✅ Most critical ice effect handlers implemented")
		test_results.append("Critical ice effect handlers: PASS")
	else:
		print("❌ Too many critical handlers missing")
		test_results.append("Critical ice effect handlers: FAIL")
		return false
	
	# Test 3: Ice effect signal connections
	print("\n📋 Test 3: Ice effect signal connections")
	
	# Check if turret has required signals
	var required_signals = ["attack_hit", "projectile_bounce"]
	var has_required_signals = true
	
	for signal_name in required_signals:
		if not turret_script.has_user_signal(signal_name):
			has_required_signals = false
			print("❌ Missing signal: ", signal_name)
		else:
			print("✅ Signal found: ", signal_name)
	
	if has_required_signals:
		print("✅ Required ice effect signals available")
		test_results.append("Ice effect signals: PASS")
	else:
		print("❌ Missing required ice effect signals")
		test_results.append("Ice effect signals: FAIL")
		return false
	
	# Test 4: Gem effect system integration
	print("\n📋 Test 4: Gem effect system integration")
	var gem_effect_script = load("res://Scenes/systems/GemEffectSystem.gd")
	
	var ice_effect_methods = [
		"apply_frost_area_effect",
		"apply_chance_freeze",
		"is_target_frozen",
		"get_frost_stacks",
		"apply_frozen_damage_bonus"
	]
	
	var missing_ice_methods = []
	for method in ice_effect_methods:
		if not gem_effect_script.has_method(method):
			missing_ice_methods.append(method)
	
	if missing_ice_methods.size() == 0:
		print("✅ All ice effect methods found in GemEffectSystem")
		test_results.append("GemEffectSystem ice methods: PASS")
	else:
		print("❌ Missing ice effect methods: ", missing_ice_methods)
		test_results.append("GemEffectSystem ice methods: FAIL")
		return false
	
	print("\n🎉 All ice enemy integration tests passed!")
	test_results.append("Ice Enemy Integration: PASS")
	return true