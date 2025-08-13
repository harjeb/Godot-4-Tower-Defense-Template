extends Node

## Resource path constants for better maintainability
const PATHS = {
	"scenes": {
		"turrets": {
			"projectile": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
			"melee": "res://Scenes/turrets/meleeTurret/meleeTurret.tscn",
			"ray": "res://Scenes/turrets/rayTurret/rayTurret.tscn",
			"base": "res://Scenes/turrets/turretBase/turret_base.tscn"
		},
		"ui": {
			"turret_details": "res://Scenes/ui/turretUI/turret_details.tscn"
		}
	},
	"assets": {
		"turrets": {
			"techno": "res://Assets/turrets/technoturret.png",
			"laser": "res://Assets/turrets/laserturret.png",
			"real_laser": "res://Assets/turrets/reallaser.png",
			"dynamite": "res://Assets/turrets/dynamite.png"
		},
		"bullets": {
			"fire": "res://Assets/bullets/bullet1.tres",
			"laser": "res://Assets/bullets/bullet2.tres"
		},
		"summon_stones": {
			"shiva": "res://Assets/summon_stones/shiva.png",
			"lucifer": "res://Assets/summon_stones/lucifer.png",
			"europa": "res://Assets/summon_stones/europa.png",
			"titan": "res://Assets/summon_stones/titan.png",
			"zeus": "res://Assets/summon_stones/zeus.png"
		},
		"maps": {
			"map1": "res://Assets/maps/map1.webp",
			"map2": "res://Assets/maps/map2.png"
		}
	}
}

## Safe resource loading with error handling
static func load_resource_safe(path: String, expected_type: String = "") -> Resource:
	if not ResourceLoader.exists(path):
		push_error("Resource not found: " + path)
		return null
	
	var resource = load(path)
	if not resource:
		push_error("Failed to load resource: " + path)
		return null
	
	if expected_type != "" and resource.get_class() != expected_type:
		push_warning("Resource type mismatch for " + path + ". Expected: " + expected_type)
	
	return resource

## Get path from PATHS dictionary with error checking
static func get_path(category: String, subcategory: String, item: String) -> String:
	if not PATHS.has(category):
		push_error("Path category not found: " + category)
		return ""
	
	if not PATHS[category].has(subcategory):
		push_error("Path subcategory not found: " + category + "." + subcategory)
		return ""
	
	if not PATHS[category][subcategory].has(item):
		push_error("Path item not found: " + category + "." + subcategory + "." + item)
		return ""
	
	return PATHS[category][subcategory][item]

