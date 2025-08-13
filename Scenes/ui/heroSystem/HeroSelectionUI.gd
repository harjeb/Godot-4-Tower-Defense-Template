class_name HeroSelectionUI
extends Control

## Hero Selection User Interface
## Handles 5-choose-1 hero selection and talent selection dialogs

signal hero_selected(hero_type: String)
signal talent_selected(hero: HeroBase, talent_id: String)
signal selection_cancelled()

# UI References
@onready var hero_selection_panel: Panel = $HeroSelectionPanel
@onready var hero_grid_container: GridContainer = $HeroSelectionPanel/VBoxContainer/HeroGridContainer
@onready var selection_title: Label = $HeroSelectionPanel/VBoxContainer/SelectionTitle
@onready var selection_description: Label = $HeroSelectionPanel/VBoxContainer/SelectionDescription
@onready var cancel_button: Button = $HeroSelectionPanel/VBoxContainer/ButtonContainer/CancelButton
@onready var confirm_button: Button = $HeroSelectionPanel/VBoxContainer/ButtonContainer/ConfirmButton

@onready var talent_selection_panel: Panel = $TalentSelectionPanel
@onready var talent_container: VBoxContainer = $TalentSelectionPanel/VBoxContainer/TalentContainer
@onready var talent_title: Label = $TalentSelectionPanel/VBoxContainer/TalentTitle
@onready var talent_hero_info: Label = $TalentSelectionPanel/VBoxContainer/HeroInfo

# Selection state
var current_selection_type: String = "" # "hero" or "talent"
var available_heroes: Array[String] = []
var selected_hero_type: String = ""
var current_hero_for_talent: HeroBase
var available_talents: Array[Dictionary] = []
var selected_talent_id: String = ""

# UI Prefabs and resources
const HERO_OPTION_SCENE = preload("res://Scenes/ui/heroSystem/HeroOptionButton.tscn")
const TALENT_OPTION_SCENE = preload("res://Scenes/ui/heroSystem/TalentOptionButton.tscn")

func _ready() -> void:
	# Set up UI connections
	setup_ui_connections()
	
	# Initially hide all panels
	hide_all_panels()
	
	# Connect to hero system signals
	setup_hero_system_connections()

func setup_ui_connections() -> void:
	"""Set up UI button connections"""
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)

func setup_hero_system_connections() -> void:
	"""Connect to hero system signals"""
	# Connect to hero manager signals
	var hero_manager = Globals.get_hero_manager()
	if hero_manager:
		if hero_manager.has_signal("hero_selection_available"):
			hero_manager.connect("hero_selection_available", _on_hero_selection_available)
	
	# Connect to talent system signals
	var talent_system = Globals.get_hero_talent_system()
	if talent_system:
		if talent_system.has_signal("talent_selection_offered"):
			talent_system.connect("talent_selection_offered", _on_talent_selection_offered)

func hide_all_panels() -> void:
	"""Hide all selection panels"""
	if hero_selection_panel:
		hero_selection_panel.visible = false
	
	if talent_selection_panel:
		talent_selection_panel.visible = false
	
	current_selection_type = ""

func show_hero_selection(hero_types: Array[String]) -> void:
	"""Show hero selection interface"""
	if hero_types.size() < 2:
		push_warning("Not enough heroes for selection")
		return
	
	# Store selection data
	available_heroes = hero_types.duplicate()
	selected_hero_type = ""
	current_selection_type = "hero"
	
	# Set up UI
	setup_hero_selection_ui()
	
	# Show panel
	if hero_selection_panel:
		hero_selection_panel.visible = true
	
	# Create hero option buttons
	create_hero_option_buttons()

func setup_hero_selection_ui() -> void:
	"""Set up hero selection UI elements"""
	if selection_title:
		selection_title.text = "选择英雄"
	
	if selection_description:
		selection_description.text = "从以下英雄中选择一个进行部署："
	
	if confirm_button:
		confirm_button.text = "确认选择"
		confirm_button.disabled = true
	
	if cancel_button:
		cancel_button.text = "取消"
		cancel_button.disabled = false

func create_hero_option_buttons() -> void:
	"""Create hero selection buttons"""
	if not hero_grid_container:
		return
	
	# Clear existing buttons
	clear_container_children(hero_grid_container)
	
	# Create button for each hero
	for hero_type in available_heroes:
		var hero_button = create_hero_option_button(hero_type)
		if hero_button:
			hero_grid_container.add_child(hero_button)

