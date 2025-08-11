extends Control
class_name SettingsUI

signal settings_closed

# UI 元素
@onready var panel: Panel
@onready var title_label: Label
@onready var close_button: Button
@onready var save_button: Button
@onready var reset_button: Button
@onready var tab_container: TabContainer
@onready var turret_settings_container: VBoxContainer
@onready var general_settings_container: VBoxContainer

# 数据存储
var original_turret_data: Dictionary = {}
var modified_turret_data: Dictionary = {}

func _ready():
	# 创建UI元素
	setup_ui()
	
	# 加载炮塔数据
	load_turret_data()
	
	# 创建炮塔设置面板
	create_turret_settings_panel()
	
	# 设置输入处理
	set_process_input(true)

func setup_ui():
	# 创建主面板
	panel = Panel.new()
	panel.size = Vector2(600, 500)
	panel.position = Vector2(100, 100)
	add_child(panel)
	
	# 创建标题
	title_label = Label.new()
	title_label.text = "游戏设置"
	title_label.position = Vector2(10, 10)
	title_label.size = Vector2(200, 30)
	panel.add_child(title_label)
	
	# 创建关闭按钮
	close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(560, 10)
	close_button.size = Vector2(30, 30)
	close_button.pressed.connect(_on_close_button_pressed)
	panel.add_child(close_button)
	
	# 创建保存按钮
	save_button = Button.new()
	save_button.text = "保存设置"
	save_button.position = Vector2(400, 10)
	save_button.size = Vector2(80, 30)
	save_button.pressed.connect(_on_save_button_pressed)
	panel.add_child(save_button)
	
	# 创建重置按钮
	reset_button = Button.new()
	reset_button.text = "重置"
	reset_button.position = Vector2(310, 10)
	reset_button.size = Vector2(80, 30)
	reset_button.pressed.connect(_on_reset_button_pressed)
	panel.add_child(reset_button)
	
	# 创建标签容器
	tab_container = TabContainer.new()
	tab_container.position = Vector2(10, 50)
	tab_container.size = Vector2(580, 440)
	panel.add_child(tab_container)
	
	# 创建炮塔设置标签页
	turret_settings_container = VBoxContainer.new()
	turret_settings_container.name = "炮塔设置"
	tab_container.add_child(turret_settings_container)
	
	# 创建通用设置标签页
	general_settings_container = VBoxContainer.new()
	general_settings_container.name = "通用设置"
	tab_container.add_child(general_settings_container)

func load_turret_data():
	# 复制原始数据用于重置
	for turret_id in Data.turrets.keys():
		original_turret_data[turret_id] = Data.turrets[turret_id].duplicate(true)
		modified_turret_data[turret_id] = Data.turrets[turret_id].duplicate(true)

func create_turret_settings_panel():
	# 为每个炮塔类型创建设置面板
	for turret_id in modified_turret_data.keys():
		var turret_data = modified_turret_data[turret_id]
		
		# 创建炮塔分组框
		var turret_group = VBoxContainer.new()
		turret_group.size_flags_vertical = Control.SIZE_EXPAND_FILL
		turret_settings_container.add_child(turret_group)
		
		# 创建炮塔标题
		var turret_title = Label.new()
		turret_title.text = "%s (%s)" % [turret_data.name, turret_id]
		turret_title.add_theme_font_size_override("font_size", 16)
		turret_group.add_child(turret_title)
		
		# 创建属性编辑器
		create_stat_editors(turret_group, turret_id, turret_data)
		
		# 添加分隔线
		var separator = HSeparator.new()
		turret_settings_container.add_child(separator)

