extends PathFollow2D

# 新增属性
var element: String = "neutral"
var special_abilities: Array = []
var is_stealthed: bool = false
var can_split: bool = false
var split_count: int = 0
var max_splits: int = 2
var can_heal: bool = false
var heal_cooldown: float = 7.0
var heal_timer: float = 0.0
var max_hp: float = 10.0

var enemy_type := "":
	set(val):
		enemy_type = val
		var enemy_data = Data.enemies[val]
		$Sprite2D.texture = load(enemy_data["sprite"])
		element = enemy_data.get("element", "neutral")
		special_abilities = enemy_data.get("special_abilities", [])
		max_hp = enemy_data["stats"]["hp"]
		
		# 设置特殊能力
		setup_special_abilities()
		
		for stat in enemy_data["stats"].keys():
			set(stat, enemy_data["stats"][stat])

enum State {walking, damaged}
var state = State.walking
var goldYield := 10.0
var hp := 10.0
var baseDamage := 5.0
var speed := 1.0
var is_destroyed := false

@onready var spawner := get_parent() as EnemyPath
func _ready():
	add_to_group("enemy")
	# 初始化治疗计时器
	heal_timer = heal_cooldown

func _process(delta):
	if state == State.walking:
		# Move
		progress_ratio += 0.0005 * speed
		if progress_ratio == 1:
			finished_path()
			return
			
		# 治疗逻辑
		if can_heal:
			heal_timer -= delta
			if heal_timer <= 0 and hp < max_hp:
				heal()
				heal_timer = heal_cooldown
		
		# Flip
		var angle = int(rotation_degrees) % 360
		if angle > 180:
			angle -= 360
		$Sprite2D.flip_v = abs(angle) > 90

func finished_path():
	if is_destroyed:
		return
	is_destroyed = true
	spawner.enemy_destroyed()
	Globals.currentMap.get_base_damage(baseDamage)
	queue_free()

func get_damage(damage):
	if is_destroyed:
		return
	hp -= damage
	damage_animation()
	if hp <= 0:
		handle_death()

func handle_death():
	is_destroyed = true
	spawner.enemy_destroyed()
	Globals.currentMap.gold += goldYield
	
	# 掉落物品
	var drop_item_id = LootSystem.roll_drop(Data.enemies[enemy_type])
	if drop_item_id != "":
		var drop = LootSystem.create_drop_item(drop_item_id, global_position)
		get_tree().current_scene.add_child(drop)
	
	# 分裂逻辑
	if can_split and split_count < max_splits:
		spawn_split_units()
	
	queue_free()

func damage_animation():
	var tween := create_tween()
	tween.tween_property(self, "v_offset", 0, 0.05)
	tween.tween_property(self, "modulate", Color.ORANGE_RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.set_parallel()
	tween.tween_property(self, "v_offset", -5, 0.2)
	tween.set_parallel(false)
	tween.tween_property(self, "v_offset", 0, 0.2)

# 新增方法
func setup_special_abilities():
	for ability in special_abilities:
		match ability:
			"stealth":
				is_stealthed = true
				modulate.a = 0.5  # 半透明
			"split":
				can_split = true
			"heal":
				can_heal = true

func heal():
	var heal_amount = max_hp * 0.1  # 恢复10%最大血量
	hp = min(hp + heal_amount, max_hp)
	# 显示治疗效果
	var heal_label = Label.new()
	heal_label.text = "+%.0f" % heal_amount
	heal_label.modulate = Color.GREEN
	add_child(heal_label)
	# 治疗动画
	var tween = create_tween()
	tween.tween_property(heal_label, "position", Vector2(0, -30), 1.0)
	tween.tween_property(heal_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(heal_label.queue_free)

func spawn_split_units():
	for i in range(2):
		var split_enemy = preload("res://Scenes/enemies/enemy_mover.tscn").instantiate()
		split_enemy.enemy_type = enemy_type
		split_enemy.split_count = split_count + 1
		split_enemy.progress_ratio = progress_ratio
		split_enemy.hp = max_hp * 0.6  # 分裂后血量60%
		split_enemy.scale = Vector2(0.8, 0.8)  # 尺寸缩小
		spawner.add_child(split_enemy)

func get_is_stealthed() -> bool:
	return is_stealthed

func get_element() -> String:
	return element

func has_ability(ability_name: String) -> bool:
	return ability_name in special_abilities

func get_element_color() -> Color:
	return ElementSystem.get_element_color(element)
