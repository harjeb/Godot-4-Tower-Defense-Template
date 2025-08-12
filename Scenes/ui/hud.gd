extends Control

var next_wait_time := 0
var waited := 0
var open_details_pane : PanelContainer

# 新增 UI 系统
var inventory_ui: InventoryUI
var weapon_wheel_ui: WeaponWheelUI
var gem_crafting_ui: GemCraftingUI
var settings_ui: SettingsUI
var ui_buttons_container: HBoxContainer

func _ready():
	Globals.hud = self
	Globals.baseHpChanged.connect(update_hp)
	Globals.goldChanged.connect(update_gold)
	Globals.waveStarted.connect(show_wave_count)
	Globals.waveCleared.connect(show_wave_timer)
	Globals.enemyDestroyed.connect(update_enemy_count)
	
	# 初始化新 UI 系统
	setup_new_ui_systems()
	find_wave_manager()
	setup_wave_countdown_ui()

func update_hp(newHp, maxHp):
	%HPLabel.text = "HP: "+str(round(newHp))+"/"+str(round(maxHp))

func update_gold(newGold):
	%GoldLabel.text = "Gold: "+str(round(newGold))

func show_wave_count(current_wave, enemies):
	$WaveWaitTimer.stop()
	waited = 0
	%WaveLabel.text = "Current Wave: "+str(current_wave)
	%RemainLabel.text = "Enemies: "+str(enemies)
	%RemainLabel.visible = true
	
func show_wave_timer(wait_time):
	%RemainLabel.visible = false
	next_wait_time = wait_time-1
	$WaveWaitTimer.start()

func _on_wave_wait_timer_timeout():
	%WaveLabel.text = "Next wave in "+str(next_wait_time-waited)
	waited += 1

func _unhandled_key_input(event):
	# 处理快捷键（备用）
	if event.pressed:
		match event.keycode:
			KEY_I:
				toggle_inventory()
			KEY_TAB:
				toggle_weapon_wheel()
			KEY_C:
				toggle_crafting()
			KEY_S:  # 添加 S 键作为设置快捷键
				toggle_settings()

func update_enemy_count(remain):
	%RemainLabel.text = "Enemies: "+str(remain)

func reset():
	if is_instance_valid(open_details_pane):
		open_details_pane.turret.close_details_pane()
	# 关闭所有 UI 面板
	close_all_ui_panels()

# 新增方法
# 新增属性
var summon_stone_ui: SummonStoneUI
var tech_tree_ui: TechTreeUI
var tower_tech_ui: TowerTechUI
var wave_manager: WaveManager

# 波次控制UI
var wave_countdown_panel: Panel
var countdown_label: Label
var start_wave_button: Button
var tech_points_display: Label

func setup_new_ui_systems():
	# 创建 UI 按钮容器
	ui_buttons_container = HBoxContainer.new()
	ui_buttons_container.position = Vector2(10, 100)
	ui_buttons_container.size = Vector2(500, 40)  # 增加宽度以容纳新按钮
	add_child(ui_buttons_container)
	
	# 创建背包按钮
	var inventory_button = Button.new()
	inventory_button.text = "背包 (I)"
	inventory_button.custom_minimum_size = Vector2(80, 35)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	ui_buttons_container.add_child(inventory_button)
	
	# 创建武器盘按钮
	var weapon_wheel_button = Button.new()
	weapon_wheel_button.text = "武器盘 (Tab)"
	weapon_wheel_button.custom_minimum_size = Vector2(100, 35)
	weapon_wheel_button.pressed.connect(_on_weapon_wheel_button_pressed)
	ui_buttons_container.add_child(weapon_wheel_button)
	
	# 创建宝石合成按钮
	var crafting_button = Button.new()
	crafting_button.text = "合成 (C)"
	crafting_button.custom_minimum_size = Vector2(80, 35)
	crafting_button.pressed.connect(_on_crafting_button_pressed)
	ui_buttons_container.add_child(crafting_button)
	
	# 创建天赋树按钮
	var tech_tree_button = Button.new()
	tech_tree_button.text = "天赋树"
	tech_tree_button.custom_minimum_size = Vector2(80, 35)
	tech_tree_button.pressed.connect(_on_tech_tree_button_pressed)
	ui_buttons_container.add_child(tech_tree_button)
	
	# 创建塔科技按钮
	var tower_tech_button = Button.new()
	tower_tech_button.text = "塔科技"
	tower_tech_button.custom_minimum_size = Vector2(80, 35)
	tower_tech_button.pressed.connect(_on_tower_tech_button_pressed)
	ui_buttons_container.add_child(tower_tech_button)
	
	# 创建游戏设置按钮
	var settings_button = Button.new()
	settings_button.text = "设置"
	settings_button.custom_minimum_size = Vector2(80, 35)
	settings_button.pressed.connect(_on_settings_button_pressed)
	ui_buttons_container.add_child(settings_button)
	
	# 创建 UI 面板
	create_ui_panels()

