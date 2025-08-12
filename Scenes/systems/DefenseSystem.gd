class_name DefenseSystem

## Defense System for Tower Defense Enhancement
## Handles damage reduction calculations based on enemy defense values
## Formula: final_damage = original_damage / (1 + defense/100)

## Calculate damage after applying defense reduction
## @param original_damage: The base damage before defense
## @param defense_value: The enemy's defense stat (0-200+)
## @return: The reduced damage value
static func calculate_damage_after_defense(original_damage: float, defense_value: float) -> float:
	if defense_value <= 0:
		return original_damage
	
	# Defense formula: damage = original / (1 + defense/100)
	var defense_multiplier = get_defense_multiplier(defense_value)
	return original_damage * defense_multiplier

## Get the defense multiplier for damage calculations
## @param defense_value: The enemy's defense stat
## @return: Multiplier between 0.0 and 1.0
static func get_defense_multiplier(defense_value: float) -> float:
	if defense_value <= 0:
		return 1.0
	
	return 1.0 / (1.0 + defense_value / 100.0)

## Get defense effectiveness percentage (for UI display)
## @param defense_value: The enemy's defense stat
## @return: Damage reduction percentage (0-100)
static func get_defense_percentage(defense_value: float) -> float:
	if defense_value <= 0:
		return 0.0
	
	var multiplier = get_defense_multiplier(defense_value)
	return (1.0 - multiplier) * 100.0

## Validate defense value is within reasonable bounds
## @param defense_value: The defense value to validate
## @return: Clamped defense value
static func validate_defense_value(defense_value: float) -> float:
	return clamp(defense_value, 0.0, 200.0)  # Cap at 200 for better game balance