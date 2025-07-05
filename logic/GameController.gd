"""
GameController manages the main game state and coordinates between different game systems.
Handles ball launching, score tracking, game over conditions, and UI updates.
"""
extends Node

@onready var _ball_scene = preload("res://ball.tscn")
@onready var _input_handler = $InputHandler
@onready var _brick_manager = $BrickManager
@onready var _round_display = $UI/RoundDisplay
@onready var _ball_count_label = $UI/BallCountContainer/BallCountLabel
@onready var _game_over_overlay = $UI/GameOverOverlay
@onready var _play_again_button = $UI/GameOverOverlay/VBoxContainer/PlayAgainButton
@onready var _end_turn_button = $UI/EndTurnButton

var _ball_count = 1
var _current_launch_position = Vector2(640, 700)  # 4x scale
var _balls_in_play = 0
var _active_balls = []  # Array to track all balls in current round
var _shooting = false
var _stop_shooting = false  # Flag to stop shooting early
var _turn_start_time = 0.0
var _double_damage_active = false  # Track if double damage is active this round

func _ready():
	# Add to game controller group for easy access
	add_to_group("game_controller")
	
	_input_handler.shoot_ball.connect(_on_shoot_ball)
	_input_handler.reset_launch_position(_current_launch_position)
	
	_brick_manager.game_over.connect(_on_game_over)
	_brick_manager.special_block_hit.connect(_on_special_block_hit)
	_brick_manager.pickup_spawned.connect(_on_pickup_spawned)
	
	_end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	_play_again_button.pressed.connect(_on_play_again)
	print("Play Again button connected: ", _play_again_button.pressed.is_connected(_on_play_again))
	
	# Allow play again button to work when game is paused
	_play_again_button.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect to pickup collection signals
	_connect_pickup_signals()
	
	_update_ui()

func _process(_delta):
	# Show end turn button after 5 seconds during a turn
	if _shooting and not _end_turn_button.visible:
		if Time.get_unix_time_from_system() - _turn_start_time >= 5.0:
			_end_turn_button.visible = true

func _on_shoot_ball(angle, launch_position):
	if _shooting:
		return
		
	_shooting = true
	_stop_shooting = false  # Reset stop flag
	_balls_in_play = 0
	_active_balls.clear()  # Clear previous round's balls
	_turn_start_time = Time.get_unix_time_from_system()
	
	# Calculate speed multiplier based on ball count
	# Formula: 1.0 + (ball_count - 1) * 0.1 (2% increase per additional ball)
	var speed_multiplier = min(1.0 + (_ball_count - 1) * 0.02, 5)
	
	# Shoot all balls sequentially
	for i in _ball_count:
		if _stop_shooting:  # Check if we should stop shooting
			break
			
		var new_ball = _ball_scene.instantiate()
		add_child(new_ball)
		new_ball.ball_exited.connect(_on_ball_exited)
		new_ball.set_ball_count_multiplier(speed_multiplier)
		new_ball.set_double_damage_active(_double_damage_active)
		new_ball.shoot(angle, _current_launch_position)
		_active_balls.append(new_ball)  # Track ball in array
		_balls_in_play += 1
		await get_tree().create_timer(0.15 / speed_multiplier).timeout

func _on_ball_exited(exit_position):
	_balls_in_play -= 1
	
	# Remove ball from active array when it exits
	var exited_ball = get_tree().get_first_node_in_group("balls") # Get the ball that called this
	if exited_ball and exited_ball in _active_balls:
		_active_balls.erase(exited_ball)
	
	# When all balls are done, end turn
	if _balls_in_play <= 0:
		_current_launch_position = Vector2(exit_position.x, 700)
		_end_turn()

func _end_turn():
	_shooting = false
	_end_turn_button.visible = false
	_stop_shooting = true
	_input_handler.reset_launch_position(_current_launch_position)
	
	# Clear double damage effect at end of turn
	_double_damage_active = false
	_update_all_balls_double_damage_state()
	
	# Clear pickups at the end of each round
	_brick_manager.clear_pickups()
	
	# Descend bricks after all balls finish
	_brick_manager.descend_bricks()
	
	# Reconnect pickup signals for new pickups
	_connect_pickup_signals()
	
	_update_ui()

func _on_special_block_hit(type):
	if type == "add":
		_ball_count += 1
	elif type == "multiply":
		_ball_count *= 2
	
	_update_ui()
	print("Balls: ", _ball_count)

func _update_ui():
	if _round_display:
		_round_display.text = str(_brick_manager.current_round)
	if _ball_count_label:
		_ball_count_label.text = str(_ball_count)

func _on_game_over():
	print("Game Over - Bricks reached bottom!")
	_game_over_overlay.visible = true
	print("Play Again button disabled: ", _play_again_button.disabled)
	print("Play Again button visible: ", _play_again_button.visible)
	get_tree().paused = true

func _on_end_turn_button_pressed():
	# Get the last ball position to update launch position
	var last_ball_position = _current_launch_position
	
	# Destroy all active balls and get last position
	for ball in _active_balls:
		if is_instance_valid(ball):
			last_ball_position = ball.global_position
			# Properly destroy the ball (stops movement, disables collision, deletes)
			ball.destroy()
	
	# Clear the active balls array
	_active_balls.clear()
	
	# Update launch position and end turn
	_current_launch_position = Vector2(last_ball_position.x, 700)
	_balls_in_play = 0
	
	_end_turn()

func _on_play_again():
	print("Play Again button clicked!")
	_reset_game()

func _reset_game():
	# Reset game state
	_ball_count = 1
	_current_launch_position = Vector2(640, 700)
	_balls_in_play = 0
	_active_balls.clear()  # Clear ball tracking array
	_shooting = false
	_end_turn_button.visible = false
	_double_damage_active = false
	_update_all_balls_double_damage_state()
	
	# Clear all balls
	for child in get_children():
		if child.name.begins_with("Ball"):
			child.free()
	
	# Reset brick manager
	_brick_manager.clear_all_bricks()
	_brick_manager.current_round = 0
	_brick_manager.spawn_new_row()
	
	# Reset input handler
	_input_handler.reset_launch_position(_current_launch_position)
	
	# Hide game over overlay and unpause
	_game_over_overlay.visible = false
	get_tree().paused = false
	
	# Update UI
	_update_ui()

func _connect_pickup_signals():
	"""Connect to pickup collection signals from all existing pickups"""
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not pickup.pickup_collected.is_connected(_on_pickup_collected):
			pickup.pickup_collected.connect(_on_pickup_collected)

func _on_pickup_spawned(pickup):
	"""Connect to a newly spawned pickup"""
	pickup.pickup_collected.connect(_on_pickup_collected)

func _on_pickup_collected(pickup_type):
	"""Handle pickup effects"""
	print("Pickup collected: ", pickup_type)
	
	if pickup_type == "minus":
		_ball_count = max(1, _ball_count - 1)  # Ensure at least 1 ball
		print("Ball count reduced to: ", _ball_count)
	elif pickup_type == "double_damage":
		_double_damage_active = true
		_update_all_balls_double_damage_state()
		print("Double damage activated for this round")
	
	_update_ui()

func is_double_damage_active() -> bool:
	"""Check if double damage is currently active"""
	return _double_damage_active

func _update_all_balls_double_damage_state():
	"""Update the visual state of all active balls based on double damage status"""
	for ball in _active_balls:
		if ball and is_instance_valid(ball):
			ball.set_double_damage_active(_double_damage_active)
