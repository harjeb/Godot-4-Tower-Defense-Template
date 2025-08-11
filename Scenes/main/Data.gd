extends Node

const turrets := {
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
			"attack_range": 100.0,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Explosive",
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
	},
}

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
			"speed": 1.0,
			"baseDamage": 5.0,
			"goldYield": 10.0,
			},
		"difficulty": 1.0,
		"sprite": "res://Assets/enemies/dino1.png",
		"element": "neutral",
		"special_abilities": [],
		"drop_table": {
			"base_chance": 0.05,
			"items": ["fire_basic", "ice_basic", "earth_basic"]
		}
	},
	"blueDino": {
		"stats": {
			"hp": 5.0,
			"speed": 2.0,
			"baseDamage": 5.0,
			"goldYield": 10.0,
			},
		"difficulty": 2.0,
		"sprite": "res://Assets/enemies/dino2.png",
		"element": "ice",
		"special_abilities": [],
		"drop_table": {
			"base_chance": 0.06,
			"items": ["ice_basic", "wind_basic"]
		}
	},
	"yellowDino": {
		"stats": {
			"hp": 10.0,
			"speed": 5.0,
			"baseDamage": 1.0,
			"goldYield": 10.0,
			},
		"difficulty": 3.0,
		"sprite": "res://Assets/enemies/dino3.png",
		"element": "wind",
		"special_abilities": ["stealth"],
		"drop_table": {
			"base_chance": 0.08,
			"items": ["wind_basic", "light_basic"]
		}
	},
	"greenDino": {
		"stats": {
			"hp": 10.0,
			"speed": 10.0,
			"baseDamage": 1.0,
			"goldYield": 10.0,
			},
		"difficulty": 4.0,
		"sprite": "res://Assets/enemies/dino4.png",
		"element": "earth",
		"special_abilities": ["split"],
		"drop_table": {
			"base_chance": 0.07,
			"items": ["earth_basic", "dark_basic"]
		}
	},
	"stealthDino": {
		"stats": {
			"hp": 15.0,
			"speed": 1.5,
			"baseDamage": 5.0,
			"goldYield": 15.0,
		},
		"element": "neutral",
		"special_abilities": ["stealth"],
		"drop_table": {
			"base_chance": 0.08,
			"items": ["wind_basic", "light_basic"]
		},
		"difficulty": 2.5,
		"sprite": "res://Assets/enemies/dino2.png"
	},
	"healerDino": {
		"stats": {
			"hp": 20.0,
			"speed": 0.8,
			"baseDamage": 3.0,
			"goldYield": 20.0,
		},
		"element": "light",
		"special_abilities": ["heal"],
		"drop_table": {
			"base_chance": 0.10,
			"items": ["light_basic", "light_intermediate"]
		},
		"difficulty": 3.5,
		"sprite": "res://Assets/enemies/dino1.png"
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
		"name": "初级火宝石",
		"element": "fire",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/fire_basic.png"
	},
	"fire_intermediate": {
		"name": "中级火宝石", 
		"element": "fire",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/fire_intermediate.png"
	},
	"fire_advanced": {
		"name": "高级火宝石",
		"element": "fire", 
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/fire_advanced.png"
	},
	"ice_basic": {
		"name": "初级冰宝石",
		"element": "ice",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/ice_basic.png"
	},
	"ice_intermediate": {
		"name": "中级冰宝石",
		"element": "ice",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/ice_intermediate.png"
	},
	"ice_advanced": {
		"name": "高级冰宝石",
		"element": "ice",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/ice_advanced.png"
	},
	"wind_basic": {
		"name": "初级风宝石",
		"element": "wind",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/wind_basic.png"
	},
	"wind_intermediate": {
		"name": "中级风宝石",
		"element": "wind",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/wind_intermediate.png"
	},
	"wind_advanced": {
		"name": "高级风宝石",
		"element": "wind",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/wind_advanced.png"
	},
	"earth_basic": {
		"name": "初级土宝石",
		"element": "earth",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/earth_basic.png"
	},
	"earth_intermediate": {
		"name": "中级土宝石",
		"element": "earth",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/earth_intermediate.png"
	},
	"earth_advanced": {
		"name": "高级土宝石",
		"element": "earth",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/earth_advanced.png"
	},
	"light_basic": {
		"name": "初级光宝石",
		"element": "light",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/light_basic.png"
	},
	"light_intermediate": {
		"name": "中级光宝石",
		"element": "light",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/light_intermediate.png"
	},
	"light_advanced": {
		"name": "高级光宝石",
		"element": "light",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/light_advanced.png"
	},
	"dark_basic": {
		"name": "初级暗宝石",
		"element": "dark",
		"level": 1,
		"damage_bonus": 0.10,
		"sprite": "res://Assets/gems/dark_basic.png"
	},
	"dark_intermediate": {
		"name": "中级暗宝石",
		"element": "dark",
		"level": 2,
		"damage_bonus": 0.20,
		"sprite": "res://Assets/gems/dark_intermediate.png"
	},
	"dark_advanced": {
		"name": "高级暗宝石",
		"element": "dark",
		"level": 3,
		"damage_bonus": 0.35,
		"sprite": "res://Assets/gems/dark_advanced.png"
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
	}
}
