class_name HeroTalentSelection
extends Control

## Hero Talent Selection UI
## Manages the talent selection interface for heroes

signal talent_selected(hero: HeroBase, talent_id: String)
signal selection_cancelled()

# UI components
@onready var title_label: Label = $Panel/TitleLabel
@onready var hero_info_label: Label = $Panel/HeroInfoLabel
@onready var talent_options_container: VBoxContainer = $Panel/TalentOptionsContainer
@onready var recommendation_label: Label = $Panel/RecommendationLabel
@onready var instruction_label: Label = $Panel/InstructionLabel

# State
var current_hero: HeroBase = null
var available_talents: Array[Dictionary] = []
var talent_buttons: Array[Button] = []
var is_visible: bool = false

func _ready() -> void:
	# Setup talent option buttons
	setup_talent_buttons()
	
	# Initially hide
	hide_selection()

func setup_talent_buttons() -> void:
	"""Set up talent option buttons"""
	talent_buttons.clear()
	
	for i in range(1, 3):  # Support up to 2 talent options
		var button = talent_options_container.get_node("TalentOption%d" % i)
		if button:
			talent_buttons.append(button)
			button.pressed.connect(_on_talent_option_pressed.bind(i - 1))
			button.visible = false  # Initially hidden

func show_talent_selection(hero: HeroBase, talents: Array[Dictionary]) -> void:
	"""Show talent selection for hero"""
	if not hero or not is_instance_valid(hero):
		return
	
	current_hero = hero
	available_talents = talents
	
	# Update UI
	title_label.text = "选择天赋 (等级 %d)" % hero.current_level
	hero_info_label.text = "%s - 等级 %d" % [hero.hero_name, hero.current_level]
	
	# Update talent buttons
	update_talent_buttons()
	
	# Show recommendations
	update_recommendations()
	
	# Show UI
	visible = true
	is_visible = true

func hide_selection() -> void:
	"""Hide talent selection UI"""
	visible = false
	is_visible = false
	current_hero = null
	available_talents.clear()

func update_talent_buttons() -> void:
	"""Update talent option buttons"""
	# Hide all buttons first
	for button in talent_buttons:
		button.visible = false
		button.text = ""
		button.tooltip_text = ""
	
	# Show buttons for available talents
	for i in range(min(available_talents.size(), talent_buttons.size())):
		var talent = available_talents[i]
		var button = talent_buttons[i]
		
		button.visible = true
		button.text = talent.name
		button.tooltip_text = get_talent_description(talent)
		button.set_meta("talent_id", talent.id)
		
		# Add talent description to button
		var description_label = Label.new()
		description_label.text = talent.description
		description_label.modulate = Color.GRAY
		description_label.size_flags_vertical = 0
		button.add_child(description_label)

func update_recommendations() -> void:
	"""Update talent recommendations"""
	if not current_hero or not is_instance_valid(current_hero):
		return
	
	var talent_system = get_talent_system()
	if not talent_system:
		return
	
	var recommendations = talent_system.get_talent_recommendations(current_hero)
	if not recommendations.is_empty():
		var recommended_talent_id = recommendations[0]
		var recommended_talent = find_talent_by_id(recommended_talent_id)
		if recommended_talent:
			recommendation_label.text = "推荐: %s" % recommended_talent.name
		else:
			recommendation_label.text = ""
	else:
		recommendation_label.text = ""

func find_talent_by_id(talent_id: String) -> Dictionary:
	"""Find talent data by ID"""
	for talent in available_talents:
		if talent.id == talent_id:
			return talent
	return {}

func get_talent_description(talent_data: Dictionary) -> String:
	"""Generate detailed talent description"""
	var description = talent_data.name + "\n" + talent_data.description
	
	if talent_data.has("effects"):
		description += "\n\n效果:"
		var effects = talent_data.effects
		for effect_key in effects:
			var effect_value = effects[effect_key]
			description += "\n• " + format_effect_description(effect_key, effect_value)
	
	return description

func format_effect_description(effect_key: String, value) -> String:
	"""Format talent effect for display"""
	match effect_key:
		"shadow_strike_attack_count":
			return "无影拳攻击次数: +" + str(value)
		"charge_generation_multiplier":
			return "充能速度: +" + str(int((value - 1.0) * 100)) + "%"
		"flame_armor_aura_damage":
			return "火焰甲光环伤害: x" + str(value)
		"max_hp_multiplier":
			return "最大生命值: +" + str(int((value - 1.0) * 100)) + "%"
		"defense_bonus":
			return "防御力: +" + str(value)
		"flame_phantom_duration":
			return "末炎幻象持续时间: x" + str(value)
		"flame_phantom_damage":
			return "幻象伤害: x" + str(value)
		"aura_radius_multiplier":
			return "光环范围: +" + str(int((value - 1.0) * 100)) + "%"
		"aura_burn_chance":
			return "燃烧几率: " + str(int(value * 100)) + "%"
		_:
			return effect_key + ": " + str(value)

func _on_talent_option_pressed(index: int) -> void:
	"""Handle talent option button press"""
	if index < 0 or index >= available_talents.size():
		return
	
	var talent = available_talents[index]
	var talent_id = talent.id
	
	# Validate selection
	var talent_system = get_talent_system()
	if talent_system:
		var validation = talent_system.validate_talent_selection(current_hero, talent_id)
		if validation.valid:
			talent_selected.emit(current_hero, talent_id)
			hide_selection()
		else:
			push_warning("Talent selection validation failed: " + validation.error)

func _input(event: InputEvent) -> void:
	"""Handle input for closing selection"""
	if not is_visible:
		return
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			selection_cancelled.emit()
			hide_selection()

func get_talent_system() -> HeroTalentSystem:
	"""Get reference to talent system"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("HeroTalentSystem") as HeroTalentSystem

func is_selection_active() -> bool:
	"""Check if selection is currently active"""
	return is_visible

func get_current_hero() -> HeroBase:
	"""Get current hero being offered talents"""
	return current_hero if is_instance_valid(current_hero) else null

# External interface for HeroManager
func setup_from_hero_manager(hero_manager: HeroManager) -> void:
	"""Setup selection from hero manager"""
	if not hero_manager:
		return
	
	# Connect to hero manager signals
	if hero_manager.has_signal("talent_selection_requested"):
		hero_manager.connect("talent_selection_requested", _on_talent_selection_requested)

func _on_talent_selection_requested(hero: HeroBase, talents: Array[Dictionary]) -> void:
	"""Handle talent selection request"""
	show_talent_selection(hero, talents)

func _exit_tree() -> void:
	"""Clean up connections"""
	# Disconnect from hero manager if connected
	var hero_manager = get_hero_manager()
	if hero_manager:
		if hero_manager.has_signal("talent_selection_requested"):
			if hero_manager.is_connected("talent_selection_requested", _on_talent_selection_requested):
				hero_manager.disconnect("talent_selection_requested", _on_talent_selection_requested)

func get_hero_manager() -> HeroManager:
	"""Get reference to hero manager"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("HeroManager") as HeroManager