var turrets := {
	"gatling": {
		"stats": {
			"damage": 10,
			"attack_speed": 2.0,
			"attack_range": 200.0,
			"bulletSpeed": 200.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Gatling Gun",
		"cost": 50,
		"upgrade_cost": 50,
		"max_level": 2,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 4.0,
		"rotates": true,
		"bullet": "fire",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
	},
	"laser": {
		"stats": {
			"damage": 0.5,
			"attack_speed": 20.0,
			"attack_range": 250.0,
			"bulletSpeed": 400.0,
			"bulletPierce": 4,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Flamethrower",
		"cost": 70,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/laserturret.png",
		"scale": 1.0,
		"rotates": false,
		"bullet": "laser",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
	},
	"ray": {
		"stats": {
			"damage": 0.5,
			"attack_speed": 0.5,
			"attack_range": 300.0,
			"ray_duration": 1.0,
			"ray_length": 300.0,
		},
		"upgrades": {
			"damage": {"amount": 1.0, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
			"ray_length": {"amount": 1.5, "multiplies": true},
			"ray_duration": {"amount": 1.5, "multiplies": true},
		},
		"name": "Raygun",
		"cost": 30,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/rayTurret/rayTurret.tscn",
		"sprite": "res://Assets/turrets/reallaser.png",
		"scale": 1.0,
		"rotates": true,
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "ray",
	},
	"melee": {
		"stats": {
			"damage": 5.0,
			"attack_speed": 1.0,
			"attack_range": 50.0,  # 近战塔攻击范围很小
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Blocking Tower",
		"cost": 70,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/meleeTurret/meleeTurret.tscn",
		"sprite": "res://Assets/turrets/dynamite.png",
		"scale": 1.0,
		"rotates": false,
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "melee",
		"combat_type": "melee",           # 近战类型
		"target_type": "ground_only",     # 只能攻击地面单位
		"max_health": 150.0,              # 塔的生命值
		"respawn_time": 4.0,              # 复活时间
		"da_bonus": 0.03,
		"ta_bonus": 0.01,
		"passive_effect": "blocking",
		"aoe_type": "none",
	},
	"arrow_tower": {
		"stats": {
			"damage": 15,
			"attack_speed": 1.2,
			"attack_range": 80.0,
			"bulletSpeed": 200.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 3.0, "multiplies": false},
			"attack_speed": {"amount": 1.3, "multiplies": true},
		},
		"name": "Arrow Tower",
		"cost": 50,
		"upgrade_cost": 40,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 3.0,
		"rotates": true,
		"bullet": "fire",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.05,
		"ta_bonus": 0.01,
		"passive_effect": "capture_tower_synergy",
		"aoe_type": "none",
		"special_mechanics": [],
		"combat_type": "ranged",         # 远程类型
		"target_type": "both"            # 可以攻击所有单位
	},
	"anti_air": {
		"stats": {
			"damage": 20,
			"attack_speed": 1.5,
			"attack_range": 220.0,
			"bulletSpeed": 300.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 4.0, "multiplies": false},
			"attack_speed": {"amount": 1.3, "multiplies": true},
		},
		"name": "Anti-Air Tower",
		"cost": 90,
		"upgrade_cost": 60,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/reallaser.png",
		"scale": 2.5,
		"rotates": true,
		"bullet": "laser",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"combat_type": "ranged",         # 远程类型
		"target_type": "air_only",       # 只能攻击飞行单位
		"da_bonus": 0.07,
		"ta_bonus": 0.02,
		"passive_effect": "air_superiority",
		"aoe_type": "none",
		"special_mechanics": ["air_targeting"]
	},
	"capture_tower": {
		"stats": {
			"damage": 8,
			"attack_speed": 0.5,
			"attack_range": 100.0,
			"bulletSpeed": 150.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 2.0, "multiplies": false},
			"attack_speed": {"amount": 1.2, "multiplies": true},
		},
		"name": "Capture Tower",
		"cost": 75,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/laserturret.png",
		"scale": 3.5,
		"rotates": true,
		"bullet": "laser",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "attack_speed_aura",
		"aoe_type": "slow",
		"special_mechanics": ["slow_effect"]
	},
	"mage_tower": {
		"stats": {
			"damage": 45,
			"attack_speed": 0.33,
			"attack_range": 90.0,
			"bulletSpeed": 100.0,
			"bulletPierce": 5,
		},
		"upgrades": {
			"damage": {"amount": 8.0, "multiplies": false},
			"attack_speed": {"amount": 1.1, "multiplies": true},
		},
		"name": "Mage Tower",
		"cost": 120,
		"upgrade_cost": 80,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/reallaser.png",
		"scale": 4.0,
		"rotates": true,
		"bullet": "fire",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "mage_damage_synergy",
		"aoe_type": "circle",
		"special_mechanics": ["aoe_damage"]
	},
	"detection_tower": {
		"stats": {
			"damage": 0,
			"attack_speed": 0.0,
			"attack_range": 120.0,
			"bulletSpeed": 0.0,
			"bulletPierce": 0,
		},
		"upgrades": {
			"attack_range": {"amount": 20.0, "multiplies": false},
		},
		"name": "Detection Tower",
		"cost": 60,
		"upgrade_cost": 30,
		"max_level": 3,
		"scene": "res://Scenes/turrets/turretBase/turret_base.tscn",
		"sprite": "res://Assets/turrets/dynamite.png",
		"scale": 3.0,
		"rotates": false,
		"bullet": "none",
		"element": "light",
		"gem_slot": null,
		"turret_category": "support",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "stealth_detection",
		"aoe_type": "none",
		"special_mechanics": ["stealth_detection"]
	},
	"doomsday_tower": {
		"stats": {
			"damage": 25,
			"attack_speed": 0.05,
			"attack_range": 70.0,
			"bulletSpeed": 0.0,
			"bulletPierce": 0,
			"dot_damage": 25.0,
			"dot_duration": 5.0,
			"disable_duration": 2.0,
		},
		"upgrades": {
			"damage": {"amount": 10.0, "multiplies": false},
			"dot_damage": {"amount": 10.0, "multiplies": false},
		},
		"name": "Doomsday Tower",
		"cost": 200,
		"upgrade_cost": 120,
		"max_level": 3,
		"scene": "res://Scenes/turrets/turretBase/turret_base.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 5.0,
		"rotates": false,
		"bullet": "none",
		"element": "dark",
		"gem_slot": null,
		"turret_category": "special",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "ta_cooldown_reduction",
		"aoe_type": "circle",
		"special_mechanics": ["dot_damage", "disable_effect"]
	},
	"pulse_tower": {
		"stats": {
			"damage": 20,
			"attack_speed": 0.56,
			"attack_range": 85.0,
			"bulletSpeed": 0.0,
			"bulletPierce": 0,
			"pulse_interval": 3.0,
		},
		"upgrades": {
			"damage": {"amount": 5.0, "multiplies": false},
			"attack_speed": {"amount": 1.2, "multiplies": true},
		},
		"name": "Pulse Tower",
		"cost": 90,
		"upgrade_cost": 60,
		"max_level": 3,
		"scene": "res://Scenes/turrets/turretBase/turret_base.tscn",
		"sprite": "res://Assets/turrets/laserturret.png",
		"scale": 4.0,
		"rotates": false,
		"bullet": "none",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "special",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "adjacent_tower_boost",
		"aoe_type": "periodic_circle",
		"special_mechanics": ["periodic_aoe"]
	},
	"ricochet_tower": {
		"stats": {
			"damage": 12,
			"attack_speed": 0.67,
			"attack_range": 75.0,
			"bulletSpeed": 250.0,
			"bulletPierce": 1,
			"ricochet_count": 5,
		},
		"upgrades": {
			"damage": {"amount": 3.0, "multiplies": false},
			"ricochet_count": {"amount": 2, "multiplies": false},
		},
		"name": "Ricochet Tower",
		"cost": 80,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/reallaser.png",
		"scale": 3.5,
		"rotates": true,
		"bullet": "fire",
		"element": "neutral",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "unique_damage_bonus",
		"aoe_type": "bounce",
		"special_mechanics": ["ricochet_shots"]
	},
	"aura_tower": {
		"stats": {
			"damage": 0,
			"attack_speed": 0.0,
			"attack_range": 95.0,
			"bulletSpeed": 0.0,
			"bulletPierce": 0,
			"slow_strength": 0.3,
		},
		"upgrades": {
			"attack_range": {"amount": 15.0, "multiplies": false},
			"slow_strength": {"amount": 0.1, "multiplies": false},
		},
		"name": "Aura Tower",
		"cost": 70,
		"upgrade_cost": 40,
		"max_level": 3,
		"scene": "res://Scenes/turrets/turretBase/turret_base.tscn",
		"sprite": "res://Assets/turrets/dynamite.png",
		"scale": 4.0,
		"rotates": false,
		"bullet": "none",
		"element": "ice",
		"gem_slot": null,
		"turret_category": "support",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "adjacent_da_ta_boost",
		"aoe_type": "persistent_slow",
		"special_mechanics": ["persistent_slow"]
	},
	"weakness_tower": {
		"stats": {
			"damage": 10,
			"attack_speed": 1.25,
			"attack_range": 65.0,
			"bulletSpeed": 180.0,
			"bulletPierce": 1,
			"armor_reduction": 15,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"armor_reduction": {"amount": 5, "multiplies": false},
		},
		"name": "Weakness Tower",
		"cost": 65,
		"upgrade_cost": 45,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 3.0,
		"rotates": true,
		"bullet": "laser",
		"element": "dark",
		"gem_slot": null,
		"turret_category": "projectile",
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"passive_effect": "slowed_enemy_bonus",
		"aoe_type": "armor_reduce",
		"special_mechanics": ["armor_reduction"]
	},
}

func _ready():
	load_custom_turret_data()

# Combat balance configuration
const combat_settings := {
	"da_max_chance": 0.5,  # Maximum Double Attack chance (50%)
	"ta_max_chance": 0.25  # Maximum Triple Attack chance (25%)
}

func load_custom_turret_data():
	# 检查是否存在自定义炮塔数据文件
	var save_file_path = "user://saved_turrets/turret_data.json"
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var custom_data = json.data
				
				# 合并自定义数据到现有数据中
				for turret_id in custom_data.keys():
					if turrets.has(turret_id):
						# 更新现有炮塔数据
						merge_turret_data(turrets[turret_id], custom_data[turret_id])
					else:
						# 添加新的炮塔类型
						turrets[turret_id] = custom_data[turret_id]

func merge_turret_data(original: Dictionary, custom: Dictionary):
	# 递归合并字典数据
	for key in custom.keys():
		if original.has(key) and typeof(original[key]) == TYPE_DICTIONARY and typeof(custom[key]) == TYPE_DICTIONARY:
			merge_turret_data(original[key], custom[key])
		else:
			original[key] = custom[key]

const stats := {
	"damage": {"name": "Damage"},
	"attack_speed": {"name": "Speed"},
	"attack_range": {"name": "Range"},
	"bulletSpeed": {"name": "Bullet Speed"},
	"bulletPierce": {"name": "Bullet Pierce"},
	"ray_length": {"name": "Ray Length"},
	"ray_duration": {"name": "Ray Duration"},
}

const bullets := {
	"fire": {
		"frames": "res://Assets/bullets/bullet1.tres",
	},
	"laser": {
		"frames": "res://Assets/bullets/bullet2.tres",
	}
}

const enemies := {
	"redDino": {
		"stats": {
			"hp": 10.0,
			"defense": 15,
			"speed": 1.0,
			"baseDamage": 5.0,
			"goldYield": 10.0,
			},
		"difficulty": 1.0,
		"sprite": "res://Assets/enemies/dino1.png",
		"element": "neutral",
		"special_abilities": [],
		"monster_skills": ["frost_aura"],
		"skill_cooldowns": {"frost_aura": 8.0},
		"drop_table": {
			"base_chance": 0.05,
			"items": ["fire_basic", "ice_basic", "earth_basic"]
		},
		"movement_type": "ground"   # 地面单位
	},
	"blueDino": {
		"stats": {
			"hp": 5.0,
			"defense": 10,
			"speed": 2.0,
			"baseDamage": 5.0,
			"goldYield": 10.0,
			},
		"difficulty": 2.0,
		"sprite": "res://Assets/enemies/dino2.png",
		"element": "ice",
		"special_abilities": [],
		"monster_skills": ["acceleration"],
		"skill_cooldowns": {"acceleration": 5.0},
		"drop_table": {
			"base_chance": 0.06,
			"items": ["ice_basic", "wind_basic"]
		},
		"movement_type": "ground"   # 地面单位
	},
	"yellowDino": {
		"stats": {
			"hp": 10.0,
			"defense": 20,
			"speed": 5.0,
			"baseDamage": 1.0,
			"goldYield": 10.0,
			},
		"difficulty": 3.0,
		"sprite": "res://Assets/enemies/dino3.png",
		"element": "wind",
		"special_abilities": ["stealth"],
		"monster_skills": ["self_destruct"],
		"skill_cooldowns": {"self_destruct": 999.0},
		"drop_table": {
			"base_chance": 0.08,
			"items": ["wind_basic", "light_basic"]
		},
		"movement_type": "ground"   # 地面单位
	},
	"greenDino": {
		"stats": {
			"hp": 10.0,
			"defense": 25,
			"speed": 10.0,
			"baseDamage": 1.0,
			"goldYield": 10.0,
			},
		"difficulty": 4.0,
		"sprite": "res://Assets/enemies/dino4.png",
		"element": "earth",
		"special_abilities": ["split"],
		"monster_skills": ["petrification"],
		"skill_cooldowns": {"petrification": 7.0},
		"drop_table": {
			"base_chance": 0.07,
			"items": ["earth_basic", "dark_basic"]
		},
		"movement_type": "ground"   # 地面单位
	},
	"stealthDino": {
		"stats": {
			"hp": 15.0,
			"defense": 30,
			"speed": 1.5,
			"baseDamage": 5.0,
			"goldYield": 15.0,
		},
		"element": "neutral",
		"special_abilities": ["stealth"],
		"monster_skills": ["acceleration"],
		"skill_cooldowns": {"acceleration": 5.0},
		"drop_table": {
			"base_chance": 0.08,
			"items": ["wind_basic", "light_basic"]
		},
		"difficulty": 2.5,
		"sprite": "res://Assets/enemies/dino2.png",
		"movement_type": "ground"   # 地面单位
	},
	"healerDino": {
		"stats": {
			"hp": 20.0,
			"defense": 40,
			"speed": 0.8,
			"baseDamage": 3.0,
			"goldYield": 20.0,
		},
		"element": "light",
		"special_abilities": ["heal"],
		"monster_skills": ["frost_aura"],
		"skill_cooldowns": {"frost_aura": 8.0},
		"drop_table": {
			"base_chance": 0.10,
			"items": ["light_basic", "light_intermediate"]
		},
		"difficulty": 3.5,
		"sprite": "res://Assets/enemies/dino1.png",
		"movement_type": "ground"   # 地面单位，可被阻挡
	},
	"flyingDragon": {
		"stats": {
			"hp": 15.0,
			"defense": 20,
			"speed": 1.5,
			"baseDamage": 8.0,
			"goldYield": 25.0,
		},
		"element": "wind",
		"special_abilities": [],
		"monster_skills": ["acceleration"],
		"skill_cooldowns": {"acceleration": 10.0},
		"drop_table": {
			"base_chance": 0.08,
			"items": ["wind_basic", "wind_intermediate"]
		},
		"difficulty": 2.5,
		"sprite": "res://Assets/enemies/dino1.png",
		"movement_type": "flying",    # 飞行单位，无法被阻挡
		"flying_height": 20.0         # 飞行高度
	},
	"airScout": {
		"stats": {
			"hp": 8.0,
			"defense": 5,
			"speed": 2.2,
			"baseDamage": 4.0,
			"goldYield": 15.0,
		},
		"element": "neutral",
		"special_abilities": ["stealth"],
		"monster_skills": [],
		"skill_cooldowns": {},
		"drop_table": {
			"base_chance": 0.03,
			"items": ["neutral_basic"]
		},
		"difficulty": 1.8,
		"sprite": "res://Assets/enemies/dino1.png",
		"movement_type": "flying",    # 飞行单位，无法被阻挡
		"flying_height": 15.0         # 飞行高度
	}
}

# 元素系统数据
const elements := {
	"fire": {"name": "火", "color": Color.RED},
	"ice": {"name": "冰", "color": Color.CYAN}, 
	"wind": {"name": "风", "color": Color.GREEN},
	"earth": {"name": "土", "color": Color.SADDLE_BROWN},
	"light": {"name": "光", "color": Color.WHITE},
	"dark": {"name": "暗", "color": Color.BLACK},
	"neutral": {"name": "无属性", "color": Color.GRAY}
}

# 属性克制关系
const element_effectiveness := {
	"fire": {"strong_against": ["wind"], "weak_against": ["ice"]},
	"ice": {"strong_against": ["fire"], "weak_against": ["wind"]},
	"wind": {"strong_against": ["earth"], "weak_against": ["ice"]},
	"earth": {"strong_against": ["fire"], "weak_against": ["wind"]},
	"light": {"strong_against": ["dark"], "weak_against": ["dark"]},
	"dark": {"strong_against": ["light"], "weak_against": ["light"]},
	"neutral": {"strong_against": [], "weak_against": []}
}

# 宝石数据
const gems := {
	"fire_basic": {
		"name": "火焰宝石 1级",
		"element": "fire",
		"level": 1,
		"damage_bonus": 0.10,
		"tower_skills": {
			"arrow_tower": {
				"name": "火箭",
				"description": "命中单位受到灼烧DEBUFF",
				"effects": ["burn_debuff_1"]
			},
			"capture_tower": {
				"name": "火网",
				"description": "范围内所有敌方受到灼热",
				"effects": ["burn_area_1"]
			},
			"mage_tower": {
				"name": "火球",
				"description": "伤害增加20%，命中单位受到灼烧",
				"effects": ["damage_boost_20", "burn_debuff_1"]
			},
			"感应塔": {
				"name": "火捆",
				"description": "范围内的隐身单位受到2层灼烧，受到伤害增加5%",
				"effects": ["burn_debuff_2", "damage_taken_boost_5"]
			},
			"末日塔": {
				"name": "痛楚",
				"description": "伤害间隔降低0.2",
				"effects": ["damage_interval_reduction_0.2"]
			},
			"pulse_tower": {
				"name": "火焰脉冲",
				"description": "攻击范围内所有单位灼热",
				"effects": ["burn_area_1"]
			},
			"弹射塔": {
				"name": "火弹",
				"description": "被弹射目标灼热",
				"effects": ["burn_debuff_1"]
			},
			"aura_tower": {
				"name": "炽热光环",
				"description": "范围内所有塔的攻击速度+3%",
				"effects": ["attack_speed_boost_3"]
			},
			"weakness_tower": {
				"name": "高温",
				"description": "防御力降低5%，受到一层灼烧",
				"effects": ["defense_reduction_5", "burn_debuff_1"]
			}
		},
		"sprite": "res://Assets/gems/fire_basic.png"
	},
	"fire_intermediate": {
		"name": "炽热之心 2级",
		"element": "fire",
		"level": 2,
		"damage_bonus": 0.20,
		"tower_skills": {
			"arrow_tower": {
				"name": "炽火箭",
				"description": "命中单位受到3层灼烧，对风属性伤害增加10%",
				"effects": ["burn_debuff_3", "wind_damage_boost_10"]
			},
			"capture_tower": {
				"name": "焦油火网",
				"description": "受到灼热3层，移动速度降低30%，持续4秒",
				"effects": ["burn_debuff_3", "slow_30"]
			},
			"mage_tower": {
				"name": "天火炼狱",
				"description": "伤害增加30%，范围内造成火海持续4秒，所有目标受到3层灼烧",
				"effects": ["damage_boost_30", "fire_field_4s", "burn_debuff_3"]
			},
			"感应塔": {
				"name": "火牢",
				"description": "范围内的隐身单位受到3层灼烧，受到伤害增加10%",
				"effects": ["burn_debuff_3", "damage_taken_boost_10"]
			},
			"末日塔": {
				"name": "窒息烟尘",
				"description": "伤害间隔降低0.25，持续时间增加10S",
				"effects": ["damage_interval_reduction_0.25", "duration_increase_10s"]
			},
			"pulse_tower": {
				"name": "震荡脉冲",
				"description": "攻击范围内所有单位3层灼烧，打断技能引导，25%几率禁锢0.5秒",
				"effects": ["burn_debuff_3", "interrupt_cast", "imprison_chance_25_0.5s"]
			},
			"弹射塔": {
				"name": "炎爆弹射",
				"description": "被弹射目标灼热3层，对单位造成0.1S炭化",
				"effects": ["burn_debuff_3", "carbonization_0.1s"]
			},
			"aura_tower": {
				"name": "炎热光环",
				"description": "范围内所有塔的攻击速度+5%，充能速度加10%",
				"effects": ["attack_speed_boost_5", "charge_speed_boost_10"]
			},
			"weakness_tower": {
				"name": "中暑",
				"description": "防御力降低10%，受到五层灼烧",
				"effects": ["defense_reduction_10", "burn_debuff_5"]
			}
		},
		"sprite": "res://Assets/gems/fire_intermediate.png"
	},
	"fire_advanced": {
		"name": "炎狱之魂 3级",
		"element": "fire",
		"level": 3,
		"damage_bonus": 0.35,
		"tower_skills": {
			"arrow_tower": {
				"name": "炙热火雨",
				"description": "单体攻击变为3目标攻击，命中单位受到5层灼烧，对风属性伤害增加30%",
				"effects": ["multi_target_3", "burn_debuff_5", "wind_damage_boost_30"]
			},
			"capture_tower": {
				"name": "炭化领域",
				"description": "施放焦油火网，同时在目标范围生成炭化地面，敌人在范围内停留超过2.5秒受到炭化，持续1.5秒",
				"effects": ["burn_debuff_3", "slow_30", "carbonization_field_2.5s"]
			},
			"mage_tower": {
				"name": "超新星引爆",
				"description": "伤害增加50%，范围内造成火海持续4秒，火海内死亡的敌人爆炸，对周围敌人造成伤害并增加5层灼热",
				"effects": ["damage_boost_50", "fire_field_4s", "death_explosion"]
			},
			"感应塔": {
				"name": "火狱",
				"description": "范围内的隐身单位立即受到2S禁锢和5层灼烧，受到伤害增加20%",
				"effects": ["imprison_2s", "burn_debuff_5", "damage_taken_boost_20"]
			},
			"末日塔": {
				"name": "热死病",
				"description": "持续时间无限，伤害间隔降低0.3",
				"effects": ["duration_infinite", "damage_interval_reduction_0.3"]
			},
			"pulse_tower": {
				"name": "地狱火风暴",
				"description": "每次脉冲将范围内所有敌人向外推开，70%炭化0.75秒，敌人变得脆弱，受到伤害增加25%持续3秒",
				"effects": ["knockback_enemies", "carbonization_chance_70_0.75s", "vulnerability_25"]
			},
			"弹射塔": {
				"name": "爆燃连锁",
				"description": "对单位造成0.5S炭化，弹射到的目标灼热层数越高伤害越高，倍率=1+(层数+25)/100",
				"effects": ["carbonization_0.5s", "chain_damage_multiplier"]
			},
			"aura_tower": {
				"name": "炙热光环",
				"description": "范围内所有塔的攻击速度+10%，充能速度加20%",
				"effects": ["attack_speed_boost_10", "charge_speed_boost_20"]
			},
			"weakness_tower": {
				"name": "热射病",
				"description": "防御力降低15%，受到八层灼烧",
				"effects": ["defense_reduction_15", "burn_debuff_8"]
			}
		},
		"sprite": "res://Assets/gems/fire_advanced.png"
	},
	"ice_basic": {
		"name": "初级冰宝石",
		"element": "ice",
		"level": 1,
		"damage_bonus": 0.10,
		"tower_skills": {
			"arrow_tower": {
				"name": "寒冰箭",
				"description": "命中单位减速10%，持续2秒",
				"effects": ["slow_10_2s"]
			},
			"capture_tower": {
				"name": "冰网",
				"description": "捕获减速提升至100%，持续+0.5秒",
				"effects": ["capture_slow_100_duration_0.5s"]
			},
			"mage_tower": {
				"name": "冰锥术",
				"description": "伤害增加20%，直线穿透，施加1层冰霜",
				"effects": ["damage_boost_20", "piercing_shot", "frost_debuff_1"]
			},
			"感应塔": {
				"name": "冰镜",
				"description": "范围内隐身单位移速额外-20%",
				"effects": ["stealth_slow_20"]
			},
			"末日塔": {
				"name": "冰封之触",
				"description": "目标攻击速度-30%，受到1层冰霜",
				"effects": ["attack_speed_reduction_30", "frost_debuff_1"]
			},
			"pulse_tower": {
				"name": "冰霜脉冲",
				"description": "范围内所有单位受到1层冰霜",
				"effects": ["frost_area_1"]
			},
			"弹射塔": {
				"name": "冰片弹射",
				"description": "弹射目标受到1层冰霜",
				"effects": ["frost_on_bounce_1"]
			},
			"aura_tower": {
				"name": "寒冰光环",
				"description": "范围内所有敌人移速-5%",
				"effects": ["aura_slow_5"]
			},
			"weakness_tower": {
				"name": "冻伤",
				"description": "攻击速度-5%，受到1层冰霜",
				"effects": ["attack_speed_reduction_5", "frost_debuff_1"]
			}
		},
		"sprite": "res://Assets/gems/ice_basic.png"
	},
	"ice_intermediate": {
		"name": "寒冰之心 2级",
		"element": "ice",
		"level": 2,
		"damage_bonus": 0.20,
		"tower_skills": {
			"arrow_tower": {
				"name": "彻骨箭",
				"description": "减速20%，持续3秒，施加1层冰霜",
				"effects": ["slow_20_3s", "frost_debuff_1"]
			},
			"capture_tower": {
				"name": "深度冻结",
				"description": "持续再+0.5秒，目标受到1层冰霜",
				"effects": ["capture_slow_100_duration_1s", "frost_debuff_1"]
			},
			"mage_tower": {
				"name": "暴风雪",
				"description": "范围+30%，伤害+40%，施加2层冰霜",
				"effects": ["damage_boost_40", "aoe_range_30", "frost_debuff_2"]
			},
			"感应塔": {
				"name": "寒冰道标",
				"description": "隐身单位受到1层冰霜，被所有塔优先攻击",
				"effects": ["frost_debuff_1", "priority_target"]
			},
			"末日塔": {
				"name": "霜燃",
				"description": "攻击速度-50%，受到2层冰霜",
				"effects": ["attack_speed_reduction_50", "frost_debuff_2"]
			},
			"pulse_tower": {
				"name": "冰霜震击",
				"description": "受到2层冰霜，20%几率冻结0.5秒",
				"effects": ["frost_debuff_2", "freeze_chance_20_0.5s"]
			},
			"弹射塔": {
				"name": "碎冰弹射",
				"description": "弹射次数+1，对有冰霜敌人伤害+30%",
				"effects": ["bounce_count_1", "frost_damage_boost_30"]
			},
			"aura_tower": {
				"name": "深度冻结光环",
				"description": "敌人移速-10%，冻结时间+20%",
				"effects": ["aura_slow_10", "freeze_duration_20"]
			},
			"weakness_tower": {
				"name": "失温",
				"description": "攻击速度-10%，受到2层冰霜",
				"effects": ["attack_speed_reduction_10", "frost_debuff_2"]
			}
		},
		"sprite": "res://Assets/gems/ice_intermediate.png"
	},
	"ice_advanced": {
		"name": "极夜之魂 3级",
		"element": "ice",
		"level": 3,
		"damage_bonus": 0.35,
		"tower_skills": {
			"arrow_tower": {
				"name": "冰河世纪",
				"description": "减速30%，15%几率冻结1秒，施加2层冰霜",
				"effects": ["slow_30_3s", "freeze_chance_15_1s", "frost_debuff_2"]
			},
			"capture_tower": {
				"name": "极寒牢笼",
				"description": "结束时冻结范围内敌人1.5秒",
				"effects": ["capture_slow_100_duration_1s", "frost_debuff_1", "freeze_on_end_1.5s"]
			},
			"mage_tower": {
				"name": "冰川尖刺",
				"description": "主目标冻结2秒，范围内敌人3层冰霜",
				"effects": ["freeze_main_2s", "frost_debuff_3_area"]
			},
			"感应塔": {
				"name": "绝对零度",
				"description": "范围内所有敌人受到2层冰霜，隐身单位冻结1秒",
				"effects": ["frost_debuff_2_area", "freeze_stealth_1s"]
			},
			"末日塔": {
				"name": "永恒冬眠",
				"description": "结束时冻结5秒，死亡时范围冻结周围敌人",
				"effects": ["attack_speed_reduction_50", "frost_debuff_2", "freeze_on_end_5s", "freeze_on_death"]
			},
			"pulse_tower": {
				"name": "极寒风暴",
				"description": "留下冰霜地面3秒，对冻结单位伤害×3",
				"effects": ["frost_ground_3s", "frozen_damage_3x"]
			},
			"弹射塔": {
				"name": "冰锥连锁",
				"description": "弹射20%几率炸裂，小范围冻结0.5秒",
				"effects": ["frost_debuff_1", "freeze_chance_20_0.5s_bounce"]
			},
			"aura_tower": {
				"name": "绝对零度光环",
				"description": "敌人移速-15%，周期性受到冰霜",
				"effects": ["aura_slow_15", "periodic_frost"]
			},
			"weakness_tower": {
				"name": "冰葬",
				"description": "攻击速度-15%，10%几率冻结1秒",
				"effects": ["attack_speed_reduction_15", "freeze_chance_10_1s"]
			}
		},
		"sprite": "res://Assets/gems/ice_advanced.png"
	},
	"wind_basic": {
		"name": "初级风宝石",
		"element": "wind",
		"level": 1,
		"damage_bonus": 0.10,
		"tower_skills": {
			"arrow_tower": {
				"name": "风之矢",
				"description": "攻击速度+15%，吹飞目标",
				"effects": ["attack_speed_boost_15", "knockback_target"]
			},
			"capture_tower": {
				"name": "风缚网",
				"description": "被捕获目标沉默，无法使用技能",
				"effects": ["silence_target"]
			},
			"mage_tower": {
				"name": "风刃",
				"description": "攻击变为3枚风刃，可攻击不同目标",
				"effects": ["multi_wind_blades"]
			},
			"detection_tower": {
				"name": "锐风",
				"description": "范围内隐身单位受到失衡",
				"effects": ["imbalance_stealth"]
			},
			"doomsday_tower": {
				"name": "风之禁锢",
				"description": "目标被沉默",
				"effects": ["silence_target"]
			},
			"pulse_tower": {
				"name": "风压脉冲",
				"description": "脉冲吹飞所有敌人",
				"effects": ["knockback_all"]
			},
			"ricochet_tower": {
				"name": "风刃弹",
				"description": "弹射速度极快，目标受到失衡",
				"effects": ["fast_ricochet", "imbalance_on_hit"]
			},
			"aura_tower": {
				"name": "迅捷光环",
				"description": "范围内所有塔攻击速度+5%",
				"effects": ["attack_speed_aura_5"]
			},
			"weakness_tower": {
				"name": "风蚀",
				"description": "防御力-5%，受到失衡",
				"effects": ["defense_reduction_5", "imbalance_on_hit"]
			}
		},
		"sprite": "res://Assets/gems/wind_basic.png"
	},
	"wind_intermediate": {
		"name": "风暴之心 2级",
		"element": "wind",
		"level": 2,
		"damage_bonus": 0.20,
		"tower_skills": {
			"arrow_tower": {
				"name": "裂风矢",
				"description": "基于1级，攻击速度+25%，施加失衡2秒",
				"effects": ["attack_speed_boost_25", "imbalance_on_hit_2s"]
			},
			"capture_tower": {
				"name": "真空陷阱",
				"description": "基于1级，范围+30%，敌人持续被拉向中心，施加沉默",
				"effects": ["capture_range_30", "pull_to_center", "silence_target"]
			},
			"mage_tower": {
				"name": "连锁风暴",
				"description": "基于1级，风刃可弹射1次，命中目标施加失衡",
				"effects": ["wind_blades_bounce_1", "imbalance_on_hit"]
			},
			"detection_tower": {
				"name": "回音定位",
				"description": "基于1级，隐身单位被沉默，周围敌人也被显形",
				"effects": ["silence_stealth", "reveal_nearby"]
			},
			"doomsday_tower": {
				"name": "真空监牢",
				"description": "基于1级，目标沉默+失衡，50%几率闪避攻击",
				"effects": ["silence_target", "imbalance_on_hit", "dodge_chance_50"]
			},
			"pulse_tower": {
				"name": "紊乱气流",
				"description": "基于1级，施加失衡，15%几率沉默2秒",
				"effects": ["imbalance_all", "silence_chance_15_2s"]
			},
			"ricochet_tower": {
				"name": "穿风弹射",
				"description": "基于1级，弹射次数+2，每次都小幅吹飞目标",
				"effects": ["ricochet_count_2", "small_knockback"]
			},
			"aura_tower": {
				"name": "风怒光环",
				"description": "基于1级，攻击速度+8%，5%几率触发DA",
				"effects": ["attack_speed_aura_8", "da_chance_5"]
			},
			"weakness_tower": {
				"name": "风切",
				"description": "基于1级，防御力-10%，受到失衡，攻击速度-10%",
				"effects": ["defense_reduction_10", "imbalance_on_hit", "attack_speed_reduction_10"]
			}
		},
		"sprite": "res://Assets/gems/wind_intermediate.png"
	},
	"wind_advanced": {
		"name": "天穹之魂 3级",
		"element": "wind",
		"level": 3,
		"damage_bonus": 0.35,
		"tower_skills": {
			"arrow_tower": {
				"name": "风神怒",
				"description": "基于2级，攻击穿透，对后续2目标造成50%伤害，均受吹飞+失衡",
				"effects": ["piercing_attack", "multi_target_2_50", "knockback_all", "imbalance_all"]
			},
			"capture_tower": {
				"name": "风暴之眼",
				"description": "基于2级，变为4秒龙卷风，敌人被卷起(禁锢)，结束时吹飞",
				"effects": ["tornado_4s", "imprison_enemies", "knockback_on_end"]
			},
			"mage_tower": {
				"name": "飓风呼啸",
				"description": "基于2级，目标区域召唤飓风，持续吸引伤害敌人，结束时吹飞",
				"effects": ["hurricane_summon", "pull_and_damage", "knockback_on_end"]
			},
			"detection_tower": {
				"name": "天空之眼",
				"description": "基于2级，所有飞行单位攻速移速-20%，隐身单位沉默",
				"effects": ["flying_debuff_20", "silence_stealth"]
			},
			"doomsday_tower": {
				"name": "放逐",
				"description": "基于2级，将目标放逐异次元8秒，回归时对周围敌人造成伤害(对Boss无效)",
				"effects": ["exile_8s", "damage_on_return", "boss_immune"]
			},
			"pulse_tower": {
				"name": "风怒图腾",
				"description": "基于2级，不造成伤害，为友方塔增加30%攻击速度",
				"effects": ["no_damage", "ally_attack_speed_30"]
			},
			"ricochet_tower": {
				"name": "风之回响",
				"description": "基于2级，弹射结束后，最初目标受到总伤害20%的额外伤害",
				"effects": ["bonus_damage_20_on_end"]
			},
			"aura_tower": {
				"name": "天空光环",
				"description": "基于2级，攻击速度+12%，DA几率+5%，TA几率+3%",
				"effects": ["attack_speed_aura_12", "da_chance_5", "ta_chance_3"]
			},
			"weakness_tower": {
				"name": "风之剥离",
				"description": "基于2级，防御力-15%，受到失衡，被沉默1秒",
				"effects": ["defense_reduction_15", "imbalance_on_hit", "silence_1s"]
			}
		},
		"sprite": "res://Assets/gems/wind_advanced.png"
	},
	"earth_basic": {
		"name": "初级土宝石",
		"element": "earth",
		"level": 1,
		"damage_bonus": 0.10,
		"tower_skills": {
			"arrow_tower": {
				"name": "石肤箭",
				"description": "命中目标受到1层重压和1层破甲",
				"effects": ["weight_debuff_1", "armor_break_debuff_1"]
			},
			"capture_tower": {
				"name": "地陷网",
				"description": "被捕获目标受到2层破甲，防御力-15%",
				"effects": ["armor_break_debuff_2", "defense_reduction_15"]
			},
			"mage_tower": {
				"name": "陨石术",
				"description": "攻击变为范围陨石，伤害+30%，施加2层重压",
				"effects": ["damage_boost_30", "meteor_attack", "weight_debuff_2"]
			},
			"detection_tower": {
				"name": "地听",
				"description": "范围内隐身单位受到1层重压，防御力-10%",
				"effects": ["weight_debuff_1", "defense_reduction_10"]
			},
			"doomsday_tower": {
				"name": "石化凝视",
				"description": "目标防御力持续降低，最多-30%",
				"effects": ["continuous_defense_reduction_30"]
			},
			"pulse_tower": {
				"name": "地震波",
				"description": "脉冲对所有单位造成1层重压",
				"effects": ["weight_area_1"]
			},
			"ricochet_tower": {
				"name": "碎石弹",
				"description": "弹射目标受到1层破甲",
				"effects": ["armor_break_on_bounce_1"]
			},
			"aura_tower": {
				"name": "坚石光环",
				"description": "范围内所有塔物理防御+10%",
				"effects": ["physical_defense_boost_10"]
			},
			"weakness_tower": {
				"name": "破甲",
				"description": "防御力-5%，受到1层重压",
				"effects": ["defense_reduction_5", "weight_debuff_1"]
			}
		},
		"sprite": "res://Assets/gems/earth_basic.png"
	},
	"earth_intermediate": {
		"name": "山脉之心 2级",
		"element": "earth",
		"level": 2,
		"damage_bonus": 0.20,
		"tower_skills": {
			"arrow_tower": {
				"name": "碎岩箭",
				"description": "基于1级效果，施加2层重压和2层破甲",
				"effects": ["weight_debuff_2", "armor_break_debuff_2"]
			},
			"capture_tower": {
				"name": "石化之网",
				"description": "基于1级效果，被捕获目标受到3层破甲，30%几率石化2秒",
				"effects": ["armor_break_debuff_3", "petrify_chance_30_2s"]
			},
			"mage_tower": {
				"name": "地动山摇",
				"description": "基于1级效果，范围+20%，伤害+50%，25%几率石化1秒",
				"effects": ["damage_boost_50", "aoe_range_20", "petrify_chance_25_1s"]
			},
			"detection_tower": {
				"name": "震感",
				"description": "基于1级效果，隐身单位受到破甲，移动时几率石化0.5秒",
				"effects": ["armor_break_debuff_1", "petrify_on_move_0.5s"]
			},
			"doomsday_tower": {
				"name": "地心熔毁",
				"description": "基于1级效果，防御力-50%，每秒受到最大生命1%伤害",
				"effects": ["defense_reduction_50", "max_hp_damage_1_percent"]
			},
			"pulse_tower": {
				"name": "余震",
				"description": "基于1级效果，25%几率触发伤害减半的余震，造成破甲",
				"effects": ["aftershock_chance_25", "armor_break_debuff_1"]
			},
			"ricochet_tower": {
				"name": "巨石弹射",
				"description": "基于1级效果，弹射次数-2但伤害大幅提升，100%造成破甲",
				"effects": ["bounce_count_minus_2", "damage_boost_large", "armor_break_guaranteed"]
			},
			"aura_tower": {
				"name": "山脉光环",
				"description": "基于1级效果，物理防御+20%，获得反伤5%",
				"effects": ["physical_defense_boost_20", "thorns_5"]
			},
			"weakness_tower": {
				"name": "粉碎",
				"description": "基于1级效果，防御力-10%，受到破甲",
				"effects": ["defense_reduction_10", "armor_break_debuff_1"]
			}
		},
		"sprite": "res://Assets/gems/earth_intermediate.png"
	},
	"earth_advanced": {
		"name": "盖亚之魂 3级",
		"element": "earth",
		"level": 3,
		"damage_bonus": 0.35,
		"tower_skills": {
			"arrow_tower": {
				"name": "地龙击",
				"description": "基于2级效果，变为范围攻击，主目标20%几率石化1.5秒",
				"effects": ["weight_debuff_2", "armor_break_debuff_2", "aoe_attack", "petrify_chance_20_1.5s"]
			},
			"capture_tower": {
				"name": "地覆天翻",
				"description": "基于2级效果，捕获区域变为永久重压领域，踏入敌人持续减速破甲",
				"effects": ["armor_break_debuff_3", "permanent_weight_field"]
			},
			"mage_tower": {
				"name": "泰坦之怒",
				"description": "基于2级效果，召唤3颗连续陨石，幸存者受到5层破甲和重压",
				"effects": ["damage_boost_50", "triple_meteor", "armor_break_debuff_5", "weight_debuff_5"]
			},
			"detection_tower": {
				"name": "地脉感应",
				"description": "基于2级效果，感应范围+50%，所有地面单位受到重压",
				"effects": ["detection_range_50", "weight_area_all_ground"]
			},
			"doomsday_tower": {
				"name": "世界崩塌",
				"description": "基于2级效果，持续无限，死亡时召唤永久石化方尖塔阻挡地面单位",
				"effects": ["infinite_duration", "petrify_obelisk_on_death"]
			},
			"pulse_tower": {
				"name": "大地脉动",
				"description": "基于2级效果，不造成伤害，为友方塔提供护盾，敌人受重压+破甲",
				"effects": ["tower_shield", "weight_debuff_1", "armor_break_debuff_1"]
			},
			"ricochet_tower": {
				"name": "山崩",
				"description": "基于2级效果，每次弹射30%几率石化1秒，石化单位刷新时间并弹射到额外2目标",
				"effects": ["petrify_chance_30_1s_bounce", "refresh_on_petrify", "extra_targets_2"]
			},
			"aura_tower": {
				"name": "泰坦光环",
				"description": "基于2级效果，物理防御+25%，反伤10%，免疫破甲",
				"effects": ["physical_defense_boost_25", "thorns_10", "immune_armor_break"]
			},
			"weakness_tower": {
				"name": "山崩",
				"description": "基于2级效果，防御力-15%，受到破甲，10%几率石化1秒",
				"effects": ["defense_reduction_15", "armor_break_debuff_1", "petrify_chance_10_1s"]
			}
		},
		"sprite": "res://Assets/gems/earth_advanced.png"
	},
	"light_basic": {
		"name": "晨曦宝石 1级",
		"element": "light",
		"level": 1,
		"damage_bonus": 0.10,
		"tower_skills": {
			"arrow_tower": {
				"name": "圣光弹",
				"description": "15%几率致盲1.5秒",
				"effects": ["blind_chance_15_1.5s"]
			},
			"capture_tower": {
				"name": "净化网",
				"description": "净化1个增益，返还5能量",
				"effects": ["purify_1_buff", "energy_return_5"]
			},
			"mage_tower": {
				"name": "圣光术",
				"description": "审判1个目标，伤害+20%",
				"effects": ["judgment_1_target", "damage_bonus_20"]
			},
			"感应塔": {
				"name": "光明感知",
				"description": "显现隐身单位，致盲2秒",
				"effects": ["reveal_stealth", "blind_stealth_2s"]
			},
			"末日塔": {
				"name": "圣光净化",
				"description": "审判主要目标",
				"effects": ["judgment_main_target"]
			},
			"脉冲塔": {
				"name": "光之脉冲",
				"description": "致盲范围内敌人1.5秒",
				"effects": ["blind_area_1.5s"]
			},
			"弹射塔": {
				"name": "圣光弹射",
				"description": "弹射时20%几率致盲",
				"effects": ["blind_chance_bounce_20"]
			},
			"aura_tower": {
				"name": "圣光光环",
				"description": "每5秒恢复友方塔生命",
				"effects": ["heal_ally_towers_5s"]
			},
			"weakness_tower": {
				"name": "破甲圣光",
				"description": "防御-5%，致盲",
				"effects": ["defense_reduction_5", "blind_target"]
			}
		},
		"sprite": "res://Assets/gems/light_basic.png"
	},
	"light_intermediate": {
		"name": "耀阳宝石 2级",
		"element": "light",
		"level": 2,
		"damage_bonus": 0.20,
		"tower_skills": {
			"arrow_tower": {
				"name": "审判之箭",
				"description": "30%几率致盲2秒，审判目标",
				"effects": ["blind_chance_30_2s", "judgment_target"]
			},
			"capture_tower": {
				"name": "深度净化",
				"description": "净化所有增益，治疗友方塔",
				"effects": ["purify_all_buffs", "heal_friendly_towers"]
			},
			"mage_tower": {
				"name": "耀阳术",
				"description": "范围审判，伤害+40%",
				"effects": ["judgment_area", "damage_bonus_40"]
			},
			"感应塔": {
				"name": "光明领域",
				"description": "显现所有敌人，致盲隐身单位",
				"effects": ["reveal_all_enemies", "blind_all_stealth"]
			},
			"末日塔": {
				"name": "耀阳审判",
				"description": "审判+扩散效果",
				"effects": ["judgment_spread"]
			},
			"脉冲塔": {
				"name": "耀阳光环",
				"description": "治疗友方塔+致盲敌人",
				"effects": ["heal_towers_blind_enemies"]
			},
			"弹射塔": {
				"name": "耀阳弹射",
				"description": "弹射时净化+致盲",
				"effects": ["purify_bounce", "blind_bounce"]
			},
			"aura_tower": {
				"name": "耀阳光环",
				"description": "净化攻击+充能+10%",
				"effects": ["purify_attack", "energy_bonus_10"]
			},
			"weakness_tower": {
				"name": "审判弱点",
				"description": "防御-10%，审判目标",
				"effects": ["defense_reduction_10", "judgment_target"]
			}
		},
		"sprite": "res://Assets/gems/light_intermediate.png"
	},
	"light_advanced": {
		"name": "天堂宝石 3级",
		"element": "light",
		"level": 3,
		"damage_bonus": 0.35,
		"tower_skills": {
			"arrow_tower": {
				"name": "天堂之箭",
				"description": "50%几率致盲3秒，审判扩散",
				"effects": ["blind_chance_50_3s", "judgment_spread"]
			},
			"capture_tower": {
				"name": "天堂净化",
				"description": "净化+治疗+能量返还",
				"effects": ["purify_heal_energy_return"]
			},
			"mage_tower": {
				"name": "天堂回响",
				"description": "审判额外伤害+审判扩散",
				"effects": ["judgment_extra_damage", "judgment_spread"]
			},
			"感应塔": {
				"name": "天堂感知",
				"description": "优先攻击审判目标，反隐身+致盲",
				"effects": ["prioritize_judgment", "anti_stealth_blind"]
			},
			"末日塔": {
				"name": "天堂末日",
				"description": "审判扩散+神圣伤害",
				"effects": ["judgment_spread_holy"]
			},
			"脉冲塔": {
				"name": "天堂圣光",
				"description": "大规模治疗+审判",
				"effects": ["mass_heal_judgment"]
			},
			"弹射塔": {
				"name": "天堂弹射",
				"description": "弹射审判+扩散",
				"effects": ["bounce_judgment_spread"]
			},
			"aura_tower": {
				"name": "天堂光环",
				"description": "持续治疗+净化+能量返还",
				"effects": ["continuous_heal_purify_energy"]
			},
			"weakness_tower": {
				"name": "天堂审判",
				"description": "防御-15%，审判+神圣伤害",
				"effects": ["defense_reduction_15", "judgment_holy_damage"]
			}
		},
		"sprite": "res://Assets/gems/light_advanced.png"
	},
	"dark_basic": {
		"name": "暗影宝石 1级",
		"element": "dark",
		"level": 1,
		"damage_bonus": 0.10,
		"tower_skills": {
			"arrow_tower": {
				"name": "暗影箭",
				"description": "命中单位受到腐蚀+30%吸血",
				"effects": ["corrosion_1", "life_steal_30"]
			},
			"capture_tower": {
				"name": "暗影之网",
				"description": "2层腐蚀+治疗-50%",
				"effects": ["corrosion_2", "healing_reduction_50"]
			},
			"mage_tower": {
				"name": "痛苦诅咒",
				"description": "腐蚀+死亡传染",
				"effects": ["corrosion_1", "death_contagion"]
			},
			"detection_tower": {
				"name": "暗影侦测",
				"description": "腐蚀",
				"effects": ["corrosion_1"]
			},
			"doomsday_tower": {
				"name": "暗影契约",
				"description": "50%伤害转化生命",
				"effects": ["life_steal_50"]
			},
			"pulse_tower": {
				"name": "凋零脉冲",
				"description": "腐蚀",
				"effects": ["corrosion_1"]
			},
			"ricochet_tower": {
				"name": "腐蚀弹",
				"description": "腐蚀",
				"effects": ["corrosion_1"]
			},
			"aura_tower": {
				"name": "吸血光环",
				"description": "5%生命虹吸",
				"effects": ["life_drain_aura_5"]
			},
			"weakness_tower": {
				"name": "腐蚀",
				"description": "防御-5%+腐蚀",
				"effects": ["defense_reduction_5", "corrosion_1"]
			}
		},
		"sprite": "res://Assets/gems/dark_basic.png"
	},
	"dark_intermediate": {
		"name": "暗影之心 2级",
		"element": "dark",
		"level": 2,
		"damage_bonus": 0.20,
		"tower_skills": {
			"arrow_tower": {
				"name": "吸血箭",
				"description": "2层腐蚀+50%吸血",
				"effects": ["corrosion_2", "life_steal_50"]
			},
			"capture_tower": {
				"name": "恐惧之网",
				"description": "50%恐惧2秒",
				"effects": ["fear_chance_50_2s"]
			},
			"mage_tower": {
				"name": "生命吸取",
				"description": "引导吸血+腐蚀",
				"effects": ["channel_life_drain", "corrosion_2"]
			},
			"detection_tower": {
				"name": "恐惧降临",
				"description": "侦测时周围恐惧",
				"effects": ["fear_area_detection"]
			},
			"doomsday_tower": {
				"name": "灵魂灼烧",
				"description": "腐蚀+生命虹吸+无法治疗",
				"effects": ["corrosion_3", "life_drain_20", "no_healing"]
			},
			"pulse_tower": {
				"name": "恐惧脉冲",
				"description": "20%恐惧1.5秒",
				"effects": ["fear_chance_20_1.5s"]
			},
			"ricochet_tower": {
				"name": "虹吸弹射",
				"description": "生命虹吸+所有塔吸血",
				"effects": ["life_drain_15", "all_towers_life_steal"]
			},
			"aura_tower": {
				"name": "腐败光环",
				"description": "治疗-25%+持续腐蚀",
				"effects": ["healing_reduction_25", "corrosion_aura"]
			},
			"weakness_tower": {
				"name": "凋零",
				"description": "防御-10%+腐蚀+生命虹吸",
				"effects": ["defense_reduction_10", "corrosion_2", "life_drain_10"]
			}
		},
		"sprite": "res://Assets/gems/dark_intermediate.png"
	},
	"dark_advanced": {
		"name": "暗影之魂 3级",
		"element": "dark",
		"level": 3,
		"damage_bonus": 0.35,
		"tower_skills": {
			"arrow_tower": {
				"name": "灵魂榨取",
				"description": "3层腐蚀+100%吸血+死亡永久+1攻击",
				"effects": ["corrosion_3", "life_steal_100", "permanent_attack_steal"]
			},
			"capture_tower": {
				"name": "绝望深渊",
				"description": "3层腐蚀+生命虹吸+范围内吸血",
				"effects": ["corrosion_3", "life_drain_25", "area_life_steal"]
			},
			"mage_tower": {
				"name": "灵魂火",
				"description": "消耗10%生命+巨量伤害+恐惧",
				"effects": ["life_cost_10", "massive_damage", "fear_on_hit"]
			},
			"detection_tower": {
				"name": "虚空之眼",
				"description": "治疗-30%+隐身生命虹吸",
				"effects": ["healing_reduction_30", "stealth_life_drain"]
			},
			"doomsday_tower": {
				"name": "末日降临",
				"description": "无限持续+死亡偷取10%攻防",
				"effects": ["infinite_duration", "stat_steal_on_death_10"]
			},
			"pulse_tower": {
				"name": "生命献祭",
				"description": "消耗5%生命+5倍伤害+生命虹吸",
				"effects": ["life_cost_5", "damage_multiplier_5", "life_drain_30"]
			},
			"ricochet_tower": {
				"name": "恐惧连锁",
				"description": "15%恐惧+优先攻击未恐惧",
				"effects": ["fear_chance_15", "prioritize_unfeared"]
			},
			"aura_tower": {
				"name": "深渊光环",
				"description": "10%生命虹吸+治疗-50%+持续腐蚀",
				"effects": ["life_drain_aura_10", "healing_reduction_50", "corrosion_aura"]
			},
			"weakness_tower": {
				"name": "绝望",
				"description": "防御-15%+腐蚀+生命虹吸+无法治疗",
				"effects": ["defense_reduction_15", "corrosion_3", "life_drain_20", "no_healing"]
			}
		},
		"sprite": "res://Assets/gems/dark_advanced.png"
	}
}

# 效果定义
const effects := {
	# 灼烧效果
	"burn_debuff_1": {
		"type": "debuff",
		"debuff_type": "burn",
		"stacks": 1,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	"burn_debuff_3": {
		"type": "debuff", 
		"debuff_type": "burn",
		"stacks": 3,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	"burn_debuff_5": {
		"type": "debuff",
		"debuff_type": "burn", 
		"stacks": 5,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	"burn_debuff_8": {
		"type": "debuff",
		"debuff_type": "burn", 
		"stacks": 8,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	
	# 属性修改器
	"damage_boost_20": {
		"type": "stat_modifier",
		"stat": "damage",
		"operation": "multiply",
		"value": 1.20
	},
	"damage_boost_30": {
		"type": "stat_modifier",
		"stat": "damage",
		"operation": "multiply",
		"value": 1.30
	},
	"damage_boost_50": {
		"type": "stat_modifier",
		"stat": "damage",
		"operation": "multiply",
		"value": 1.50
	},
	
	# 攻击修改器
	"multi_target_3": {
		"type": "attack_modifier",
		"property": "target_count",
		"value": 3
	},
	"multi_target_5": {
		"type": "attack_modifier",
		"property": "target_count",
		"value": 5
	},
	
	# 伤害修改器
	"wind_damage_boost_10": {
		"type": "damage_modifier",
		"target_element": "wind",
		"multiplier": 1.10
	},
	"wind_damage_boost_30": {
		"type": "damage_modifier",
		"target_element": "wind",
		"multiplier": 1.30
	},
	
	# 防御修改器
	"defense_reduction_5": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.95
	},
	"defense_reduction_10": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.90
	},
	"defense_reduction_15": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.85
	},
	
	# 攻速修改器
	"attack_speed_boost_3": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 1.03
	},
	"attack_speed_boost_5": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 1.05
	},
	"attack_speed_boost_10": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 1.10
	},
	
	# 充能速度修改器
	"charge_speed_boost_10": {
		"type": "stat_modifier",
		"stat": "charge_speed",
		"operation": "multiply",
		"value": 1.10
	},
	"charge_speed_boost_20": {
		"type": "stat_modifier",
		"stat": "charge_speed",
		"operation": "multiply",
		"value": 1.20
	},
	
	# 伤害间隔修改器
	"damage_interval_reduction_0.2": {
		"type": "stat_modifier",
		"stat": "damage_interval",
		"operation": "add",
		"value": -0.2
	},
	"damage_interval_reduction_0.25": {
		"type": "stat_modifier",
		"stat": "damage_interval",
		"operation": "add",
		"value": -0.25
	},
	"damage_interval_reduction_0.3": {
		"type": "stat_modifier",
		"stat": "damage_interval",
		"operation": "add",
		"value": -0.3
	},
	
	# 特殊效果
	"carbonization_0.1s": {
		"type": "debuff",
		"debuff_type": "炭化",
		"duration": 0.1
	},
	"carbonization_0.5s": {
		"type": "debuff",
		"debuff_type": "炭化",
		"duration": 0.5
	},
	"carbonization_1.5s": {
		"type": "debuff",
		"debuff_type": "炭化",
		"duration": 1.5
	},
	"imprison_2s": {
		"type": "debuff",
		"debuff_type": "禁锢",
		"duration": 2.0
	},
	"vulnerability_25": {
		"type": "debuff",
		"debuff_type": "脆弱",
		"damage_increase": 0.25,
		"duration": 3.0
	},
	
	# 移动速度修改器
	"slow_30": {
		"type": "stat_modifier",
		"stat": "movement_speed",
		"operation": "multiply",
		"value": 0.70,
		"duration": 4.0
	},
	
	# 伤害承受增加
	"damage_taken_boost_5": {
		"type": "stat_modifier",
		"stat": "damage_taken",
		"operation": "multiply",
		"value": 1.05,
		"duration": 3.0
	},
	"damage_taken_boost_10": {
		"type": "stat_modifier",
		"stat": "damage_taken",
		"operation": "multiply",
		"value": 1.10,
		"duration": 3.0
	},
	"damage_taken_boost_20": {
		"type": "stat_modifier",
		"stat": "damage_taken",
		"operation": "multiply",
		"value": 1.20,
		"duration": 3.0
	},
	
	# 特殊效果（占位符，后续实现）
	"burn_area_1": {
		"type": "special",
		"effect_type": "area_burn",
		"stacks": 1
	},
	"burn_debuff_2": {
		"type": "debuff",
		"debuff_type": "burn",
		"stacks": 2,
		"damage_per_second": 5.0,
		"duration": 3.0
	},
	"duration_increase_10s": {
		"type": "stat_modifier",
		"stat": "effect_duration",
		"operation": "add",
		"value": 10.0
	},
	"interrupt_cast": {
		"type": "special",
		"effect_type": "interrupt"
	},
	"imprison_chance_25_0.5s": {
		"type": "special",
		"effect_type": "chance_imprison",
		"chance": 0.25,
		"duration": 0.5
	},
	"duration_infinite": {
		"type": "special",
		"effect_type": "infinite_duration"
	},
	"knockback_enemies": {
		"type": "special",
		"effect_type": "knockback"
	},
	"carbonization_chance_70_0.75s": {
		"type": "special",
		"effect_type": "chance_carbonization",
		"chance": 0.70,
		"duration": 0.75
	},
	"chain_damage_multiplier": {
		"type": "special",
		"effect_type": "chain_multiplier"
	},
	"fire_field_4s": {
		"type": "special",
		"effect_type": "fire_field",
		"duration": 4.0
	},
	"death_explosion": {
		"type": "special",
		"effect_type": "explosion_on_death"
	},
	"carbonization_field_2.5s": {
		"type": "special",
		"effect_type": "carbonization_field",
		"trigger_time": 2.5,
		"duration": 1.5
	},
	
	# 冰霜效果
	"frost_debuff_1": {
		"type": "debuff",
		"debuff_type": "frost",
		"stacks": 1,
		"slow_per_stack": 0.02,
		"damage_bonus": 0.02,
		"duration": 4.0
	},
	"frost_debuff_2": {
		"type": "debuff",
		"debuff_type": "frost",
		"stacks": 2,
		"slow_per_stack": 0.02,
		"damage_bonus": 0.02,
		"duration": 4.0
	},
	"frost_debuff_3": {
		"type": "debuff",
		"debuff_type": "frost",
		"stacks": 3,
		"slow_per_stack": 0.02,
		"damage_bonus": 0.02,
		"duration": 4.0
	},
	
	# 减速效果
	"slow_10_2s": {
		"type": "stat_modifier",
		"stat": "movement_speed",
		"operation": "multiply",
		"value": 0.90,
		"duration": 2.0
	},
	"slow_20_3s": {
		"type": "stat_modifier",
		"stat": "movement_speed",
		"operation": "multiply",
		"value": 0.80,
		"duration": 3.0
	},
	"slow_30_3s": {
		"type": "stat_modifier",
		"stat": "movement_speed",
		"operation": "multiply",
		"value": 0.70,
		"duration": 3.0
	},
	
	# 攻击速度降低
	"attack_speed_reduction_5": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 0.95,
		"duration": 3.0
	},
	"attack_speed_reduction_10": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 0.90,
		"duration": 3.0
	},
	"attack_speed_reduction_15": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 0.85,
		"duration": 3.0
	},
	"attack_speed_reduction_30": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 0.70,
		"duration": 3.0
	},
	"attack_speed_reduction_50": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 0.50,
		"duration": 3.0
	},
	
	# 冰霜特殊效果
	"frost_area_1": {
		"type": "special",
		"effect_type": "frost_area",
		"stacks": 1
	},
	"frost_on_bounce_1": {
		"type": "special",
		"effect_type": "frost_on_bounce",
		"stacks": 1
	},
	"aura_slow_5": {
		"type": "special",
		"effect_type": "aura_slow",
		"slow_amount": 0.05
	},
	"aura_slow_10": {
		"type": "special",
		"effect_type": "aura_slow",
		"slow_amount": 0.10
	},
	"aura_slow_15": {
		"type": "special",
		"effect_type": "aura_slow",
		"slow_amount": 0.15
	},
	
	# 冻结效果
	"freeze_chance_15_1s": {
		"type": "special",
		"effect_type": "chance_freeze",
		"chance": 0.15,
		"duration": 1.0
	},
	"freeze_chance_20_0.5s": {
		"type": "special",
		"effect_type": "chance_freeze",
		"chance": 0.20,
		"duration": 0.5
	},
	"freeze_chance_10_1s": {
		"type": "special",
		"effect_type": "chance_freeze",
		"chance": 0.10,
		"duration": 1.0
	},
	"freeze_chance_20_0.5s_bounce": {
		"type": "special",
		"effect_type": "chance_freeze_bounce",
		"chance": 0.20,
		"duration": 0.5
	},
	"freeze_main_2s": {
		"type": "special",
		"effect_type": "freeze_main_target",
		"duration": 2.0
	},
	"freeze_on_end_1.5s": {
		"type": "special",
		"effect_type": "freeze_on_effect_end",
		"duration": 1.5
	},
	"freeze_on_end_5s": {
		"type": "special",
		"effect_type": "freeze_on_effect_end",
		"duration": 5.0
	},
	"freeze_stealth_1s": {
		"type": "special",
		"effect_type": "freeze_stealth_units",
		"duration": 1.0
	},
	"freeze_on_death": {
		"type": "special",
		"effect_type": "freeze_on_death"
	},
	
	# 其他冰霜效果
	"capture_slow_100_duration_0.5s": {
		"type": "special",
		"effect_type": "capture_slow_bonus",
		"slow_multiplier": 1.0,
		"duration_bonus": 0.5
	},
	"capture_slow_100_duration_1s": {
		"type": "special",
		"effect_type": "capture_slow_bonus",
		"slow_multiplier": 1.0,
		"duration_bonus": 1.0
	},
	"stealth_slow_20": {
		"type": "special",
		"effect_type": "stealth_slow",
		"slow_amount": 0.20
	},
	"priority_target": {
		"type": "special",
		"effect_type": "priority_targeting"
	},
	"damage_boost_40": {
		"type": "stat_modifier",
		"stat": "damage",
		"operation": "multiply",
		"value": 1.40
	},
	"aoe_range_30": {
		"type": "attack_modifier",
		"property": "aoe_range",
		"value": 1.30
	},
	"frost_debuff_2_area": {
		"type": "special",
		"effect_type": "frost_debuff_area",
		"stacks": 2
	},
	"frost_debuff_3_area": {
		"type": "special",
		"effect_type": "frost_debuff_area",
		"stacks": 3
	},
	"frost_ground_3s": {
		"type": "special",
		"effect_type": "frost_ground",
		"duration": 3.0
	},
	"frozen_damage_3x": {
		"type": "special",
		"effect_type": "frozen_damage_multiplier",
		"multiplier": 3.0
	},
	"bounce_count_1": {
		"type": "attack_modifier",
		"property": "bounce_count",
		"value": 1
	},
	"frost_damage_boost_30": {
		"type": "damage_modifier",
		"target_condition": "frost",
		"multiplier": 1.30
	},
	"freeze_duration_20": {
		"type": "special",
		"effect_type": "freeze_duration_bonus",
		"bonus": 0.20
	},
	"periodic_frost": {
		"type": "special",
		"effect_type": "periodic_frost",
		"interval": 2.0
	},
	"piercing_shot": {
		"type": "attack_modifier",
		"property": "piercing",
		"value": true
	},
	
	# 土系效果 - 重压
	"weight_debuff_1": {
		"type": "debuff",
		"debuff_type": "weight",
		"stacks": 1,
		"speed_reduction_per_stack": 0.015,
		"defense_reduction_per_stack": 1.0,
		"duration": 4.0
	},
	"weight_debuff_2": {
		"type": "debuff",
		"debuff_type": "weight",
		"stacks": 2,
		"speed_reduction_per_stack": 0.015,
		"defense_reduction_per_stack": 1.0,
		"duration": 4.0
	},
	"weight_debuff_3": {
		"type": "debuff",
		"debuff_type": "weight",
		"stacks": 3,
		"speed_reduction_per_stack": 0.015,
		"defense_reduction_per_stack": 1.0,
		"duration": 4.0
	},
	"weight_debuff_5": {
		"type": "debuff",
		"debuff_type": "weight",
		"stacks": 5,
		"speed_reduction_per_stack": 0.015,
		"defense_reduction_per_stack": 1.0,
		"duration": 4.0
	},
	
	# 土系效果 - 破甲
	"armor_break_debuff_1": {
		"type": "debuff",
		"debuff_type": "armor_break",
		"stacks": 1,
		"defense_reduction_percent": 0.05,
		"duration": 5.0
	},
	"armor_break_debuff_2": {
		"type": "debuff",
		"debuff_type": "armor_break",
		"stacks": 2,
		"defense_reduction_percent": 0.05,
		"duration": 5.0
	},
	"armor_break_debuff_3": {
		"type": "debuff",
		"debuff_type": "armor_break",
		"stacks": 3,
		"defense_reduction_percent": 0.05,
		"duration": 5.0
	},
	"armor_break_debuff_5": {
		"type": "debuff",
		"debuff_type": "armor_break",
		"stacks": 5,
		"defense_reduction_percent": 0.05,
		"duration": 5.0
	},
	
	# 土系效果 - 石化
	"petrify_chance_10_1s": {
		"type": "special",
		"effect_type": "chance_petrify",
		"chance": 0.10,
		"duration": 1.0
	},
	"petrify_chance_20_1.5s": {
		"type": "special",
		"effect_type": "chance_petrify",
		"chance": 0.20,
		"duration": 1.5
	},
	"petrify_chance_25_1s": {
		"type": "special",
		"effect_type": "chance_petrify",
		"chance": 0.25,
		"duration": 1.0
	},
	"petrify_chance_30_1s": {
		"type": "special",
		"effect_type": "chance_petrify",
		"chance": 0.30,
		"duration": 1.0
	},
	"petrify_chance_30_2s": {
		"type": "special",
		"effect_type": "chance_petrify",
		"chance": 0.30,
		"duration": 2.0
	},
	
	# 土系特殊效果
	"weight_area_1": {
		"type": "special",
		"effect_type": "weight_area",
		"stacks": 1
	},
	"armor_break_on_bounce_1": {
		"type": "special",
		"effect_type": "armor_break_on_bounce",
		"stacks": 1
	},
	"meteor_attack": {
		"type": "attack_modifier",
		"property": "meteor",
		"value": true
	},
	"triple_meteor": {
		"type": "attack_modifier",
		"property": "triple_meteor",
		"value": true
	},
	"aoe_attack": {
		"type": "attack_modifier",
		"property": "aoe",
		"value": true
	},
	"physical_defense_boost_10": {
		"type": "stat_modifier",
		"stat": "physical_defense",
		"operation": "multiply",
		"value": 1.10
	},
	"physical_defense_boost_20": {
		"type": "stat_modifier",
		"stat": "physical_defense",
		"operation": "multiply",
		"value": 1.20
	},
	"physical_defense_boost_25": {
		"type": "stat_modifier",
		"stat": "physical_defense",
		"operation": "multiply",
		"value": 1.25
	},
	"thorns_5": {
		"type": "special",
		"effect_type": "thorns",
		"percentage": 0.05
	},
	"thorns_10": {
		"type": "special",
		"effect_type": "thorns",
		"percentage": 0.10
	},
	"continuous_defense_reduction_30": {
		"type": "special",
		"effect_type": "continuous_defense_reduction",
		"max_reduction": 0.30
	},
	"max_hp_damage_1_percent": {
		"type": "special",
		"effect_type": "max_hp_damage",
		"percentage": 0.01
	},
	"aftershock_chance_25": {
		"type": "special",
		"effect_type": "aftershock",
		"chance": 0.25,
		"damage_multiplier": 0.5
	},
	"bounce_count_minus_2": {
		"type": "attack_modifier",
		"property": "bounce_count",
		"value": -2
	},
	"damage_boost_large": {
		"type": "stat_modifier",
		"stat": "damage",
		"operation": "multiply",
		"value": 2.0
	},
	"armor_break_guaranteed": {
		"type": "special",
		"effect_type": "guaranteed_armor_break"
	},
	"detection_range_50": {
		"type": "attack_modifier",
		"property": "detection_range",
		"value": 1.50
	},
	"weight_area_all_ground": {
		"type": "special",
		"effect_type": "weight_area_all_ground"
	},
	"infinite_duration": {
		"type": "special",
		"effect_type": "infinite_duration"
	},
	"petrify_obelisk_on_death": {
		"type": "special",
		"effect_type": "petrify_obelisk_on_death"
	},
	"tower_shield": {
		"type": "special",
		"effect_type": "tower_shield",
		"shield_amount": 100.0
	},
	"petrify_chance_30_1s_bounce": {
		"type": "special",
		"effect_type": "petrify_chance_bounce",
		"chance": 0.30,
		"duration": 1.0
	},
	"refresh_on_petrify": {
		"type": "special",
		"effect_type": "refresh_on_petrify"
	},
	"extra_targets_2": {
		"type": "attack_modifier",
		"property": "extra_targets",
		"value": 2
	},
	"immune_armor_break": {
		"type": "special",
		"effect_type": "immune_armor_break"
	},
	"permanent_weight_field": {
		"type": "special",
		"effect_type": "permanent_weight_field"
	},
	"petrify_on_move_0.5s": {
		"type": "special",
		"effect_type": "petrify_on_move",
		"chance": 0.20,
		"duration": 0.5
	},
	
	# 风系效果 - 攻击速度提升
	"attack_speed_boost_15": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 1.15
	},
	"attack_speed_boost_25": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 1.25
	},
	
	# 风系效果 - 击退
	"knockback_target": {
		"type": "special",
		"effect_type": "knockback",
		"force": 150.0
	},
	"knockback_all": {
		"type": "special",
		"effect_type": "knockback_all",
		"force": 200.0
	},
	"small_knockback": {
		"type": "special",
		"effect_type": "knockback",
		"force": 80.0
	},
	
	# 风系效果 - 失衡
	"imbalance_on_hit": {
		"type": "debuff",
		"debuff_type": "imbalance",
		"duration": 2.0
	},
	"imbalance_on_hit_2s": {
		"type": "debuff",
		"debuff_type": "imbalance",
		"duration": 2.0
	},
	"imbalance_all": {
		"type": "special",
		"effect_type": "imbalance_area",
		"duration": 2.0
	},
	"imbalance_stealth": {
		"type": "special",
		"effect_type": "imbalance_stealth",
		"duration": 2.0
	},
	
	# 风系效果 - 沉默
	"silence_target": {
		"type": "debuff",
		"debuff_type": "silence",
		"duration": 3.0
	},
	"silence_stealth": {
		"type": "special",
		"effect_type": "silence_stealth",
		"duration": 3.0
	},
	"silence_chance_15_2s": {
		"type": "special",
		"effect_type": "silence_chance",
		"chance": 0.15,
		"duration": 2.0
	},
	"silence_1s": {
		"type": "debuff",
		"debuff_type": "silence",
		"duration": 1.0
	},
	
	# 风系效果 - 防御降低
	"defense_reduction_5": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.95
	},
	"defense_reduction_10": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.90
	},
	"defense_reduction_15": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "multiply",
		"value": 0.85
	},
	
	# 风系特殊效果
	"multi_wind_blades": {
		"type": "attack_modifier",
		"property": "multi_shot",
		"value": 3
	},
	"capture_range_30": {
		"type": "attack_modifier",
		"property": "attack_range",
		"value": 1.30
	},
	"pull_to_center": {
		"type": "special",
		"effect_type": "pull_to_center",
		"force": 100.0
	},
	"wind_blades_bounce_1": {
		"type": "attack_modifier",
		"property": "bounce_count",
		"value": 1
	},
	"reveal_nearby": {
		"type": "special",
		"effect_type": "reveal_nearby",
		"range": 100.0
	},
	"dodge_chance_50": {
		"type": "special",
		"effect_type": "dodge_chance",
		"chance": 0.50
	},
	"ricochet_count_2": {
		"type": "attack_modifier",
		"property": "bounce_count",
		"value": 2
	},
	"attack_speed_aura_5": {
		"type": "special",
		"effect_type": "attack_speed_aura",
		"bonus": 0.05,
		"range": 150.0
	},
	"attack_speed_aura_8": {
		"type": "special",
		"effect_type": "attack_speed_aura",
		"bonus": 0.08,
		"range": 150.0
	},
	"attack_speed_aura_12": {
		"type": "special",
		"effect_type": "attack_speed_aura",
		"bonus": 0.12,
		"range": 150.0
	},
	"attack_speed_reduction_10": {
		"type": "stat_modifier",
		"stat": "attack_speed",
		"operation": "multiply",
		"value": 0.90
	},
	"da_chance_5": {
		"type": "stat_modifier",
		"stat": "da_bonus",
		"operation": "add",
		"value": 0.05
	},
	"ta_chance_3": {
		"type": "stat_modifier",
		"stat": "ta_bonus",
		"operation": "add",
		"value": 0.03
	},
	"fast_ricochet": {
		"type": "attack_modifier",
		"property": "projectile_speed",
		"value": 2.0
	},
	"piercing_attack": {
		"type": "attack_modifier",
		"property": "piercing",
		"value": true
	},
	"multi_target_2_50": {
		"type": "attack_modifier",
		"property": "chain_targets",
		"value": 2,
		"damage_multiplier": 0.5
	},
	"tornado_4s": {
		"type": "special",
		"effect_type": "tornado",
		"duration": 4.0
	},
	"imprison_enemies": {
		"type": "special",
		"effect_type": "imprison",
		"duration": 4.0
	},
	"knockback_on_end": {
		"type": "special",
		"effect_type": "knockback_on_end",
		"force": 200.0
	},
	"hurricane_summon": {
		"type": "special",
		"effect_type": "hurricane",
		"duration": 5.0
	},
	"pull_and_damage": {
		"type": "special",
		"effect_type": "pull_and_damage",
		"pull_force": 50.0,
		"damage_per_second": 20.0
	},
	"flying_debuff_20": {
		"type": "special",
		"effect_type": "flying_debuff",
		"speed_reduction": 0.20,
		"attack_speed_reduction": 0.20
	},
	"exile_8s": {
		"type": "special",
		"effect_type": "exile",
		"duration": 8.0
	},
	"damage_on_return": {
		"type": "special",
		"effect_type": "damage_on_return",
		"damage_multiplier": 1.0
	},
	"boss_immune": {
		"type": "special",
		"effect_type": "boss_immune"
	},
	"no_damage": {
		"type": "attack_modifier",
		"property": "damage",
		"value": 0.0
	},
	"ally_attack_speed_30": {
		"type": "special",
		"effect_type": "ally_attack_speed_aura",
		"bonus": 0.30,
		"range": 200.0
	},
	"bonus_damage_20_on_end": {
		"type": "special",
		"effect_type": "bonus_damage_on_end",
		"damage_multiplier": 0.20
	}
}

