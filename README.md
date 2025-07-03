# Pong with GDScript

A simpleton's Breakout.
It's the game from the ads.

[signals](https://docs.godotengine.org/en/latest/getting_started/step_by_step/signals.html).

Language: GDScript

Renderer: Compatibility

## How does it work?

The walls, bricks, and balls are all
[`Area2D`](https://docs.godotengine.org/en/latest/classes/class_area2d.html)
nodes. When the ball touches the walls or the bricks,
they emit signals and modify the ball.