func create_ui_panels():
	# 创建背包 UI
	inventory_ui = preload("res://Scenes/ui/inventory/InventoryUI.gd").new()
	inventory_ui.hide()
	inventory_ui.inventory_closed.connect(_on_inventory_closed)
	inventory_ui.gem_selected.connect(_on_gem_selected)
	add_child(inventory_ui)
	
	# 创建武器盘 UI
	weapon_wheel_ui = preload("res://Scenes/ui/weaponWheel/WeaponWheelUI.gd").new()
	weapon_wheel_ui.hide()
	weapon_wheel_ui.weapon_wheel_closed.connect(_on_weapon_wheel_closed)
	weapon_wheel_ui.buff_removed.connect(_on_buff_removed)
	add_child(weapon_wheel_ui)
	
	# 创建宝石合成 UI
	gem_crafting_ui = preload("res://Scenes/ui/gemCrafting/GemCraftingUI.gd").new()
	gem_crafting_ui.hide()
	gem_crafting_ui.crafting_closed.connect(_on_crafting_closed)
	gem_crafting_ui.gem_crafted.connect(_on_gem_crafted)
	add_child(gem_crafting_ui)
	
	# 创建科技树 UI
	tech_tree_ui = preload("res://Scenes/ui/techTree/TechTreeUI.gd").new()
	tech_tree_ui.hide()
	tech_tree_ui.name = "TechTreeUI"
	tech_tree_ui.talent_tree_closed.connect(_on_talent_tree_closed)
	add_child(tech_tree_ui)
	
	# 创建塔科技 UI
	tower_tech_ui = preload("res://Scenes/ui/towerTech/TowerTechUI.gd").new()
	tower_tech_ui.hide()
	tower_tech_ui.name = "TowerTechUI"
	tower_tech_ui.tower_tech_closed.connect(_on_tower_tech_closed)
	add_child(tower_tech_ui)
	
	# 创建游戏设置 UI
	settings_ui = preload("res://Scenes/ui/settings/SettingsUI.gd").new()
	settings_ui.hide()
	settings_ui.settings_closed.connect(_on_settings_closed)
	add_child(settings_ui)
	
	# 创建召唤石 UI
	summon_stone_ui = preload("res://Scenes/ui/summonStones/SummonStoneUI.gd").new()
	summon_stone_ui.name = "SummonStoneUI"
	summon_stone_ui.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	summon_stone_ui.position = Vector2(50, -120)  # 放置在屏幕底部左侧
	add_child(summon_stone_ui)

func _input(event):
	# 处理快捷键
	if event.is_action_pressed("open_inventory"):
		toggle_inventory()
	elif event.is_action_pressed("open_weapon_wheel"):
		toggle_weapon_wheel()
	elif event.is_action_pressed("craft_gems"):
		toggle_crafting()
	elif event.is_action_pressed("open_settings"):
		toggle_settings()

