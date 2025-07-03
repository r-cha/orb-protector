extends Node

@onready var ball_scene = preload("res://ball.tscn")
@onready var input_handler = $InputHandler
@onready var brick_manager = $BrickManager
@onready var info_label = $UI/InfoPanel/InfoLabel
@onready var game_over_overlay = $UI/GameOverOverlay
@onready var play_again_button = $UI/GameOverOverlay/VBoxContainer/PlayAgainButton
@onready var end_turn_button = $UI/EndTurnButton

var ball_count = 1
var current_launch_position = Vector2(640, 700)  # 4x scale
var balls_in_play = 0
var shooting = false
var turn_start_time = 0.0

func _ready():
	input_handler.shoot_ball.connect(_on_shoot_ball)
	input_handler.reset_launch_position(current_launch_position)
	
	brick_manager.game_over.connect(_on_game_over)
	brick_manager.special_block_hit.connect(_on_special_block_hit)
	
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	play_again_button.pressed.connect(_on_play_again)
	
	update_ui()

func _process(_delta):
	# Show end turn button after 5 seconds during a turn
	if shooting and not end_turn_button.visible:
		if Time.get_unix_time_from_system() - turn_start_time >= 5.0:
			end_turn_button.visible = true

func _on_shoot_ball(angle, launch_position):
	if shooting:
		return
		
	shooting = true
	balls_in_play = 0
	turn_start_time = Time.get_unix_time_from_system()
	
	# Calculate speed multiplier based on ball count
	# Formula: 1.0 + (ball_count - 1) * 0.1 (2% increase per additional ball)
	var speed_multiplier = 1.0 + (ball_count - 1) * 0.02
	
	# Shoot all balls sequentially
	for i in ball_count:
		var new_ball = ball_scene.instantiate()
		add_child(new_ball)
		new_ball.ball_exited.connect(_on_ball_exited)
		new_ball.set_ball_count_multiplier(speed_multiplier)
		new_ball.shoot(angle, current_launch_position)
		balls_in_play += 1
		await get_tree().create_timer(0.15).timeout

func _on_ball_exited(exit_position):
	balls_in_play -= 1
	
	# When all balls are done, end turn
	if balls_in_play <= 0:
		current_launch_position = Vector2(exit_position.x, 700)
		end_turn()

func end_turn():
	shooting = false
	end_turn_button.visible = false
	input_handler.reset_launch_position(current_launch_position)
	
	# Descend bricks after all balls finish
	await get_tree().create_timer(0.5).timeout
	brick_manager.descend_bricks()
	update_ui()

func _on_special_block_hit(type):
	if type == "add":
		ball_count += 1
	elif type == "multiply":
		ball_count *= 2
	
	update_ui()
	print("Balls: ", ball_count)

func update_ui():
	info_label.text = "Round: %d  Balls: %d" % [brick_manager.current_round, ball_count]

func _on_game_over():
	print("Game Over - Bricks reached bottom!")
	game_over_overlay.visible = true
	get_tree().paused = true

func _on_end_turn_button_pressed():
	# Get the last ball position to update launch position
	var last_ball_position = current_launch_position
	
	# Find any ball still in play to get its position
	for child in get_children():
		if child.name.begins_with("Ball"):
			last_ball_position = child.global_position
			child.queue_free()
	
	# Update launch position and end turn
	current_launch_position = Vector2(last_ball_position.x, 700)
	balls_in_play = 0
	end_turn()

func _on_play_again():
	reset_game()

func reset_game():
	# Reset game state
	ball_count = 1
	current_launch_position = Vector2(640, 700)
	balls_in_play = 0
	shooting = false
	end_turn_button.visible = false
	
	# Clear all balls
	for child in get_children():
		if child.name.begins_with("Ball"):
			child.queue_free()
	
	# Reset brick manager
	brick_manager.clear_all_bricks()
	brick_manager.current_round = 1
	brick_manager.spawn_new_row()
	
	# Reset input handler
	input_handler.reset_launch_position(current_launch_position)
	
	# Hide game over overlay and unpause
	game_over_overlay.visible = false
	get_tree().paused = false
	
	# Update UI
	update_ui()
