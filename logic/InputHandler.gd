"""
InputHandler manages user input for aiming and shooting balls.
Handles mouse input, displays trajectory indicators, and signals when to shoot.
"""
extends Node

# Signal to emit the shooting angle
signal shoot_ball(angle, launch_position)

# Reference to the Line2D nodes
@onready var _angle_indicator = get_parent().get_node("AngleIndicator")
@onready var _launcher_indicator = get_parent().get_node("LauncherIndicator")
@onready var _launcher_circle = get_parent().get_node("LauncherIndicator/LauncherCircle")

# Variable to store the launch position
var _launch_position = Vector2.ZERO
var _line_length = 200  # Shorter line - 1/4 screen height
var _ball_in_motion = false
var _mouse_pressed = false

func _ready():
	_launch_position = Vector2(get_viewport().get_visible_rect().size.x / 2, get_viewport().get_visible_rect().size.y)
	_update_launcher_indicator()
	_update_angle_indicator()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_pressed = true
			_update_angle_indicator()
		else:
			if _mouse_pressed:
				# Calculate the direction and angle
				var mouse_position = event.position
				var direction = (mouse_position - _launch_position).normalized()
				var angle = direction.angle()
				emit_signal("shoot_ball", angle, _launch_position)
				_ball_in_motion = true
			_mouse_pressed = false
			_update_angle_indicator()
	
	if event is InputEventMouseMotion and _mouse_pressed:
		# Update the angle indicator line while mouse is pressed
		_update_angle_indicator()

func _update_angle_indicator():
	if _mouse_pressed and !_ball_in_motion:
		var mouse_position = get_viewport().get_mouse_position()
		var direction = (mouse_position - _launch_position).normalized()
		var fixed_length_position = _launch_position + direction * _line_length
		_angle_indicator.points = [_launch_position, fixed_length_position]
		_angle_indicator.visible = true
	else:
		_angle_indicator.visible = false

func update_launch_position(new_position):
	_launch_position = new_position
	_update_launcher_indicator()
	_update_angle_indicator()

func reset_launch_position(new_position):
	_launch_position = new_position
	_ball_in_motion = false
	_update_launcher_indicator()
	_update_angle_indicator()

func _update_launcher_indicator():
	# Create a small circle at the launch position
	var circle_points = []
	var radius = 15
	var segments = 16
	for i in segments + 1:
		var angle = i * 2 * PI / segments
		var point = _launch_position + Vector2(cos(angle), sin(angle)) * radius
		circle_points.append(point)
	_launcher_circle.points = circle_points