# 武器盘BUFF数据
const weapon_wheel_buffs := {
	"projectile_damage": {
		"name": "投射物伤害",
		"applies_to": ["gatling", "laser"],
		"bonus": 0.05
	},
	"ray_damage": {
		"name": "射线伤害", 
		"applies_to": ["ray"],
		"bonus": 0.08
	},
	"melee_damage": {
		"name": "近战伤害",
		"applies_to": ["melee"], 
		"bonus": 0.06
	},
	"fire_element": {
		"name": "火元素强化",
		"element_type": "fire",
		"bonus": 0.10
	},
	"ice_element": {
		"name": "冰元素强化",
		"element_type": "ice",
		"bonus": 0.10
	},
	"wind_element": {
		"name": "风元素强化",
		"element_type": "wind",
		"bonus": 0.10
	},
	"earth_element": {
		"name": "土元素强化",
		"element_type": "earth",
		"bonus": 0.10
	},
	"light_element": {
		"name": "光元素强化",
		"element_type": "light",
		"bonus": 0.10
	},
	"dark_element": {
		"name": "暗元素强化",
		"element_type": "dark",
		"bonus": 0.10
	}
}

const maps := {
	"map1": {
		"name": "Grass Map",
		"bg": "res://Assets/maps/map1.webp",
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 10,
		"startingGold": 100,
		"spawner_settings":
			{
			"difficulty": {"initial": 2.0, "increase": 1.5, "multiplies": true},
			"max_waves": 10,
			"wave_spawn_count": 10,
			"special_waves": {},
			},
	},
	"map2": {
		"name": "Desert Map",
		"bg": "res://Assets/maps/map2.png",
		"scene": "res://Scenes/maps/map2.tscn",
		"baseHp": 15,
		"startingGold": 200,
		"spawner_settings":
			{
			"difficulty": {"initial": 1.0, "increase": 1.2, "multiplies": true},
			"max_waves": 10,
			"wave_spawn_count": 10,
			"special_waves": {},
			},
	},
	# Chapter 1 Maps
	"chapter1_level1": {
		"name": "Chapter 1 - Level 1",
		"bg": "res://Assets/maps/map1.webp",
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 20,
		"startingGold": 150,
		"chapter": 1,
		"level": 1,
		"spawner_settings": {
			"difficulty": {"initial": 1.0, "increase": 1.1, "multiplies": true},
			"max_waves": 20,
			"wave_spawn_count": 8,
			"special_waves": {
				10: {"enemy_type": "redDino", "count": 15},
				20: {"enemy_type": "blueDino", "count": 5}
			},
		},
	},
	"chapter1_level2": {
		"name": "Chapter 1 - Level 2", 
		"bg": "res://Assets/maps/map2.png",
		"scene": "res://Scenes/maps/map2.tscn",
		"baseHp": 20,
		"startingGold": 150,
		"chapter": 1,
		"level": 2,
		"spawner_settings": {
			"difficulty": {"initial": 1.2, "increase": 1.15, "multiplies": true},
			"max_waves": 20,
			"wave_spawn_count": 10,
			"special_waves": {
				5: {"enemy_type": "redDino", "count": 12},
				15: {"enemy_type": "blueDino", "count": 8},
				20: {"enemy_type": "yellowDino", "count": 3}
			},
		},
	},
	"chapter1_level3": {
		"name": "Chapter 1 - Level 3",
		"bg": "res://Assets/maps/map1.webp", 
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 25,
		"startingGold": 200,
		"chapter": 1,
		"level": 3,
		"spawner_settings": {
			"difficulty": {"initial": 1.5, "increase": 1.2, "multiplies": true},
			"max_waves": 30,
			"wave_spawn_count": 12,
			"special_waves": {
				10: {"enemy_type": "redDino", "count": 20},
				20: {"enemy_type": "blueDino", "count": 15},
				25: {"enemy_type": "yellowDino", "count": 8},
				30: {"enemy_type": "greenDino", "count": 5}
			},
		},
	},
	"chapter1_level4": {
		"name": "Chapter 1 - Level 4",
		"bg": "res://Assets/maps/map2.png",
		"scene": "res://Scenes/maps/map2.tscn",
		"baseHp": 30,
		"startingGold": 250,
		"chapter": 1,
		"level": 4,
		"spawner_settings": {
			"difficulty": {"initial": 2.0, "increase": 1.25, "multiplies": true},
			"max_waves": 30,
			"wave_spawn_count": 15,
			"special_waves": {
				8: {"enemy_type": "stealthDino", "count": 10},
				16: {"enemy_type": "yellowDino", "count": 12},
				24: {"enemy_type": "greenDino", "count": 8},
				30: {"enemy_type": "healerDino", "count": 5}
			},
		},
	},
	"chapter1_level5": {
		"name": "Chapter 1 - Level 5 (Boss)",
		"bg": "res://Assets/maps/map1.webp",
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 50,
		"startingGold": 300,
		"chapter": 1,
		"level": 5,
		"spawner_settings": {
			"difficulty": {"initial": 2.5, "increase": 1.3, "multiplies": true},
			"max_waves": 50,
			"wave_spawn_count": 20,
			"special_waves": {
				10: {"enemy_type": "redDino", "count": 30},
				20: {"enemy_type": "blueDino", "count": 25},
				30: {"enemy_type": "stealthDino", "count": 15},
				40: {"enemy_type": "greenDino", "count": 12},
				45: {"enemy_type": "healerDino", "count": 8},
				50: {"enemy_type": "healerDino", "count": 10}  # Final boss wave
			},
		},
	}
}

