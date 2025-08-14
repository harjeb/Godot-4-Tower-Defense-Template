class_name HeroSelection
extends Control

## Hero Selection UI
## Manages the 5-choose-1 hero selection interface

signal hero_selected(hero_type: String)
signal selection_cancelled()

# UI components
@onready var title_label: Label = $Panel/TitleLabel
@onready var description_label: Label = $Panel/DescriptionLabel
@onready var hero_options_container: VBoxContainer = $Panel/HeroOptionsContainer

# State
var available_heroes: Array[String] = []
var hero_buttons: Array[Button] = []
var is_visible: bool = false

func _ready() -> void:
	# Connect hero option buttons
	setup_hero_buttons()
	
	# Initially hide
	hide_selection()

func setup_hero_buttons() -> void:
	"""Set up hero option buttons"""
	hero_buttons.clear()
	
	for i in range(1, 6):
		var button = hero_options_container.get_node("HeroOption%d" % i)
		if button:
			hero_buttons.append(button)
			button.pressed.connect(_on_hero_option_pressed.bind(i - 1))

func show_hero_selection(hero_options: Array[String]) -> void:
	"""Show hero selection with given options"""
	available_heroes = hero_options
	
	if available_heroes.size() != 5:
		push_error("Hero selection requires exactly 5 options")
		return
	
	# Update button texts and data
	for i in range(5):
		var hero_type = available_heroes[i]
		var button = hero_buttons[i]
		
		if Data.heroes.has(hero_type):
			var hero_data = Data.heroes[hero_type]
			button.text = hero_data.get("name", hero_type)
			button.set_meta("hero_type", hero_type)
			
			# Set button tooltip with hero description
			var description = hero_data.get("description", "未知英雄")
			button.tooltip_text = description
		else:
			button.text = "未知英雄"
			button.set_meta("hero_type", "")
	
	# Show UI
	visible = true
	is_visible = true

func hide_selection() -> void:
	"""Hide hero selection UI"""
	visible = false
	is_visible = false

func _on_hero_option_pressed(index: int) -> void:
	"""Handle hero option button press"""
	if index < 0 or index >= available_heroes.size():
		return
	
	var hero_type = available_heroes[index]
	if not hero_type.is_empty():
		hero_selected.emit(hero_type)
		hide_selection()

func _input(event: InputEvent) -> void:
	"""Handle input for closing selection"""
	if not is_visible:
		return
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			selection_cancelled.emit()
			hide_selection()

func update_hero_descriptions() -> void:
	"""Update hero descriptions with current game state"""
	# This could be enhanced to show dynamic information
	# like current hero count, wave information, etc.
	var wave_manager = get_wave_manager()
	if wave_manager:
		var current_wave = wave_manager.current_wave
		description_label.text = "第 %d 波 - 从以下5个英雄中选择1个" % current_wave

func get_wave_manager() -> Node:
	"""Get reference to wave manager"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("WaveManager")

func is_selection_active() -> bool:
	"""Check if selection is currently active"""
	return is_visible

func get_selected_hero_type() -> String:
	"""Get the currently selected hero type (for testing)"""
	# This would normally be handled by the signal
	# Added for testing purposes
	return available_heroes[0] if not available_heroes.is_empty() else ""

# External interface for HeroManager
func setup_from_hero_manager(hero_manager: Node) -> void:
	"""Setup selection from hero manager"""
	if not hero_manager:
		return
	
	# Connect to hero manager signals
	if hero_manager.has_signal("hero_selection_available"):
		hero_manager.connect("hero_selection_available", _on_hero_selection_available)
	
	if hero_manager.has_signal("hero_selection_completed"):
		hero_manager.connect("hero_selection_completed", _on_hero_selection_completed)

func _on_hero_selection_available(available_heroes: Array[String]) -> void:
	"""Handle hero selection available signal"""
	show_hero_selection(available_heroes)

func _on_hero_selection_completed(selected_hero: String) -> void:
	"""Handle hero selection completed signal"""
	hide_selection()

func _exit_tree() -> void:
	"""Clean up connections"""
	# Disconnect from hero manager if connected
	var hero_manager = get_hero_manager()
	if hero_manager:
		if hero_manager.has_signal("hero_selection_available"):
			if hero_manager.is_connected("hero_selection_available", _on_hero_selection_available):
				hero_manager.disconnect("hero_selection_available", _on_hero_selection_available)
		
		if hero_manager.has_signal("hero_selection_completed"):
			if hero_manager.is_connected("hero_selection_completed", _on_hero_selection_completed):
				hero_manager.disconnect("hero_selection_completed", _on_hero_selection_completed)

func get_hero_manager() -> Node:
	"""Get reference to hero manager"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("HeroManager")