extends Turret

var bulletSpeed := 200.0
var bulletPierce := 1

func attack():
	if is_instance_valid(current_target):
		# Calculate DA/TA attacks for projectile towers only
		var attack_count = 1
		if turret_category == "projectile":
			attack_count = calculate_da_ta_attacks()
		
		# Fire projectiles based on attack count
		for i in range(attack_count):
			fire_projectile(i, attack_count)
			
		# Create visual effect for DA/TA
		if attack_count > 1:
			create_da_ta_effect(attack_count)
	else:
		try_get_closest_target()

func fire_projectile(projectile_index: int, total_count: int):
	if not Globals.projectiles_node:
		print("ERROR: Globals.projectiles_node is null!")
		return
	
	var projectileScene := preload("res://Scenes/turrets/projectileTurret/bullet/bulletBase.tscn")
	var projectile := projectileScene.instantiate()
	projectile.bullet_type = Data.turrets[turret_type]["bullet"]
	projectile.base_damage = damage * (1.0 + passive_damage_bonus)
	projectile.element = element
	projectile.turret_category = turret_category
	projectile.equipped_gem = equipped_gem
	projectile.source_tower = self  # 设置发射塔的引用
	
	# 设置宝石效果
	if projectile.has_method("setup_gem_effects"):
		projectile.setup_gem_effects(self)
	
	# Apply projectile speed talent boost
	var speed_multiplier = 1.0
	if Globals.has_method("get") and Globals.get("projectile_speed_boost") != null:
		speed_multiplier = Globals.get("projectile_speed_boost")
	projectile.speed = bulletSpeed * speed_multiplier
	projectile.pierce = bulletPierce
	
	# Add slight spread for multiple projectiles
	var spread_angle = 0.0
	if total_count > 1:
		spread_angle = (projectile_index - (total_count - 1) / 2.0) * 0.2  # 0.2 radians spread
	
	# Apply spread to target direction
	var target_direction = (current_target.position - position).normalized()
	var spread_direction = target_direction.rotated(spread_angle)
	projectile.target = position + spread_direction * 1000  # Extend far enough
	
	Globals.projectiles_node.add_child(projectile)
	projectile.position = position
	
	print("子弹发射! 类型: %s, 位置: %s, 目标: %s, 速度: %s" % [projectile.bullet_type, projectile.position, projectile.target, projectile.speed])

func create_da_ta_effect(attack_count: int):
	# Create visual indicator for DA/TA attacks
	var effect_color = Color.YELLOW if attack_count == 2 else Color.RED
	var effect_label = Label.new()
	effect_label.text = "DA!" if attack_count == 2 else "TA!"
	effect_label.modulate = effect_color
	effect_label.position = Vector2(-20, -40)
	add_child(effect_label)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", Vector2(-20, -70), 1.0)
	tween.parallel().tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(effect_label.queue_free)
