extends RigidBody2D
class_name Ball

signal ball_exited(exit_position)

# Initial velocity of the ball
@export var initial_velocity: Vector2 = Vector2(300, -300)
# Speed multiplier for fine-tuning
@export var speed_multiplier = 1.5
# Ball count speed scaling
var ball_count_multiplier = 1.0

var velocity: Vector2
var damaged_bodies: Array = []  # Track bodies damaged this frame

func _ready():
	# Configure RigidBody2D settings for perfect bouncing
	gravity_scale = 0.0  # No gravity
	linear_damp = 0.0    # No damping
	angular_damp = 0.0   # No angular damping
	
	# Create and configure PhysicsMaterial for perfect bounce
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = 1.0  # Perfect bounce
	physics_material.friction = 0.0  # No friction
	physics_material_override = physics_material
	
	 # Set collision layers - balls only collide with walls, bricks, not other balls
	collision_layer = 1  # Ball layer
	collision_mask = 6   # Walls (layer 2) + Bricks (layer 4), NOT balls (layer 1)
	
	# Set collision detection to continuous for better accuracy
	continuous_cd = CCD_MODE_CAST_RAY
	
	# Enable contact monitoring for collision signals (not _integrate_forces)
	contact_monitor = true
	max_contacts_reported = 10
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	
	# Set initial velocity
	velocity = initial_velocity * speed_multiplier * ball_count_multiplier
	linear_velocity = velocity

func _physics_process(_delta):
	# Clear damaged bodies list for new frame
	damaged_bodies.clear()

	# Ensure velocity magnitude remains constant
	var current_speed = linear_velocity.length()
	var desired_speed = velocity.length()
	
	# If speed has changed due to physics engine, correct it
	if current_speed > 0 and abs(current_speed - desired_speed) > 0.1:
		linear_velocity = linear_velocity.normalized() * desired_speed
		velocity = linear_velocity

func _on_body_entered(body):
	print("Ball hit " + body.name)
	if body.has_method("take_damage_from_ball"):
		if not body in damaged_bodies:
			body.take_damage_from_ball()
			damaged_bodies.append(body)
	
func set_velocity(new_velocity: Vector2):
	"""Set a new velocity for the ball"""
	velocity = new_velocity
	linear_velocity = velocity

func get_speed():
	"""Get the current speed (magnitude of velocity)"""
	return velocity.length()

func set_speed(new_speed: float):
	"""Set the speed while maintaining direction"""
	if linear_velocity.length() > 0:
		velocity = linear_velocity.normalized() * new_speed
		linear_velocity = velocity

func set_ball_count_multiplier(multiplier: float):
	"""Set the ball count speed multiplier"""
	ball_count_multiplier = multiplier

func shoot(angle: float, initial_position: Vector2):
	"""Launch the ball from a given position at a given angle
	
	Args:
		angle: Angle in radians (0 is right, PI/2 is up, PI is left, -PI/2 is down)
		initial_position: Starting position for the ball
	"""
	# Set the ball's position
	global_position = initial_position
	
	# Calculate velocity vector from angle
	var direction = Vector2(cos(angle), sin(angle))
	var speed = initial_velocity.length() * speed_multiplier * ball_count_multiplier
	
	# Set the velocity
	velocity = direction * speed
	linear_velocity = velocity
	
	# Reset any angular velocity
	angular_velocity = 0.0

func shoot_degrees(angle_degrees: float, initial_position: Vector2):
	"""Launch the ball from a given position at a given angle in degrees
	
	Args:
		angle_degrees: Angle in degrees (0 is right, 90 is down, -90 is up, 180 is left)
		initial_position: Starting position for the ball
	"""
	shoot(deg_to_rad(angle_degrees), initial_position)

func _process(delta):
	if position.y > get_viewport().get_visible_rect().size.y:
		emit_signal("ball_exited", Vector2(position.x, get_viewport().get_visible_rect().size.y))
		queue_free()