# Charge System Configuration
const charge_system := {
	"max_charge": 100,
	"charge_per_attack": {
		"arrow_tower": 8,
		"capture_tower": 12,
		"mage_tower": 15
	},
	"charge_abilities": {
		"arrow_tower": {
			"name": "剑雨",
			"description": "小范围AOE，在目标区域施放15支箭",
			"range": 120.0,
			"arrow_count": 15,
			"damage_multiplier": 0.8
		},
		"capture_tower": {
			"name": "刺网", 
			"description": "捕获网范围增加100%，被捕单位防御力降低15%",
			"range_multiplier": 2.0,
			"armor_reduction": 0.15,
			"duration": 3.0
		},
		"mage_tower": {
			"name": "激活",
			"description": "攻击速度增加30%，持续3S",
			"speed_bonus": 0.30,
			"duration": 3.0
		}
	}
}

# Summon Stone Configuration
const summon_stones := {
	"shiva": {
		"name": "湿婆",
		"description": "所有塔攻击力+150%，持续15S",
		"cooldown": 180.0,
		"duration": 15.0,
		"effect_type": "global_damage_boost",
		"damage_multiplier": 2.5,
		"icon": "res://Assets/summon_stones/shiva.png"
	},
	"lucifer": {
		"name": "路西法",
		"description": "圆形范围内共造成2000点光属性伤害",
		"cooldown": 120.0,
		"effect_type": "targeted_damage",
		"damage": 2000,
		"element": "light",
		"range": 150.0,
		"icon": "res://Assets/summon_stones/lucifer.png"
	},
	"europa": {
		"name": "欧罗巴",
		"description": "圆形范围内共造成1200点冰属性伤害，并冻结所有单位2s",
		"cooldown": 180.0,
		"effect_type": "freeze_damage",
		"damage": 1200,
		"element": "ice",
		"range": 180.0,
		"freeze_duration": 2.0,
		"icon": "res://Assets/summon_stones/europa.png"
	},
	"titan": {
		"name": "泰坦",
		"description": "对所有塔充能30，伤害增加30%，持续5S",
		"cooldown": 120.0,
		"effect_type": "charge_and_damage",
		"charge_bonus": 30,
		"damage_bonus": 0.30,
		"duration": 5.0,
		"icon": "res://Assets/summon_stones/titan.png"
	},
	"zeus": {
		"name": "宙斯",
		"description": "驱散范围内敌方的BUFF，造成1500点光属性伤害",
		"cooldown": 180.0,
		"effect_type": "dispel_damage",
		"damage": 1500,
		"element": "light",
		"range": 200.0,
		"icon": "res://Assets/summon_stones/zeus.png"
	}
}