func toggle_inventory():
	if inventory_ui.visible:
		inventory_ui.close_inventory()
	else:
		close_all_ui_panels()
		inventory_ui.open_inventory()

func toggle_weapon_wheel():
	if weapon_wheel_ui.visible:
		weapon_wheel_ui.close_weapon_wheel()
	else:
		close_all_ui_panels()
		weapon_wheel_ui.open_weapon_wheel()

func toggle_crafting():
	if gem_crafting_ui.visible:
		gem_crafting_ui.close_crafting()
	else:
		close_all_ui_panels()
		gem_crafting_ui.open_crafting()

func toggle_tech_tree():
	if tech_tree_ui.visible:
		tech_tree_ui.close_talent_tree()
	else:
		close_all_ui_panels()
		tech_tree_ui.open_talent_tree()

func toggle_tower_tech():
	if tower_tech_ui.visible:
		tower_tech_ui.close_tower_tech_tree()
	else:
		close_all_ui_panels()
		tower_tech_ui.open_tower_tech_tree()

func toggle_settings():
	if settings_ui.visible:
		settings_ui.close_settings()
	else:
		close_all_ui_panels()
		settings_ui.open_settings()

func close_all_ui_panels():
	if inventory_ui:
		inventory_ui.hide()
	if weapon_wheel_ui:
		weapon_wheel_ui.hide()
	if gem_crafting_ui:
		gem_crafting_ui.hide()
	if tech_tree_ui:
		tech_tree_ui.hide()
	if tower_tech_ui:
		tower_tech_ui.hide()
	if settings_ui:
		settings_ui.hide()

# UI 事件处理方法
func _on_inventory_button_pressed():
	toggle_inventory()

func _on_weapon_wheel_button_pressed():
	toggle_weapon_wheel()

func _on_crafting_button_pressed():
	toggle_crafting()

func _on_settings_button_pressed():
	toggle_settings()

func _on_tech_tree_button_pressed():
	toggle_tech_tree()

func _on_tower_tech_button_pressed():
	toggle_tower_tech()

func _on_inventory_closed():
	pass  # UI 已经处理隐藏

func _on_weapon_wheel_closed():
	pass  # UI 已经处理隐藏

func _on_crafting_closed():
	pass  # UI 已经处理隐藏

func _on_settings_closed():
	pass  # UI 已经处理隐藏

func _on_gem_selected(gem_data: Dictionary):
	var gem_name = "未知"
	if gem_data.has("name"):
		gem_name = gem_data.get("name")
	print("选中宝石: ", gem_name)
	# 可以在这里处理宝石装备逻辑

func _on_buff_removed(slot_index: int):
	print("移除BUFF: 槽位 ", slot_index)

func _on_gem_crafted(gem_id: String):
	print("成功合成宝石: ", gem_id)

func find_wave_manager():
	wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
	if wave_manager:
		wave_manager.wave_countdown_started.connect(_on_wave_countdown_started)
		wave_manager.wave_countdown_updated.connect(_on_wave_countdown_updated)
		wave_manager.wave_completed.connect(_on_wave_completed)

func setup_wave_countdown_ui():
	# 创建波次倒计时面板
	wave_countdown_panel = Panel.new()
	wave_countdown_panel.custom_minimum_size = Vector2(300, 120)
	wave_countdown_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	wave_countdown_panel.position.y = 50
	wave_countdown_panel.visible = false
	add_child(wave_countdown_panel)
	
	var panel_vbox = VBoxContainer.new()
	panel_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_vbox.add_theme_constant_override("separation", 10)
	wave_countdown_panel.add_child(panel_vbox)
	
	# 倒计时标题
	var title_label = Label.new()
	title_label.text = "下一波准备中..."
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	panel_vbox.add_child(title_label)
	
	# 倒计时显示
	countdown_label = Label.new()
	countdown_label.text = "30"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 36)
	countdown_label.modulate = Color.YELLOW
	panel_vbox.add_child(countdown_label)
	
	# 立即开始按钮
	start_wave_button = Button.new()
	start_wave_button.text = "立即开始"
	start_wave_button.custom_minimum_size = Vector2(150, 40)
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	var button_container = CenterContainer.new()
	button_container.add_child(start_wave_button)
	panel_vbox.add_child(button_container)
	
	# 科技点显示（在右上角）
	tech_points_display = Label.new()
	tech_points_display.text = "科技点: 0"
	tech_points_display.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tech_points_display.position = Vector2(-150, 10)
	tech_points_display.add_theme_font_size_override("font_size", 16)
	tech_points_display.modulate = Color.CYAN
	add_child(tech_points_display)
	
	# 更新科技点显示
	update_tech_points_display()

