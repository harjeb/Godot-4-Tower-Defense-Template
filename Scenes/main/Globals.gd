extends Node

## Game-wide signals using Godot 4.4 syntax
signal gold_changed(new_gold: int)
signal base_hp_changed(new_hp: int, max_hp: int)
signal wave_started(wave_count: int, enemy_count: int)
signal wave_cleared(wait_time: float)
signal enemy_destroyed(remain: int)

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
