extends Node

# Signal to emit the shooting angle
signal shoot_ball(angle, launch_position)

# Reference to the Line2D nodes
@onready var angle_indicator = get_parent().get_node("AngleIndicator")
@onready var launcher_indicator = get_parent().get_node("LauncherIndicator")
@onready var launcher_circle = get_parent().get_node("LauncherIndicator/LauncherCircle")

# Variable to store the launch position
var launch_position = Vector2.ZERO
var line_length = 200  # Shorter line - 1/4 screen height
var ball_in_motion = false
var mouse_pressed = false

func _ready():
	launch_position = Vector2(get_viewport().get_visible_rect().size.x / 2, get_viewport().get_visible_rect().size.y)
	update_launcher_indicator()
	update_angle_indicator()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_pressed = true
			update_angle_indicator()
		else:
			if mouse_pressed:
				# Calculate the direction and angle
				var mouse_position = event.position
				var direction = (mouse_position - launch_position).normalized()
				var angle = direction.angle()
				emit_signal("shoot_ball", angle, launch_position)
				ball_in_motion = true
			mouse_pressed = false
			update_angle_indicator()
	
	if event is InputEventMouseMotion and mouse_pressed:
		# Update the angle indicator line while mouse is pressed
		update_angle_indicator()

func update_angle_indicator():
	if mouse_pressed and !ball_in_motion:
		var mouse_position = get_viewport().get_mouse_position()
		var direction = (mouse_position - launch_position).normalized()
		var fixed_length_position = launch_position + direction * line_length
		angle_indicator.points = [launch_position, fixed_length_position]
		angle_indicator.visible = true
	else:
		angle_indicator.visible = false

func update_launch_position(new_position):
	launch_position = new_position
	update_launcher_indicator()
	update_angle_indicator()

func reset_launch_position(new_position):
	launch_position = new_position
	ball_in_motion = false
	update_launcher_indicator()
	update_angle_indicator()

func update_launcher_indicator():
	# Create a small circle at the launch position
	var circle_points = []
	var radius = 15
	var segments = 16
	for i in segments + 1:
		var angle = i * 2 * PI / segments
		var point = launch_position + Vector2(cos(angle), sin(angle)) * radius
		circle_points.append(point)
	launcher_circle.points = circle_points