func create_hero_option_button(hero_type: String) -> Control:
	"""Create individual hero option button"""
	if not Data.heroes.has(hero_type):
		push_error("Hero type not found: " + hero_type)
		return null
	
	var hero_data = Data.heroes[hero_type]
	
	# Create button container
	var button_container = VBoxContainer.new()
	button_container.custom_minimum_size = Vector2(200, 250)
	
	# Create hero button
	var hero_button = Button.new()
	hero_button.text = hero_data.get("name", hero_type)
	hero_button.custom_minimum_size = Vector2(180, 40)
	hero_button.pressed.connect(func(): _on_hero_option_selected(hero_type))
	
	# Create hero preview (sprite)
	var hero_preview = TextureRect.new()
	hero_preview.custom_minimum_size = Vector2(150, 150)
	hero_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hero_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var sprite_path = hero_data.get("sprite", "")
	if not sprite_path.is_empty():
		var texture = Data.load_resource_safe(sprite_path, "Texture2D")
		if texture:
			hero_preview.texture = texture
	
	# Create hero description
	var hero_description = Label.new()
	hero_description.text = hero_data.get("description", "")
	hero_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_description.custom_minimum_size = Vector2(180, 60)
	hero_description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	# Add to container
	button_container.add_child(hero_preview)
	button_container.add_child(hero_button)
	button_container.add_child(hero_description)
	
	return button_container

func show_talent_selection(hero: HeroBase, talents: Array[Dictionary]) -> void:
	"""Show talent selection interface"""
	if not hero or talents.size() < 2:
		push_warning("Invalid talent selection parameters")
		return
	
	# Store selection data
	current_hero_for_talent = hero
	available_talents = talents.duplicate(true)
	selected_talent_id = ""
	current_selection_type = "talent"
	
	# Set up UI
	setup_talent_selection_ui()
	
	# Show panel
	if talent_selection_panel:
		talent_selection_panel.visible = true
	
	# Create talent option buttons
	create_talent_option_buttons()

func setup_talent_selection_ui() -> void:
	"""Set up talent selection UI elements"""
	if talent_title:
		talent_title.text = "天赋选择"
	
	if talent_hero_info and current_hero_for_talent:
		var hero_info = "%s (Lv.%d)" % [current_hero_for_talent.hero_name, current_hero_for_talent.current_level]
		talent_hero_info.text = "英雄：" + hero_info

func create_talent_option_buttons() -> void:
	"""Create talent selection buttons"""
	if not talent_container:
		return
	
	# Clear existing buttons
	clear_container_children(talent_container)
	
	# Create button for each talent
	for talent in available_talents:
		var talent_button = create_talent_option_button(talent)
		if talent_button:
			talent_container.add_child(talent_button)

func create_talent_option_button(talent_data: Dictionary) -> Control:
	"""Create individual talent option button"""
	var talent_container = VBoxContainer.new()
	talent_container.custom_minimum_size = Vector2(400, 120)
	
	# Create talent button
	var talent_button = Button.new()
	talent_button.text = talent_data.get("name", "Unknown Talent")
	talent_button.custom_minimum_size = Vector2(380, 40)
	talent_button.pressed.connect(func(): _on_talent_option_selected(talent_data.id))
	
	# Create talent description
	var talent_description = Label.new()
	var description_text = talent_data.get("description", "")
	
	# Add effect details
	if talent_data.has("effects"):
		description_text += "\n效果："
		var effects = talent_data.effects
		for effect_key in effects:
			var effect_value = effects[effect_key]
			description_text += "\n• " + format_talent_effect_description(effect_key, effect_value)
	
	talent_description.text = description_text
	talent_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talent_description.custom_minimum_size = Vector2(380, 70)
	talent_description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	# Add to container
	talent_container.add_child(talent_button)
	talent_container.add_child(talent_description)
	
	return talent_container

func format_talent_effect_description(effect_key: String, value) -> String:
	"""Format talent effect for display"""
	match effect_key:
		"shadow_strike_attack_count":
			return "无影拳攻击次数 +" + str(value)
		"charge_generation_multiplier":
			return "充能速度 +" + str(int((value - 1.0) * 100)) + "%"
		"flame_armor_aura_damage":
			return "火焰甲光环伤害 x" + str(value)
		"max_hp_multiplier":
			return "最大生命值 +" + str(int((value - 1.0) * 100)) + "%"
		"defense_bonus":
			return "防御力 +" + str(value)
		"flame_phantom_duration":
			return "末炎幻象持续时间 x" + str(value)
		"flame_phantom_damage":
			return "幻象伤害 x" + str(value)
		"aura_radius_multiplier":
			return "光环范围 +" + str(int((value - 1.0) * 100)) + "%"
		"aura_burn_chance":
			return "光环燃烧几率 " + str(int(value * 100)) + "%"
		_:
			return effect_key + ": " + str(value)