func update_tech_points_display():
	var tech_point_system = get_tree().current_scene.get_node_or_null("TechPointSystem")
	if tech_point_system and tech_points_display:
		var points = tech_point_system.get_tech_points()
		tech_points_display.text = "科技点: %d" % points

func _on_wave_countdown_started(countdown_time: float):
	wave_countdown_panel.visible = true
	countdown_label.text = str(int(countdown_time))

func _on_wave_countdown_updated(remaining_time: float):
	if wave_countdown_panel.visible:
		countdown_label.text = str(int(remaining_time))
		
		# 倒计时颜色变化
		if remaining_time <= 5:
			countdown_label.modulate = Color.RED
		elif remaining_time <= 10:
			countdown_label.modulate = Color.ORANGE
		else:
			countdown_label.modulate = Color.YELLOW

func _on_wave_completed(wave_number: int, tech_points_earned: int):
	# 隐藏倒计时面板
	wave_countdown_panel.visible = false
	
	# 更新科技点显示
	update_tech_points_display()
	
	# 显示波次完成信息
	show_wave_completion_info(wave_number, tech_points_earned)

func _on_start_wave_button_pressed():
	if wave_manager and wave_manager.can_start_wave_manually():
		wave_manager.start_wave_immediately()
		wave_countdown_panel.visible = false

func show_wave_completion_info(wave_number: int, tech_points_earned: int):
	# 创建临时信息面板
	var info_panel = Panel.new()
	info_panel.custom_minimum_size = Vector2(400, 150)
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(info_panel)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_vbox.add_theme_constant_override("separation", 15)
	info_panel.add_child(info_vbox)
	
	var title = Label.new()
	title.text = "第 %d 波完成!" % wave_number
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	info_vbox.add_child(title)
	
	var reward = Label.new()
	reward.text = "获得 %d 科技点!" % tech_points_earned
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.add_theme_font_size_override("font_size", 18)
	reward.modulate = Color.CYAN
	info_vbox.add_child(reward)
	
	var button_hbox = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 20)
	var button_container = CenterContainer.new()
	button_container.add_child(button_hbox)
	info_vbox.add_child(button_container)
	
	var talent_button = Button.new()
	talent_button.text = "打开天赋树"
	talent_button.custom_minimum_size = Vector2(120, 40)
	talent_button.pressed.connect(_on_open_talent_tree_from_completion)
	button_hbox.add_child(talent_button)
	
	var continue_button = Button.new()
	continue_button.text = "继续"
	continue_button.custom_minimum_size = Vector2(120, 40)
	continue_button.pressed.connect(_on_continue_from_completion.bind(info_panel))
	button_hbox.add_child(continue_button)

func _on_open_talent_tree_from_completion():
	# 关闭当前打开的完成面板
	var completion_panels = get_children().filter(func(child): return child is Panel and child != wave_countdown_panel and child.custom_minimum_size.x == 400)
	for panel in completion_panels:
		panel.queue_free()
	
	# 打开天赋树
	toggle_tech_tree()

func _on_continue_from_completion(info_panel: Panel):
	info_panel.queue_free()

func _on_talent_tree_closed():
	# 天赋树关闭时的处理
	pass

func _on_tower_tech_closed():
	# 塔科技树关闭时的处理
	pass