# Tower Tech Tree Configuration - Individual tower progression
const tower_tech_tree := {
	"arrow_tower": {
		"name": "箭塔科技",
		"1": {
			"name": "基础箭塔",
			"description": "标准弓箭手塔",
			"cost": 0,
			"unlocked": true,
			"gem_slot_level": 1
		},
		"2a": {
			"name": "精准射手",
			"description": "提高命中率和射程",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"attack_range": 0.3, "da_bonus": 0.1}
		},
		"2b": {
			"name": "连射弓手",
			"description": "提高攻击速度和多重攻击",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"attack_speed": 0.4, "ta_bonus": 0.05}
		},
		"3a": {
			"name": "神射手",
			"description": "极致精准，必定暴击",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"attack_range": 0.5, "da_bonus": 0.2, "damage": 0.3}
		},
		"3b": {
			"name": "穿透射手",
			"description": "箭矢可穿透多个敌人",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"pierce": 2, "damage": 0.2}
		},
		"3c": {
			"name": "暴雨射手",
			"description": "极快攻速，连射不断",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"attack_speed": 0.8, "ta_bonus": 0.1}
		},
		"3d": {
			"name": "多重射手",
			"description": "每次攻击发射多支箭",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"multi_shot": 3, "damage": 0.15}
		}
	},
	"capture_tower": {
		"name": "捕获塔科技",
		"1": {
			"name": "基础捕获塔",
			"description": "标准减速塔",
			"cost": 0,
			"unlocked": true,
			"gem_slot_level": 1
		},
		"2a": {
			"name": "冰霜陷阱",
			"description": "冰冻效果，范围伤害",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"aoe_range": 50.0, "slow_strength": 0.3}
		},
		"2b": {
			"name": "蛛网陷阱",
			"description": "强力减速，持续时间长",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"slow_duration": 0.8, "damage": 0.2}
		},
		"3a": {
			"name": "急冻领域",
			"description": "大范围冰冻，冰系伤害",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"aoe_range": 80.0, "freeze_chance": 0.3, "element": "ice"}
		},
		"3b": {
			"name": "寒冰风暴",
			"description": "冰暴攻击，群体减速",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"aoe_damage": 30.0, "attack_speed": 0.3}
		},
		"3c": {
			"name": "剧毒蛛网",
			"description": "毒性减速，持续伤害",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"dot_damage": 20.0, "slow_strength": 0.5}
		},
		"3d": {
			"name": "束缚之网",
			"description": "强力定身，防御削弱",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"immobilize": true, "armor_reduction": 0.4}
		}
	},
	"mage_tower": {
		"name": "法师塔科技",
		"1": {
			"name": "基础法师塔",
			"description": "标准魔法塔",
			"cost": 0,
			"unlocked": true,
			"gem_slot_level": 1
		},
		"2a": {
			"name": "元素法师",
			"description": "精通元素魔法",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"elemental_damage": 0.4, "aoe_range": 20.0}
		},
		"2b": {
			"name": "奥术法师",
			"description": "纯粹魔法力量",
			"cost": 3,
			"unlocked": false,
			"parent": "1",
			"gem_slot_level": 2,
			"bonuses": {"damage": 0.5, "mana_efficiency": 0.3}
		},
		"3a": {
			"name": "风暴法师",
			"description": "雷电风暴，链式伤害",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"chain_lightning": 3, "element": "wind"}
		},
		"3b": {
			"name": "烈焰法师",
			"description": "火焰爆炸，灼烧效果",
			"cost": 5,
			"unlocked": false,
			"parent": "2a",
			"gem_slot_level": 3,
			"bonuses": {"explosion_damage": 80.0, "element": "fire", "burn_dot": 15.0}
		},
		"3c": {
			"name": "秘法大师",
			"description": "纯能量伤害，无视防御",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"damage": 0.8, "ignore_armor": true}
		},
		"3d": {
			"name": "时空法师",
			"description": "时间操控，减速敌人",
			"cost": 5,
			"unlocked": false,
			"parent": "2b",
			"gem_slot_level": 3,
			"bonuses": {"time_slow": 0.4, "damage": 0.4, "area_effect": true}
		}
	}
}

