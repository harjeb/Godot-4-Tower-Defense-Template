extends PanelContainer

var turret : Node2D
const sell_modifier := 0.7

func _ready():
	Globals.goldChanged.connect(check_can_upgrade)
	turret.turretUpdated.connect(set_props)
	set_props()
	animate_appear()
	check_can_upgrade()

func animate_appear():
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(500,0), 0.01).as_relative()
	tween.tween_property(self, "position", Vector2(-500,0), 0.3).as_relative()

func set_props():
	%TurretTexture.texture = load(Data.turrets[turret.turret_type]["sprite"])
	%TurretName.text = Data.turrets[turret.turret_type]["name"]
	%TurretLevel.text = "Level "+str(turret.turret_level)
	%UpgradeButton.text = "Upgrade for "+str(get_upgrade_price())
	%SellButton.text = "Sell for "+str(get_sell_price())
	for c in %Stats.get_children():
		c.queue_free()
	var statLabelScene := preload("res://Scenes/ui/turretUI/stat_label.tscn")
	for stat in Data.turrets[turret.turret_type]["stats"].keys():
		var statLabel := statLabelScene.instantiate()
		statLabel.text = Data.stats[stat]["name"]+" "+str(round(turret.get(stat)))
		%Stats.add_child(statLabel)
	
	# 显示宝石技能信息
	display_gem_skills()

func _on_upgrade_button_pressed():
	if check_can_upgrade():
		Globals.currentMap.gold -= get_upgrade_price()
		turret.upgrade_turret()
		check_can_upgrade()

func get_upgrade_price():
	return turret.turret_level * Data.turrets[turret.turret_type]["upgrade_cost"]

func get_sell_price():
	var total_cost = Data.turrets[turret.turret_type]["cost"]
	for i in range(turret.turret_level):
		total_cost += i*Data.turrets[turret.turret_type]["upgrade_cost"]
	return round(total_cost * sell_modifier)

func check_can_upgrade(_new_gold=0):
	if turret.turret_level == Data.turrets[turret.turret_type]["max_level"]:
		%UpgradeButton.text = "Maxed Out"
		%UpgradeButton.disabled = true
	else:
		%UpgradeButton.disabled = Globals.currentMap.gold < get_upgrade_price()
	return not %UpgradeButton.disabled


func _on_sell_button_pressed():
	queue_free()
	Globals.currentMap.gold += get_sell_price()
	turret.queue_free()

func _on_close_button_pressed():
	turret.close_details_pane()

# 显示宝石技能信息
func display_gem_skills():
	if not turret or not turret.has_method("get_gem_skills_info"):
		return
	
	var gem_info = turret.get_gem_skills_info()
	if gem_info.is_empty():
		return
	
	var skill_name = gem_info[0]
	var skill_description = gem_info[1]
	
	# 创建分隔线
	var separator = HSeparator.new()
	separator.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%Stats.add_child(separator)
	
	# 创建宝石技能标题
	var titleLabel := Label.new()
	titleLabel.text = "宝石技能:"
	titleLabel.add_theme_color_override("font_color", Color.ORANGE)
	titleLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%Stats.add_child(titleLabel)
	
	# 创建技能名称
	var nameLabel := Label.new()
	nameLabel.text = skill_name
	nameLabel.add_theme_color_override("font_color", Color.YELLOW)
	nameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%Stats.add_child(nameLabel)
	
	# 创建技能描述
	var descLabel := Label.new()
	descLabel.text = skill_description
	descLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descLabel.custom_minimum_size = Vector2(200, 0)
	descLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%Stats.add_child(descLabel)