func create_stat_editors(container: VBoxContainer, turret_id: String, turret_data: Dictionary):
	# 创建统计数据编辑器
	var stats_container = VBoxContainer.new()
	container.add_child(stats_container)
	
	# 基本属性
	var cost_hbox = HBoxContainer.new()
	var cost_label = Label.new()
	cost_label.text = "建造成本:"
	cost_hbox.add_child(cost_label)
	stat_spinbox.min = 0
		stat_spinbox.max = 1000
		stat_spinbox.step = 1
		stat_spinbox.value = turret_data.cost
		stat_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_spinbox.connect("value_changed", _on_stat_value_changed.bind(turret_id, "cost"))
		cost_hbox.add_child(cost_spinbox)
	stats_container.add_child(cost_hbox)
	
	var upgrade_cost_hbox = HBoxContainer.new()
	var upgrade_cost_label = Label.new()
	upgrade_cost_label.text = "升级成本:"
	upgrade_cost_hbox.add_child(upgrade_cost_label)
	upgrade_cost_spinbox.min = 0
		upgrade_cost_spinbox.max = 1000
		upgrade_cost_spinbox.step = 1
		upgrade_cost_spinbox.value = turret_data.upgrade_cost
		upgrade_cost_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade_cost_spinbox.connect("value_changed", _on_stat_value_changed.bind(turret_id, "upgrade_cost"))
		upgrade_cost_hbox.add_child(upgrade_cost_spinbox)
	stats_container.add_child(upgrade_cost_hbox)
	
	var max_level_hbox = HBoxContainer.new()
	var max_level_label = Label.new()
	max_level_label.text = "最高等级:"
	max_level_hbox.add_child(max_level_label)
	var max_level_spinbox = SpinBox.new()
	max_level_spinbox.min = 1
	max_level_spinbox.max = 10
	max_level_spinbox.step = 1
	max_level_spinbox.value = turret_data.max_level
	max_level_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	max_level_spinbox.connect("value_changed", _on_stat_value_changed.bind(turret_id, "max_level"))
	max_level_hbox.add_child(max_level_spinbox)
	stats_container.add_child(max_level_hbox)
	
	# 统计属性
	for stat_name in turret_data.stats.keys():
		var stat_value = turret_data.stats[stat_name]
		var stat_hbox = HBoxContainer.new()
		
		var stat_label = Label.new()
		stat_label.text = "%s:" % Data.stats.get(stat_name, {"name": stat_name}).name
		stat_hbox.add_child(stat_label)
		
		var stat_spinbox = SpinBox.new()
		stat_spinbox.min = 0
		stat_spinbox.max = 10000
		stat_spinbox.step = 0.1
		stat_spinbox.value = stat_value
		stat_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_spinbox.connect("value_changed", _on_stat_value_changed.bind(turret_id, "stats", stat_name))
		stat_hbox.add_child(stat_spinbox)
		
		stats_container.add_child(stat_hbox)
	
	# 升级属性
	var upgrades_title = Label.new()
	upgrades_title.text = "升级属性:"
	upgrades_title.add_theme_font_size_override("font_size", 14)
	stats_container.add_child(upgrades_title)
	
	for upgrade_name in turret_data.upgrades.keys():
		var upgrade_data = turret_data.upgrades[upgrade_name]
		var upgrade_hbox = HBoxContainer.new()
		
		var upgrade_label = Label.new()
		upgrade_label.text = "%s:" % Data.stats.get(upgrade_name, {"name": upgrade_name}).name
		upgrade_hbox.add_child(upgrade_label)
		
		var amount_spinbox = SpinBox.new()
		amount_spinbox.min = -100
		amount_spinbox.max = 100
		amount_spinbox.step = 0.1
		amount_spinbox.value = upgrade_data.amount
		amount_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		amount_spinbox.connect("value_changed", _on_upgrade_value_changed.bind(turret_id, upgrade_name, "amount"))
		upgrade_hbox.add_child(amount_spinbox)
		
		var multiplies_check = CheckBox.new()
		multiplies_check.text = "倍增"
		multiplies_check.button_pressed = upgrade_data.multiplies
		multiplies_check.connect("toggled", _on_upgrade_value_changed.bind(turret_id, upgrade_name, "multiplies"))
		upgrade_hbox.add_child(multiplies_check)
		
		stats_container.add_child(upgrade_hbox)

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_settings"):
		close_settings()

func _on_stat_value_changed(value, turret_id: String, category: String, stat_name: String = ""):
	if category == "stats":
		modified_turret_data[turret_id][category][stat_name] = value
	else:
		modified_turret_data[turret_id][category] = value

func _on_upgrade_value_changed(value, turret_id: String, upgrade_name: String, property: String):
	modified_turret_data[turret_id]["upgrades"][upgrade_name][property] = value

func _on_close_button_pressed():
	close_settings()

func _on_save_button_pressed():
	save_settings()

func _on_reset_button_pressed():
	reset_settings()

func close_settings():
	settings_closed.emit()
	hide()

func open_settings():
	show()

func save_settings():
	# 保存修改后的数据到文件
	save_turret_data_to_file()
	
	# 更新 Data.gd 中的数据
	update_data_gd()
	
	# 显示保存成功的消息
	show_save_confirmation()

func save_turret_data_to_file():
	# 创建保存目录
	var save_dir = "user://saved_turrets"
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_absolute(save_dir)
	
	# 保存数据到文件
	var save_file = FileAccess.open("%s/turret_data.json" % save_dir, FileAccess.WRITE)
	if save_file:
		var json_string = JSON.stringify(modified_turret_data, "\t")
		save_file.store_string(json_string)
		save_file.close()

func show_save_confirmation():
	# 显示保存成功的消息
	var confirmation_label = Label.new()
	confirmation_label.text = "设置已保存!"
	confirmation_label.position = Vector2(250, 50)
	confirmation_label.add_theme_color_override("font_color", Color.GREEN)
	panel.add_child(confirmation_label)
	
	# 3秒后移除消息
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(confirmation_label):
		confirmation_label.queue_free()

func update_data_gd():
	# 获取 Data 单例
	var data_node = get_node("/root/Data")
	if data_node:
		# 更新炮塔数据
		for turret_id in modified_turret_data.keys():
			if data_node.turrets.has(turret_id):
				# 更新现有炮塔数据
				data_node.merge_turret_data(data_node.turrets[turret_id], modified_turret_data[turret_id])
			else:
				# 添加新的炮塔类型
				data_node.turrets[turret_id] = modified_turret_data[turret_id].duplicate(true)

func reset_settings():
	# 重置为原始数据
	for turret_id in original_turret_data.keys():
		modified_turret_data[turret_id] = original_turret_data[turret_id].duplicate(true)
	
	# 重新创建设置面板
	for child in turret_settings_container.get_children():
		child.queue_free()
	
	create_turret_settings_panel()