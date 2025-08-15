extends "res://Scenes/turrets/projectileTurret/bullet/bulletBase.gd"

# Homing/Seeking Bullet Properties
var homing_enabled: bool = true
var homing_strength: float = 5.0  # How sharply the bullet turns (higher = sharper turns)
var max_turn_rate: float = 10.0   # Maximum turn rate in radians per second
var tracking_range: float = 400.0  # Maximum range to track targets
var current_target_node: Node2D = null  # The actual target node for tracking

# Performance optimization
var last_target_update: float = 0.0
var target_update_interval: float = 0.1  # Update target every 0.1 seconds

func _ready():
	super._ready()
	
	# Override the timer for longer lifetime for homing bullets
	var timer = get_node_or_null("DisappearTimer")
	if timer:
		timer.wait_time = 3.0  # Homing bullets live longer
	
	# Store the initial target node reference
	# Target can be either a Node2D (for homing) or a Vector2 (for regular bullets)
	if target is Node2D and is_instance_valid(target):
		current_target_node = target
	elif source_tower and source_tower.has("current_target"):
		# Fallback: get target from source tower's current_target variable
		var tower_target = source_tower.current_target
		if tower_target and is_instance_valid(tower_target):
			current_target_node = tower_target

func _process(delta):
	if not homing_enabled:
		# Fall back to regular bullet behavior
		super._process(delta)
		return
	
	# Update target tracking periodically
	last_target_update += delta
	if last_target_update >= target_update_interval:
		last_target_update = 0.0
		update_tracking_target()
	
	# Homing movement logic
	if current_target_node and is_instance_valid(current_target_node):
		homing_movement(delta)
	else:
		# No valid target, move in last direction
		regular_movement(delta)
	
	# Update trail
	update_trail()

func homing_movement(delta: float):
	if not current_target_node or not is_instance_valid(current_target_node):
		return
	
	var target_pos = current_target_node.global_position
	var current_pos = global_position
	var distance_to_target = current_pos.distance_to(target_pos)
	
	# Check if target is out of tracking range
	if distance_to_target > tracking_range:
		current_target_node = null
		return
	
	# Calculate desired direction
	var desired_direction = (target_pos - current_pos).normalized()
	
	# Calculate current movement direction
	if direction.length() == 0:
		direction = desired_direction
	else:
		direction = direction.normalized()
	
	# Calculate angle between current direction and desired direction
	var current_angle = atan2(direction.y, direction.x)
	var target_angle = atan2(desired_direction.y, desired_direction.x)
	
	# Calculate angle difference (normalized to -PI to PI)
	var angle_diff = target_angle - current_angle
	while angle_diff > PI:
		angle_diff -= 2 * PI
	while angle_diff < -PI:
		angle_diff += 2 * PI
	
	# Apply homing turn rate
	var max_turn_this_frame = max_turn_rate * delta
	var actual_turn = clamp(angle_diff, -max_turn_this_frame, max_turn_this_frame)
	
	# Calculate new direction with homing strength applied
	var new_angle = current_angle + actual_turn * homing_strength
	direction = Vector2(cos(new_angle), sin(new_angle))
	
	# Move in the new direction
	position += direction * speed * delta

func regular_movement(delta: float):
	# Standard bullet movement when no target
	if direction.length() == 0:
		return
	
	position += direction * speed * delta

func update_tracking_target():
	# If we have a current target, check if it's still valid
	if current_target_node and is_instance_valid(current_target_node):
		# Check if target is still an enemy and in range
		if not current_target_node.is_in_group("enemy"):
			current_target_node = null
			return
		
		var distance = global_position.distance_to(current_target_node.global_position)
		if distance > tracking_range:
			current_target_node = null
			return
		
		# Target is still valid, keep it
		return
	
	# No current target or target became invalid, find new one
	find_new_target()

func find_new_target():
	# Find all enemies in tracking range
	var enemies_in_range = get_enemies_in_range(tracking_range)
	
	if enemies_in_range.is_empty():
		return
	
	# Find closest enemy
	var closest_enemy = null
	var closest_distance = tracking_range
	
	for enemy in enemies_in_range:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	current_target_node = closest_enemy

func get_enemies_in_range(range: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	
	# Find all enemies in scene
	var tree = get_tree()
	if not tree:
		return enemies
	
	var enemy_nodes = tree.get_nodes_in_group("enemy")
	for enemy in enemy_nodes:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= range:
			enemies.append(enemy)
	
	return enemies

# Override the collision handling to maintain target reference
func _on_area_2d_area_entered(area):
	super._on_area_2d_area_entered(area)
	
	# If we hit the target we were tracking, clear the target
	var obj = area.get_parent()
	if obj == current_target_node:
		current_target_node = null

# Set homing properties (called by the tower when creating the bullet)
func setup_homing_properties(enabled: bool = true, strength: float = 5.0, turn_rate: float = 10.0, range: float = 400.0):
	homing_enabled = enabled
	homing_strength = strength
	max_turn_rate = turn_rate
	tracking_range = range

# Get current tracking status (for debugging or UI)
func get_tracking_status() -> Dictionary:
	return {
		"homing_enabled": homing_enabled,
		"has_target": current_target_node != null and is_instance_valid(current_target_node),
		"target_name": current_target_node.name if current_target_node else "none",
		"tracking_range": tracking_range,
		"homing_strength": homing_strength
	}
