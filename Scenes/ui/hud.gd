extends Control

var next_wait_time := 0
var waited := 0
var open_details_pane : PanelContainer

# 新增 UI 系统
var inventory_ui: InventoryUI
var weapon_wheel_ui: WeaponWheelUI
var gem_crafting_ui: GemCraftingUI
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

func update_enemy_count(remain):
	%RemainLabel.text = "Enemies: "+str(remain)

func reset():
	if is_instance_valid(open_details_pane):
		open_details_pane.turret.close_details_pane()
	# 关闭所有 UI 面板
	close_all_ui_panels()

# 新增方法
func setup_new_ui_systems():
	# 创建 UI 按钮容器
	ui_buttons_container = HBoxContainer.new()
	ui_buttons_container.position = Vector2(10, 100)
	ui_buttons_container.size = Vector2(300, 40)
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

func _input(event):
	# 处理快捷键
	if event.is_action_pressed("open_inventory"):
		toggle_inventory()
	elif event.is_action_pressed("open_weapon_wheel"):
		toggle_weapon_wheel()
	elif event.is_action_pressed("craft_gems"):
		toggle_crafting()

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

func close_all_ui_panels():
	if inventory_ui:
		inventory_ui.hide()
	if weapon_wheel_ui:
		weapon_wheel_ui.hide()
	if gem_crafting_ui:
		gem_crafting_ui.hide()

# UI 事件处理方法
func _on_inventory_button_pressed():
	toggle_inventory()

func _on_weapon_wheel_button_pressed():
	toggle_weapon_wheel()

func _on_crafting_button_pressed():
	toggle_crafting()

func _on_inventory_closed():
	pass  # UI 已经处理隐藏

func _on_weapon_wheel_closed():
	pass  # UI 已经处理隐藏

func _on_crafting_closed():
	pass  # UI 已经处理隐藏

func _on_gem_selected(gem_data: Dictionary):
	print("选中宝石: ", gem_data.get("name", "未知"))
	# 可以在这里处理宝石装备逻辑

func _on_buff_removed(slot_index: int):
	print("移除BUFF: 槽位 ", slot_index)

func _on_gem_crafted(gem_id: String):
	print("成功合成宝石: ", gem_id)