# Tech Tree Configuration with Tech Points
const tech_tree := {
	"damage_boost": {
		"name": "伤害强化",
		"description": "所有炮塔伤害+10%",
		"cost": 1,
		"max_level": 5,
		"unlocked": false,
		"requirements": []
	},
	"attack_speed_boost": {
		"name": "攻速强化",
		"description": "所有炮塔攻速+8%",
		"cost": 1,
		"max_level": 5,
		"unlocked": false,
		"requirements": []
	},
	"range_boost": {
		"name": "射程强化",
		"description": "所有炮塔射程+15%",
		"cost": 1,
		"max_level": 3,
		"unlocked": false,
		"requirements": []
	},
	"da_chance_boost": {
		"name": "连击强化",
		"description": "DA几率+5%",
		"cost": 2,
		"max_level": 3,
		"unlocked": false,
		"requirements": ["damage_boost"]
	},
	"ta_chance_boost": {
		"name": "三连击强化", 
		"description": "TA几率+3%",
		"cost": 3,
		"max_level": 2,
		"unlocked": false,
		"requirements": ["da_chance_boost"]
	},
	"charge_speed_boost": {
		"name": "充能加速",
		"description": "充能获取速度+50%",
		"cost": 2,
		"max_level": 3,
		"unlocked": false,
		"requirements": ["attack_speed_boost"]
	},
	"economic_boost": {
		"name": "经济强化",
		"description": "击杀敌人金币+20%",
		"cost": 1,
		"max_level": 4,
		"unlocked": false,
		"requirements": []
	},
	"wave_preparation": {
		"name": "战术准备",
		"description": "波次间隔时间+10秒",
		"cost": 1,
		"max_level": 3,
		"unlocked": false,
		"requirements": []
	},
	"projectile_speed_boost": {
		"name": "弹道加速",
		"description": "投射物速度+25%",
		"cost": 2,
		"max_level": 4,
		"unlocked": false,
		"requirements": ["attack_speed_boost"]
	}
}

