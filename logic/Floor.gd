extends Area2D

func _ready():
	# Connect the body_entered signal instead of area_entered
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Ball":
		emit_signal("update_launch_position", body.global_position)
		body.emit_signal("ball_exited", body.global_position)
		body.queue_free()
