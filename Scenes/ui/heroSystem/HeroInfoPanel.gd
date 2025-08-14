class_name HeroInfoPanel
extends Control

## Hero Information Panel
## Displays detailed information about selected heroes

# UI components
@onready var hero_name_label: Label = $Panel/HeroNameLabel
@onready var level_label: Label = $Panel/LevelLabel
@onready var health_label: Label = $Panel/HealthLabel
@onready var damage_label: Label = $Panel/StatsContainer/DamageLabel
@onready var defense_label: Label = $Panel/StatsContainer/DefenseLabel
@onready var attack_speed_label: Label = $Panel/StatsContainer/AttackSpeedLabel
@onready var charge_bar: ProgressBar = $Panel/StatsContainer/ChargeBar
@onready var status_label: Label = $Panel/StatsContainer/StatusLabel
@onready var skill1_label: Label = $Panel/StatsContainer/SkillsContainer/Skill1Label
@onready var skill2_label: Label = $Panel/StatsContainer/SkillsContainer/Skill2Label
@onready var skill3_label: Label = $Panel/StatsContainer/SkillsContainer/Skill3Label

# State
var current_hero: Node = null
var update_timer: float = 0.0
var update_interval: float = 0.2  # Update every 200ms

func _ready() -> void:
	# Initially hide
	hide_panel()

func _process(delta: float) -> void:
	# Update hero information periodically
	if current_hero and is_instance_valid(current_hero):
		update_timer += delta
		if update_timer >= update_interval:
			update_hero_info()
			update_timer = 0.0

func show_hero_info(hero: Node) -> void:
	"""Show information for specific hero"""
	if not hero or not is_instance_valid(hero):
		return
	
	current_hero = hero
	visible = true
	update_hero_info()

func hide_panel() -> void:
	"""Hide the info panel"""
	visible = false
	current_hero = null

func update_hero_info() -> void:
	"""Update displayed hero information"""
	if not current_hero or not is_instance_valid(current_hero):
		return
	
	# Update basic info
	hero_name_label.text = current_hero.hero_name
	level_label.text = "等级: %d" % current_hero.current_level
	
	# Update health
	var current_hp = current_hero.health_bar.value if current_hero.health_bar else 0
	var max_hp = current_hero.current_stats.get("max_hp", 100)
	health_label.text = "生命: %d/%d" % [int(current_hp), int(max_hp)]
	
	# Update stats
	var damage = current_hero.current_stats.get("damage", 0)
	var defense = current_hero.current_stats.get("defense", 0)
	var attack_speed = current_hero.current_stats.get("attack_speed", 1.0)
	
	damage_label.text = "攻击力: %d" % int(damage)
	defense_label.text = "防御力: %d" % int(defense)
	attack_speed_label.text = "攻击速度: %.2f" % attack_speed
	
	# Update charge
	charge_bar.value = current_hero.current_charge
	
	# Update status
	update_hero_status()
	
	# Update skills
	update_skills_info()

func update_hero_status() -> void:
	"""Update hero status display"""
	if not current_hero or not is_instance_valid(current_hero):
		return
	
	var status_text = "状态: "
	
	if not current_hero.is_alive:
		if current_hero.is_respawning:
			status_text += "复活中 (%.1fs)" % current_hero.respawn_timer
		else:
			status_text += "已死亡"
	elif current_hero.current_casting_skill:
		status_text += "施法中 - " + current_hero.current_casting_skill.skill_name
	elif current_hero.pending_talent_selection:
		status_text += "等待天赋选择"
	else:
		status_text += "正常"
	
	status_label.text = status_text

func update_skills_info() -> void:
	"""Update skills information"""
	if not current_hero or not is_instance_valid(current_hero):
		return
	
	var skills = current_hero.skills
	
	# Clear existing skill labels (except title)
	for child in $Panel/StatsContainer/SkillsContainer.get_children():
		if child != $Panel/StatsContainer/SkillsContainer/SkillsTitle:
			child.queue_free()
	
	# Add skill information
	for i in range(min(skills.size(), 3)):
		var skill = skills[i]
		var skill_label = Label.new()
		
		var cooldown_text = ""
		if skill.is_on_cooldown:
			cooldown_text = " (CD: %.1fs)" % skill.cooldown_remaining
		elif skill.can_cast(current_hero):
			cooldown_text = " (就绪)"
		else:
			cooldown_text = " (充能不足)"
		
		skill_label.text = "• %s (%s)%s" % [skill.skill_name, skill.skill_type, cooldown_text]
		skill_label.modulate = get_skill_color(skill)
		
		$Panel/StatsContainer/SkillsContainer.add_child(skill_label)

func get_skill_color(skill: Node) -> Color:
	"""Get color for skill based on type"""
	match skill.skill_type:
		"A":
			return Color.GREEN
		"B":
			return Color.YELLOW
		"C":
			return Color.RED
		_:
			return Color.WHITE

func set_panel_position(position: Vector2) -> void:
	"""Set panel position"""
	global_position = position

func set_panel_size(size: Vector2) -> void:
	"""Set panel size"""
	custom_minimum_size = size
	size = size

func is_showing_hero(hero: Node) -> bool:
	"""Check if panel is showing specific hero"""
	return current_hero == hero and is_instance_valid(current_hero)

func get_current_hero() -> Node:
	"""Get currently displayed hero"""
	return current_hero if is_instance_valid(current_hero) else null

# External interface for HeroManager
func setup_from_hero_manager(hero_manager: Node) -> void:
	"""Setup panel from hero manager"""
	if not hero_manager:
		return
	
	# Connect to hero manager signals
	if hero_manager.has_signal("hero_deployed"):
		hero_manager.connect("hero_deployed", _on_hero_deployed)
	
	if hero_manager.has_signal("hero_died"):
		hero_manager.connect("hero_died", _on_hero_died)
	
	if hero_manager.has_signal("hero_respawned"):
		hero_manager.connect("hero_respawned", _on_hero_respawned)

func _on_hero_deployed(hero: Node, position: Vector2) -> void:
	"""Handle hero deployment"""
	# Auto-show info for deployed hero
	show_hero_info(hero)

func _on_hero_died(hero: Node) -> void:
	"""Handle hero death"""
	if current_hero == hero:
		update_hero_status()

func _on_hero_respawned(hero: Node) -> void:
	"""Handle hero respawn"""
	if current_hero == hero:
		update_hero_status()

func _exit_tree() -> void:
	"""Clean up connections"""
	# Disconnect from hero manager if connected
	var hero_manager = get_hero_manager()
	if hero_manager:
		if hero_manager.has_signal("hero_deployed"):
			if hero_manager.is_connected("hero_deployed", _on_hero_deployed):
				hero_manager.disconnect("hero_deployed", _on_hero_deployed)
		
		if hero_manager.has_signal("hero_died"):
			if hero_manager.is_connected("hero_died", _on_hero_died):
				hero_manager.disconnect("hero_died", _on_hero_died)
		
		if hero_manager.has_signal("hero_respawned"):
			if hero_manager.is_connected("hero_respawned", _on_hero_respawned):
				hero_manager.disconnect("hero_respawned", _on_hero_respawned)

func get_hero_manager() -> Node:
	"""Get reference to hero manager"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("HeroManager")