# Tower Mechanics Configuration
const tower_mechanics := {
	"ricochet_shots": {
		"description": "子弹在敌人间弹射",
		"max_bounces": 5,
		"bounce_range": 80.0,
		"damage_falloff": 0.9
	},
	"periodic_aoe": {
		"description": "周期性区域伤害",
		"pulse_interval": 3.0,
		"range_multiplier": 1.0
	},
	"persistent_slow": {
		"description": "持续范围减速",
		"slow_strength": 0.3,
		"tick_interval": 0.5
	},
	"dot_damage": {
		"description": "持续伤害效果",
		"dot_duration": 15.0,
		"tick_interval": 1.0,
		"damage_per_tick": 25.0
	},
	"armor_reduction": {
		"description": "降低护甲效果",
		"reduction_amount": 0.05,
		"max_stacks": 10,
		"duration": 5.0
	},
	
	# 光元素效果
	"blind_chance_15_1.5s": {
		"type": "chance_effect",
		"effect": "blind",
		"chance": 0.15,
		"duration": 1.5,
		"miss_chance": 0.50
	},
	"purify_1_buff": {
		"type": "purify",
		"remove_buffs": 1,
		"energy_return": 5
	},
	"judgment_1_target": {
		"type": "judgment",
		"damage_multiplier": 1.20,
		"duration": 5.0
	},
	"reveal_stealth": {
		"type": "reveal",
		"reveal_range": 120.0,
		"duration": 3.0
	},
	"blind_stealth_2s": {
		"type": "blind",
		"duration": 2.0,
		"miss_chance": 0.50,
		"target_stealth": true
	},
	"blind_area_1.5s": {
		"type": "area_effect",
		"effect": "blind",
		"radius": 85.0,
		"duration": 1.5,
		"miss_chance": 0.50
	},
	"blind_chance_bounce_20": {
		"type": "chance_effect",
		"effect": "blind",
		"chance": 0.20,
		"duration": 1.5,
		"miss_chance": 0.50,
		"trigger": "bounce"
	},
	"heal_ally_towers_5s": {
		"type": "heal",
		"target": "allies",
		"heal_amount": 25.0,
		"radius": 150.0,
		"interval": 5.0
	},
	"blind_target": {
		"type": "blind",
		"duration": 1.5,
		"miss_chance": 0.50
	},
	"blind_chance_30_2s": {
		"type": "chance_effect",
		"effect": "blind",
		"chance": 0.30,
		"duration": 2.0,
		"miss_chance": 0.50
	},
	"judgment_target": {
		"type": "judgment",
		"damage_multiplier": 1.20,
		"duration": 5.0
	},
	"purify_all_buffs": {
		"type": "purify",
		"remove_buffs": -1,  # -1 means all buffs
		"heal_amount": 15.0
	},
	"heal_friendly_towers": {
		"type": "heal",
		"target": "towers",
		"heal_amount": 30.0,
		"radius": 100.0
	},
	"judgment_area": {
		"type": "area_effect",
		"effect": "judgment",
		"radius": 60.0,
		"damage_multiplier": 1.20,
		"duration": 5.0
	},
	"reveal_all_enemies": {
		"type": "reveal",
		"reveal_range": 200.0,
		"duration": 4.0,
		"reveal_all": true
	},
	"blind_all_stealth": {
		"type": "blind",
		"duration": 2.0,
		"miss_chance": 0.50,
		"target_stealth": true,
		"area": true,
		"radius": 120.0
	},
	"judgment_spread": {
		"type": "judgment",
		"damage_multiplier": 1.20,
		"duration": 5.0,
		"spread_on_death": true,
		"spread_radius": 50.0,
		"spread_damage": 30.0
	},
	"heal_towers_blind_enemies": {
		"type": "combo_effect",
		"effects": ["heal_towers", "blind_enemies"],
		"heal_amount": 25.0,
		"heal_radius": 100.0,
		"blind_radius": 85.0,
		"blind_duration": 1.5
	},
	"purify_bounce": {
		"type": "purify",
		"remove_buffs": 1,
		"trigger": "bounce"
	},
	"blind_bounce": {
		"type": "blind",
		"duration": 1.5,
		"miss_chance": 0.50,
		"trigger": "bounce"
	},
	"purify_attack": {
		"type": "purify",
		"remove_buffs": 1,
		"trigger": "attack",
		"energy_return": 3
	},
	"energy_bonus_10": {
		"type": "energy_bonus",
		"bonus_amount": 10,
		"trigger": "purify"
	},
	"defense_reduction_10": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "subtract",
		"value": 10,
		"duration": 4.0
	},
	"blind_chance_50_3s": {
		"type": "chance_effect",
		"effect": "blind",
		"chance": 0.50,
		"duration": 3.0,
		"miss_chance": 0.50
	},
	"purify_heal_energy_return": {
		"type": "purify",
		"remove_buffs": 2,
		"heal_amount": 20.0,
		"energy_return": 8
	},
	"judgment_extra_damage": {
		"type": "judgment",
		"damage_multiplier": 1.40,
		"duration": 5.0,
		"holy_damage": true
	},
	"prioritize_judgment": {
		"type": "targeting",
		"priority": "judged",
		"priority_multiplier": 2.0
	},
	"anti_stealth_blind": {
		"type": "anti_stealth",
		"reveal_range": 150.0,
		"blind_duration": 2.0,
		"blind_chance": 0.75
	},
	"judgment_spread_holy": {
		"type": "judgment",
		"damage_multiplier": 1.30,
		"duration": 5.0,
		"spread_on_death": true,
		"spread_radius": 75.0,
		"spread_damage": 40.0,
		"holy_damage": true
	},
	"mass_heal_judgment": {
		"type": "combo_effect",
		"effects": ["mass_heal", "area_judgment"],
		"heal_amount": 40.0,
		"heal_radius": 120.0,
		"judgment_radius": 100.0,
		"judgment_multiplier": 1.25
	},
	"bounce_judgment_spread": {
		"type": "bounce_effect",
		"effect": "judgment",
		"damage_multiplier": 1.20,
		"spread_on_hit": true,
		"spread_radius": 40.0
	},
	"continuous_heal_purify_energy": {
		"type": "aura_effect",
		"interval": 3.0,
		"effects": ["heal", "purify", "energy_return"],
		"heal_amount": 15.0,
		"heal_radius": 100.0,
		"energy_return": 5
	},
	"defense_reduction_15": {
		"type": "stat_modifier",
		"stat": "defense",
		"operation": "subtract",
		"value": 15,
		"duration": 5.0
	},
	"judgment_holy_damage": {
		"type": "judgment",
		"damage_multiplier": 1.25,
		"duration": 5.0,
		"holy_damage": true
	},
	
	# 暗元素效果 - 腐蚀
	"corrosion_1": {
		"type": "debuff",
		"debuff_type": "corrosion",
		"stacks": 1,
		"damage_per_second": 4.0,
		"defense_reduction": 0.01,
		"duration": 4.0
	},
	"corrosion_2": {
		"type": "debuff",
		"debuff_type": "corrosion",
		"stacks": 2,
		"damage_per_second": 4.0,
		"defense_reduction": 0.01,
		"duration": 4.0
	},
	"corrosion_3": {
		"type": "debuff",
		"debuff_type": "corrosion",
		"stacks": 3,
		"damage_per_second": 4.0,
		"defense_reduction": 0.01,
		"duration": 4.0
	},
	
	# 暗元素效果 - 生命偷取
	"life_steal_30": {
		"type": "special",
		"effect_type": "life_steal",
		"percentage": 0.30
	},
	"life_steal_50": {
		"type": "special",
		"effect_type": "life_steal",
		"percentage": 0.50
	},
	"life_steal_100": {
		"type": "special",
		"effect_type": "life_steal",
		"percentage": 1.0
	},
	
	# 暗元素效果 - 治疗效果降低
	"healing_reduction_50": {
		"type": "debuff",
		"debuff_type": "healing_reduction",
		"reduction_percent": 0.50,
		"duration": 4.0
	},
	"healing_reduction_25": {
		"type": "debuff",
		"debuff_type": "healing_reduction",
		"reduction_percent": 0.25,
		"duration": 4.0
	},
	"healing_reduction_30": {
		"type": "debuff",
		"debuff_type": "healing_reduction",
		"reduction_percent": 0.30,
		"duration": 4.0
	},
	
	# 暗元素效果 - 死亡传染
	"death_contagion": {
		"type": "special",
		"effect_type": "death_contagion",
		"contagion_radius": 80.0,
		"contagion_stacks": 1
	},
	
	# 暗元素效果 - 恐惧
	"fear_chance_50_2s": {
		"type": "special",
		"effect_type": "chance_fear",
		"chance": 0.50,
		"duration": 2.0,
		"miss_chance": 0.50
	},
	"fear_chance_20_1.5s": {
		"type": "special",
		"effect_type": "chance_fear",
		"chance": 0.20,
		"duration": 1.5,
		"miss_chance": 0.50
	},
	"fear_chance_15": {
		"type": "special",
		"effect_type": "chance_fear",
		"chance": 0.15,
		"duration": 2.0,
		"miss_chance": 0.50
	},
	
	# 暗元素效果 - 生命虹吸
	"life_drain_10": {
		"type": "debuff",
		"debuff_type": "life_drain",
		"drain_percent": 0.10,
		"duration": 3.0
	},
	"life_drain_15": {
		"type": "debuff",
		"debuff_type": "life_drain",
		"drain_percent": 0.15,
		"duration": 3.0
	},
	"life_drain_20": {
		"type": "debuff",
		"debuff_type": "life_drain",
		"drain_percent": 0.20,
		"duration": 3.0
	},
	"life_drain_25": {
		"type": "debuff",
		"debuff_type": "life_drain",
		"drain_percent": 0.25,
		"duration": 3.0
	},
	"life_drain_30": {
		"type": "debuff",
		"debuff_type": "life_drain",
		"drain_percent": 0.30,
		"duration": 3.0
	},
	
	# 暗元素特殊效果
	"channel_life_drain": {
		"type": "special",
		"effect_type": "channel_life_drain",
		"drain_percent": 0.15,
		"channel_duration": 3.0
	},
	"fear_area_detection": {
		"type": "special",
		"effect_type": "fear_area",
		"radius": 120.0,
		"duration": 2.0
	},
	"no_healing": {
		"type": "special",
		"effect_type": "no_healing",
		"duration": 5.0
	},
	"all_towers_life_steal": {
		"type": "special",
		"effect_type": "global_life_steal",
		"percentage": 0.10,
		"duration": 3.0
	},
	"corrosion_aura": {
		"type": "special",
		"effect_type": "corrosion_aura",
		"radius": 95.0,
		"stacks": 1,
		"interval": 2.0
	},
	"life_drain_aura_5": {
		"type": "special",
		"effect_type": "life_drain_aura",
		"radius": 95.0,
		"drain_percent": 0.05
	},
	"life_drain_aura_10": {
		"type": "special",
		"effect_type": "life_drain_aura",
		"radius": 95.0,
		"drain_percent": 0.10
	},
	"permanent_attack_steal": {
		"type": "special",
		"effect_type": "permanent_stat_steal",
		"stat": "damage",
		"steal_amount": 1.0
	},
	"area_life_steal": {
		"type": "special",
		"effect_type": "area_life_steal",
		"radius": 100.0,
		"percentage": 0.15
	},
	"life_cost_10": {
		"type": "special",
		"effect_type": "life_cost",
		"percentage": 0.10
	},
	"life_cost_5": {
		"type": "special",
		"effect_type": "life_cost",
		"percentage": 0.05
	},
	"massive_damage": {
		"type": "special",
		"effect_type": "damage_multiplier",
		"multiplier": 3.0
	},
	"fear_on_hit": {
		"type": "special",
		"effect_type": "fear_on_hit",
		"chance": 0.30,
		"duration": 2.0
	},
	"stealth_life_drain": {
		"type": "special",
		"effect_type": "stealth_life_drain",
		"drain_percent": 0.20,
		"duration": 3.0
	},
	"stat_steal_on_death_10": {
		"type": "special",
		"effect_type": "stat_steal_on_death",
		"attack_steal": 0.10,
		"defense_steal": 0.10
	},
	"damage_multiplier_5": {
		"type": "special",
		"effect_type": "damage_multiplier",
		"multiplier": 5.0
	},
	"prioritize_unfeared": {
		"type": "special",
		"effect_type": "targeting_priority",
		"priority": "unfeared",
		"priority_multiplier": 2.0
	},
	"infinite_duration": {
		"type": "special",
		"effect_type": "infinite_duration"
	}
}

