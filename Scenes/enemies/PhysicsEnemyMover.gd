extends CharacterBody2D
class_name PhysicsEnemyMover

# 这个类为地面单位提供物理碰撞支持
# 继承自CharacterBody2D来支持物理交互

signal enemy_reached_end
signal enemy_destroyed

# 引用主要的敌人移动器
var main_enemy_mover: Node
var is_physics_active: bool = false
var target_position: Vector2
var movement_speed: float = 1.0

# Physics movement variables
var push_force: float = 50.0
var max_physics_time: float = 3.0  # 最大物理模式时间，防止卡住
var physics_timer: float = 0.0

func _ready() -> void:
	# 设置碰撞层
	collision_layer = 2   # 敌人层
	collision_mask = 8    # 检测阻挡塔层
	
	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision_shape.shape = shape
	add_child(collision_shape)

func setup(enemy_mover: Node) -> void:
	main_enemy_mover = enemy_mover
	if main_enemy_mover:
		global_position = main_enemy_mover.global_position
		movement_speed = main_enemy_mover.speed * 50  # 转换速度单位

func _physics_process(delta: float) -> void:
	if not is_physics_active or not main_enemy_mover:
		return
	
	physics_timer += delta
	
	# 如果物理模式时间太长，强制返回路径模式
	if physics_timer > max_physics_time:
		deactivate_physics_mode()
		return
	
	# 计算朝向目标的方向
	var direction = (target_position - global_position).normalized()
	
	# 应用移动
	velocity = direction * movement_speed
	
	# 处理物理碰撞
	var collision = move_and_slide()
	
	# 如果发生碰撞，尝试绕行
	if collision:
		handle_collision()
	
	# 检查是否足够接近目标可以返回路径模式
	if global_position.distance_to(target_position) < 15:
		deactivate_physics_mode()

func handle_collision() -> void:
	# 获取碰撞信息
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# 如果碰撞到阻挡塔，攻击它
		if collider and collider.get_parent().is_in_group("tower"):
			var tower = collider.get_parent()
			if tower.has_method("take_damage") and tower.can_block_path and tower.is_alive:
				# 攻击阻挡塔
				if main_enemy_mover.has_method("get"):
					tower.take_damage(main_enemy_mover.baseDamage)
				
				# 尝试推开或绕行
				var push_direction = (global_position - tower.global_position).normalized()
				velocity += push_direction * push_force

func activate_physics_mode(target_pos: Vector2) -> void:
	if not main_enemy_mover:
		return
	
	is_physics_active = true
	target_position = target_pos
	physics_timer = 0.0
	global_position = main_enemy_mover.global_position
	
	# 隐藏主敌人，显示物理体
	main_enemy_mover.visible = false
	visible = true

func deactivate_physics_mode() -> void:
	is_physics_active = false
	physics_timer = 0.0
	
	# 恢复主敌人位置
	if main_enemy_mover:
		main_enemy_mover.global_position = global_position
		main_enemy_mover.visible = true
	
	# 隐藏物理体
	visible = false

func get_main_enemy() -> Node:
	return main_enemy_mover
