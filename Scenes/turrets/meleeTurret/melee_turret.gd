extends Turret

func attack():
	if is_instance_valid(current_target):
		$AnimatedSprite2D.play("default")
		for a in $DetectionArea.get_overlapping_areas():
			var collider = a.get_parent()
			if collider.is_in_group("enemy"):
				# 获取目标元素属性
				var target_element = "neutral"
				if collider.has_method("get_element"):
					target_element = collider.get_element()
				
				# 使用增强的伤害计算
				var final_damage = calculate_final_damage(damage, target_element)
				collider.get_damage(final_damage)
	else:
		try_get_closest_target()