## Hero System Data
## Complete hero definitions, skills, talents, and level modifiers

var heroes := {
	"phantom_spirit": {
		"name": "幻影之灵",
		"element": "fire",
		"base_stats": {
			"max_hp": 540,
			"damage": 58,
			"defense": 10,
			"attack_speed": 0.9,
			"attack_range": 150.0,
			"movement_speed": 0.0  # Heroes are stationary when deployed
		},
		"skills": ["shadow_strike", "flame_armor", "flame_phantom"],
		"sprite": "res://Assets/heroes/phantom_spirit.png",
		"scene": "res://Scenes/heroes/phantom_spirit.tscn",
		"charge_generation": 2.0,  # Charge per second
		"max_charge": 100,
		"description": "火系近战英雄，拥有强大的影拳技能和火焰防护能力"
	}
}

var hero_skills := {
	"shadow_strike": {
		"name": "无影拳",
		"type": "A",
		"charge_cost": 20,
		"cooldown": 5.0,
		"cast_range": 200.0,
		"effect_radius": 150.0,
		"damage_base": 70,
		"damage_scaling": 1.0,  # Multiplied by hero attack
		"invulnerable_duration": 0.3,
		"attack_count": 5,
		"attack_interval": 0.3,
		"description": "对范围内敌人发动连续攻击，期间无敌",
		"icon": "res://Assets/skills/shadow_strike.png"
	},
	"flame_armor": {
		"name": "火焰甲", 
		"type": "B",
		"charge_cost": 35,
		"cooldown": 12.0,
		"duration": 15.0,
		"defense_bonus": 15,
		"shield_amount": 500,
		"aura_radius": 200.0,
		"aura_damage": 30.0,
		"description": "增加防御力和护盾，周围敌人持续受到火焰伤害",
		"icon": "res://Assets/skills/flame_armor.png"
	},
	"flame_phantom": {
		"name": "末炎幻象",
		"type": "C",
		"charge_cost": 60,
		"cooldown": 90.0,
		"duration": 30.0,
		"phantom_damage": 200,
		"phantom_attack_speed": 1.7,
		"phantom_range": 350.0,
		"aura_radius": 250.0,
		"aura_damage": 65.0,
		"burn_stacks": 3,
		"description": "召唤火焰幻象协同作战，大幅增强周围火焰效果",
		"icon": "res://Assets/skills/flame_phantom.png"
	}
}

var hero_talents := {
	"phantom_spirit": {
		"level_5": [
			{
				"id": "enhanced_strikes",
				"name": "强化打击",
				"description": "无影拳攻击次数+2",
				"effects": {
					"shadow_strike_attack_count": 2
				}
			},
			{
				"id": "rapid_charge",
				"name": "快速充能",
				"description": "充能速度+50%",
				"effects": {
					"charge_generation_multiplier": 1.5
				}
			}
		],
		"level_10": [
			{
				"id": "flame_mastery",
				"name": "火焰精通",
				"description": "火焰甲光环伤害+100%",
				"effects": {
					"flame_armor_aura_damage": 2.0
				}
			},
			{
				"id": "defensive_stance",
				"name": "防御姿态",
				"description": "最大生命值+25%，防御力+10",
				"effects": {
					"max_hp_multiplier": 1.25,
					"defense_bonus": 10
				}
			}
		],
		"level_15": [
			{
				"id": "phantom_lord",
				"name": "幻象之主",
				"description": "末炎幻象持续时间+50%，幻象伤害+100%",
				"effects": {
					"flame_phantom_duration": 1.5,
					"flame_phantom_damage": 2.0
				}
			},
			{
				"id": "infernal_aura",
				"name": "地狱光环",
				"description": "所有技能光环范围+50%，附加燃烧效果",
				"effects": {
					"aura_radius_multiplier": 1.5,
					"aura_burn_chance": 0.3
				}
			}
		]
	}
}

var level_modifiers := {
	"positive": [
		{
			"id": "hero_damage_boost",
			"name": "英雄强化",
			"description": "所有英雄伤害+25%",
			"effects": {
				"hero_damage_multiplier": 1.25
			},
			"weight": 10
		},
		{
			"id": "fast_respawn",
			"name": "快速复活",
			"description": "英雄复活时间-50%",
			"effects": {
				"respawn_time_multiplier": 0.5
			},
			"weight": 8
		},
		{
			"id": "enhanced_charge",
			"name": "充能增强",
			"description": "英雄充能速度+100%",
			"effects": {
				"charge_generation_multiplier": 2.0
			},
			"weight": 12
		},
		{
			"id": "skill_cooldown_reduction",
			"name": "技能冷却",
			"description": "技能冷却时间-30%",
			"effects": {
				"skill_cooldown_multiplier": 0.7
			},
			"weight": 15
		},
		{
			"id": "double_experience",
			"name": "经验加倍",
			"description": "英雄获得经验+100%",
			"effects": {
				"experience_multiplier": 2.0
			},
			"weight": 6
		}
	],
	"negative": [
		{
			"id": "reduced_hero_hp",
			"name": "脆弱英雄",
			"description": "所有英雄最大生命值-20%",
			"effects": {
				"hero_hp_multiplier": 0.8
			},
			"weight": 8
		},
		{
			"id": "slow_charge",
			"name": "充能迟缓",
			"description": "英雄充能速度-40%",
			"effects": {
				"charge_generation_multiplier": 0.6
			},
			"weight": 10
		},
		{
			"id": "increased_cooldowns",
			"name": "技能延迟",
			"description": "技能冷却时间+50%",
			"effects": {
				"skill_cooldown_multiplier": 1.5
			},
			"weight": 12
		},
		{
			"id": "expensive_skills",
			"name": "技能耗费",
			"description": "技能充能消耗+30%",
			"effects": {
				"skill_cost_multiplier": 1.3
			},
			"weight": 9
		}
	],
	"neutral": [
		{
			"id": "hero_range_boost",
			"name": "远程专精",
			"description": "英雄攻击距离+50%，攻击力-15%",
			"effects": {
				"attack_range_multiplier": 1.5,
				"damage_multiplier": 0.85
			},
			"weight": 7
		},
		{
			"id": "berserker_mode",
			"name": "狂战士模式",
			"description": "英雄攻击力+40%，防御力-30%",
			"effects": {
				"damage_multiplier": 1.4,
				"defense_multiplier": 0.7
			},
			"weight": 8
		},
		{
			"id": "support_focus",
			"name": "辅助专精",
			"description": "技能光环范围+100%，个人伤害-25%",
			"effects": {
				"aura_radius_multiplier": 2.0,
				"damage_multiplier": 0.75
			},
			"weight": 6
		}
	]
}
