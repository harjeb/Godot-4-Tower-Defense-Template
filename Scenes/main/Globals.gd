extends Node

## Game-wide signals using Godot 4.4 syntax
signal gold_changed(new_gold: int)
signal base_hp_changed(new_hp: int, max_hp: int)
signal wave_started(wave_count: int, enemy_count: int)
signal wave_cleared(wait_time: float)
signal enemy_destroyed(remain: int)

## Hero System Signals
signal hero_deployed(hero: Node, position: Vector2)
signal hero_died(hero: Node)
signal hero_respawned(hero: Node) 
signal hero_skill_cast(hero: Node, skill: Resource)
signal level_modifiers_generated(modifiers: Array)
signal talent_selection_available(hero: Node, level: int)
signal hero_selection_offered(available_heroes: Array[String])
signal hero_experience_gained(hero: Node, amount: int)

## Game state variables with proper typing
var selected_map: String = ""
var main_node: Node2D
var turrets_node: Node2D
var projectiles_node: Node2D
var current_map: Node2D
var hud: Control

func restart_current_level() -> void:
	if not is_instance_valid(current_map):
		push_error("Cannot restart: current_map is invalid")
		return
	
	var scene_path = current_map.scene_file_path
	var current_level_scene = Data.load_resource_safe(scene_path, "PackedScene")
	if not current_level_scene:
		return
	
	current_map.queue_free()
	var new_map = current_level_scene.instantiate()
	if new_map.has_method("set_map_type"):
		new_map.set_map_type(selected_map)
	elif "map_type" in new_map:
		new_map.map_type = selected_map
	
	if is_instance_valid(main_node):
		main_node.add_child(new_map)
		current_map = new_map
	
	if is_instance_valid(hud) and hud.has_method("reset"):
		hud.reset()

## Hero System Integration Methods

func deploy_hero(hero_type: String, position: Vector2) -> Node:
	"""Deploy a hero at specified position"""
	var hero_manager = get_hero_manager()
	if not hero_manager:
		push_error("HeroManager not available")
		return null
	
	var hero = hero_manager.deploy_hero(hero_type, position)
	if hero:
		hero_deployed.emit(hero, position)
	
	return hero

func get_hero_manager() -> Node:
	"""Get reference to hero manager"""
	if not is_instance_valid(main_node):
		return null
	
	var manager = main_node.get_node_or_null("HeroManager")
	if not manager:
		# Try finding in main scene children
		for child in main_node.get_children():
			if child.get_script() and child.get_script().get_global_name() == "HeroManager":
				return child
	
	return manager

func get_level_modifier_system() -> Node:
	"""Get reference to level modifier system"""
	if not is_instance_valid(main_node):
		return null
	
	return main_node.get_node_or_null("LevelModifierSystem")

func get_hero_talent_system() -> Node:
	"""Get reference to hero talent system"""
	if not is_instance_valid(main_node):
		return null
	
	return main_node.get_node_or_null("HeroTalentSystem")

func get_deployed_heroes() -> Array:
	"""Get all currently deployed heroes"""
	var hero_manager = get_hero_manager()
	if hero_manager and hero_manager.has_method("get_deployed_heroes"):
		return hero_manager.get_deployed_heroes()
	elif hero_manager and "deployed_heroes" in hero_manager:
		return hero_manager.deployed_heroes
	
	return []

func get_living_heroes() -> Array:
	"""Get all currently living heroes"""
	var heroes = get_deployed_heroes()
	var living_heroes: Array = []
	
	for hero in heroes:
		if is_instance_valid(hero) and hero.get("is_alive"):
			living_heroes.append(hero)
	
	return living_heroes

func request_hero_selection() -> void:
	"""Request hero selection from player"""
	var hero_manager = get_hero_manager()
	if hero_manager:
		hero_manager.offer_hero_selection()

func apply_wave_modifiers(modifiers: Array) -> void:
	"""Apply wave modifiers to heroes"""
	var level_modifier_system = get_level_modifier_system()
	if level_modifier_system:
		level_modifier_system.apply_level_modifiers(modifiers)

func notify_hero_experience_gained(hero: Node, amount: int) -> void:
	"""Notify systems of hero experience gain"""
	hero_experience_gained.emit(hero, amount)

func get_hero_system_status() -> Dictionary:
	"""Get overview of hero system status"""
	var hero_manager = get_hero_manager()
	var talent_system = get_hero_talent_system()
	var modifier_system = get_level_modifier_system()
	
	return {
		"hero_manager_available": hero_manager != null,
		"talent_system_available": talent_system != null,
		"modifier_system_available": modifier_system != null,
		"deployed_heroes": get_deployed_heroes().size(),
		"living_heroes": get_living_heroes().size()
	}

func show_error_dialog(message: String, title: String = "错误") -> void:
	"""显示错误对话框，防止debug日志刷屏"""
	if is_instance_valid(hud) and hud.has_node("ErrorDialogUI"):
		var error_dialog = hud.get_node("ErrorDialogUI")
		if error_dialog and error_dialog.has_method("show_error"):
			error_dialog.show_error(message, title)
	else:
		# 如果HUD不可用，仍然使用print输出
		print("错误: ", message)

func _ready():
	# 执行启动前检查
	if ErrorHandler and ErrorHandler.has_method("perform_startup_checks"):
		ErrorHandler.perform_startup_checks()
	
	# 设置全局错误处理
	setup_global_error_handling()

func setup_global_error_handling():
	"""设置全局错误处理系统"""
	# 设置自定义错误处理
	set_meta("error_handler_enabled", true)
	
	# 启用错误监控
	call_deferred("start_error_monitoring")
	
	# 设置全局编译时错误拦截
	if ErrorHandler and ErrorHandler.has_method("setup_global_error_monitoring"):
		ErrorHandler.setup_global_error_monitoring()

func start_error_monitoring():
	"""启动错误监控"""
	print("错误监控系统已启动")
	# 在这里可以添加其他错误监控逻辑
