class_name TechTreeUI
extends Control

signal talent_tree_closed()

var tech_point_system: Node
var talent_buttons: Dictionary = {}
var tech_points_label: Label
var main_container: ScrollContainer

func _ready():
	find_tech_point_system()
	setup_ui()
	if tech_point_system:
		tech_point_system.tech_points_changed.connect(_on_tech_points_changed)
		tech_point_system.talent_upgraded.connect(_on_talent_upgraded)

func find_tech_point_system():
	tech_point_system = get_tree().current_scene.get_node_or_null("TechPointSystem")

func setup_ui():
	# Create main container
	var bg_panel = Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	bg_panel.add_child(main_vbox)
	
	# Title and close button
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "天赋树"
	title.add_theme_font_size_override("font_size", 24)
	header_hbox.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)
	
	var close_button = Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(80, 35)
	close_button.pressed.connect(_on_close_button_pressed)
	header_hbox.add_child(close_button)
	
	# Tech points display
	tech_points_label = Label.new()
	tech_points_label.text = "科技点数: 0"
	tech_points_label.add_theme_font_size_override("font_size", 18)
	main_vbox.add_child(tech_points_label)
	
	# Scrollable content
	main_container = ScrollContainer.new()
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(main_container)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 5)
	main_container.add_child(scroll_vbox)
	
	# Create talent buttons
	create_talent_buttons(scroll_vbox)
	
	# Update display
	update_ui()

func create_talent_buttons(parent: VBoxContainer):
	for talent_id in Data.tech_tree.keys():
		var talent_data = Data.tech_tree[talent_id]
		
		# Create talent container
		var talent_panel = Panel.new()
		talent_panel.custom_minimum_size = Vector2(0, 80)
		parent.add_child(talent_panel)
		
		var talent_hbox = HBoxContainer.new()
		talent_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		talent_hbox.add_theme_constant_override("separation", 10)
		talent_panel.add_child(talent_hbox)
		
		# Talent info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		talent_hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = talent_data.name
		name_label.add_theme_font_size_override("font_size", 16)
		info_vbox.add_child(name_label)
		
		var desc_label = Label.new()
		desc_label.text = talent_data.description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.modulate = Color.LIGHT_GRAY
		info_vbox.add_child(desc_label)
		
		var level_label = Label.new()
		var max_level = 1
		if talent_data.has("max_level"):
			max_level = talent_data.get("max_level")
		level_label.text = "等级: 0/%d" % max_level
		level_label.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(level_label)
		
		# Cost and upgrade button
		var button_vbox = VBoxContainer.new()
		button_vbox.custom_minimum_size = Vector2(100, 0)
		talent_hbox.add_child(button_vbox)
		
		var cost_label = Label.new()
		cost_label.text = "消耗: %d点" % talent_data.cost
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 12)
		button_vbox.add_child(cost_label)
		
		var upgrade_button = Button.new()
		upgrade_button.text = "升级"
		upgrade_button.custom_minimum_size = Vector2(80, 35)
		upgrade_button.pressed.connect(_on_talent_button_pressed.bind(talent_id))
		button_vbox.add_child(upgrade_button)
		
		# Store references
		talent_buttons[talent_id] = {
			"button": upgrade_button,
			"level_label": level_label,
			"cost_label": cost_label,
			"panel": talent_panel
		}

func update_ui():
	if not tech_point_system:
		return
	
	# Update tech points display
	var current_points = tech_point_system.get_tech_points()
	tech_points_label.text = "科技点数: %d" % current_points
	
	# Update talent buttons
	for talent_id in talent_buttons.keys():
		var components = talent_buttons[talent_id]
		var talent_data = Data.tech_tree[talent_id]
		var current_level = tech_point_system.get_talent_level(talent_id)
		var max_level = 1
		if talent_data.has("max_level"):
			max_level = talent_data.get("max_level")
		var can_upgrade = tech_point_system.can_upgrade_talent(talent_id)
		
		# Update level display
		components.level_label.text = "等级: %d/%d" % [current_level, max_level]
		
		# Update button state
		components.button.disabled = not can_upgrade
		if current_level >= max_level:
			components.button.text = "已满级"
		elif can_upgrade:
			components.button.text = "升级"
		else:
			components.button.text = "无法升级"
		
		# Update panel appearance based on requirements
		var requirements_met = true
		var requirements = []
		if talent_data.has("requirements"):
			requirements = talent_data.get("requirements")
		for requirement in requirements:
			if tech_point_system.get_talent_level(requirement) == 0:
				requirements_met = false
				break
		
		if not requirements_met:
			components.panel.modulate = Color(0.7, 0.7, 0.7)
		else:
			components.panel.modulate = Color.WHITE

func _on_talent_button_pressed(talent_id: String):
	if tech_point_system and tech_point_system.can_upgrade_talent(talent_id):
		tech_point_system.upgrade_talent(talent_id)

func _on_tech_points_changed(current_points: int):
	update_ui()

func _on_talent_upgraded(talent_id: String, new_level: int):
	update_ui()

func _on_close_button_pressed():
	hide()
	talent_tree_closed.emit()

func open_talent_tree():
	show()
	update_ui()

func close_talent_tree():
	hide()
	talent_tree_closed.emit()