func clear_container_children(container: Node) -> void:
	"""Clear all children from container"""
	if not container:
		return
	
	for child in container.get_children():
		child.queue_free()

func _on_hero_option_selected(hero_type: String) -> void:
	"""Handle hero option selection"""
	selected_hero_type = hero_type
	
	# Update UI
	if confirm_button:
		confirm_button.disabled = false
	
	# Update visual feedback
	highlight_selected_hero_option(hero_type)

func highlight_selected_hero_option(hero_type: String) -> void:
	"""Highlight selected hero option"""
	if not hero_grid_container:
		return
	
	# Reset all button styles
	for child in hero_grid_container.get_children():
		var button = child.get_child(1) as Button # Button is second child
		if button:
			button.modulate = Color.WHITE
	
	# Highlight selected option
	var index = available_heroes.find(hero_type)
	if index >= 0 and index < hero_grid_container.get_child_count():
		var selected_child = hero_grid_container.get_child(index)
		var selected_button = selected_child.get_child(1) as Button
		if selected_button:
			selected_button.modulate = Color.LIGHT_GREEN

func _on_talent_option_selected(talent_id: String) -> void:
	"""Handle talent option selection"""
	selected_talent_id = talent_id
	
	# Update visual feedback
	highlight_selected_talent_option(talent_id)
	
	# Auto-confirm talent selection
	_confirm_talent_selection()

func highlight_selected_talent_option(talent_id: String) -> void:
	"""Highlight selected talent option"""
	if not talent_container:
		return
	
	# Reset all button styles
	for child in talent_container.get_children():
		var button = child.get_child(0) as Button
		if button:
			button.modulate = Color.WHITE
	
	# Highlight selected option
	var index = -1
	for i in available_talents.size():
		if available_talents[i].id == talent_id:
			index = i
			break
	
	if index >= 0 and index < talent_container.get_child_count():
		var selected_child = talent_container.get_child(index)
		var selected_button = selected_child.get_child(0) as Button
		if selected_button:
			selected_button.modulate = Color.LIGHT_GREEN

func _on_confirm_pressed() -> void:
	"""Handle confirm button press"""
	match current_selection_type:
		"hero":
			_confirm_hero_selection()
		"talent":
			_confirm_talent_selection()

func _confirm_hero_selection() -> void:
	"""Confirm hero selection"""
	if selected_hero_type.is_empty():
		push_warning("No hero selected")
		return
	
	# Emit selection signal
	hero_selected.emit(selected_hero_type)
	
	# Hide panel
	hide_all_panels()
	
	# Notify hero manager
	var hero_manager = Globals.get_hero_manager()
	if hero_manager:
		hero_manager.select_hero(selected_hero_type)

func _confirm_talent_selection() -> void:
	"""Confirm talent selection"""
	if selected_talent_id.is_empty() or not current_hero_for_talent:
		push_warning("Invalid talent selection")
		return
	
	# Emit selection signal
	talent_selected.emit(current_hero_for_talent, selected_talent_id)
	
	# Hide panel
	hide_all_panels()
	
	# Apply talent
	var talent_system = Globals.get_hero_talent_system()
	if talent_system:
		talent_system.apply_talent(current_hero_for_talent, selected_talent_id)

func _on_cancel_pressed() -> void:
	"""Handle cancel button press"""
	selection_cancelled.emit()
	hide_all_panels()

# Signal handlers for hero system events
func _on_hero_selection_available(hero_types: Array[String]) -> void:
	"""Handle hero selection availability"""
	show_hero_selection(hero_types)

func _on_talent_selection_offered(hero: HeroBase, talents: Array[Dictionary]) -> void:
	"""Handle talent selection offer"""
	show_talent_selection(hero, talents)

# Utility methods for external use
func is_selection_active() -> bool:
	"""Check if any selection is currently active"""
	return not current_selection_type.is_empty()

func get_current_selection_type() -> String:
	"""Get current selection type"""
	return current_selection_type

func force_close() -> void:
	"""Force close all selection panels"""
	hide_all_panels()
	selection_cancelled.emit()

func show_hero_preview(hero_type: String) -> void:
	"""Show detailed hero preview (can be expanded)"""
	if not Data.heroes.has(hero_type):
		return
	
	var hero_data = Data.heroes[hero_type]
	# Could show additional preview window with stats, skills, etc.
	print("Hero Preview: ", hero_data.name)