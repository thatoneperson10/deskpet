extends Node2D

var speed = 300
var direction = Vector2(1,0)
var screen_size = Vector2()
var window_size = Vector2(200, 200)
var idle_timer = 0.0
var is_idling = false
var is_dragging = false
var drag_offset = Vector2()
var gravity = 1800.0
var fall_velocity = 0.0
var bounce_strength = 0.2
var stop_bounce_speed = 60.0
var fling_velocity = Vector2()
var fling_damping = 1200.0

@onready var animated_sprite =$AnimatedSprite2D
@onready var area = $Area2D

func _ready():
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("Run")
	area.input_event.connect(_on_area_input)

func _physics_process(delta: float) -> void:
		if is_dragging:
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var new_win_pos = mouse_pos - drag_offset
			var current_win_pos = Vector2(DisplayServer.window_get_position())
			fling_velocity = (new_win_pos - current_win_pos) / maxf(delta, 0.001)
			fall_velocity = 0.0
			DisplayServer.window_set_position(Vector2i(new_win_pos))
			return
		
		if is_idling:
			idle_timer -= delta
			if idle_timer <= 0:
				is_idling = false
				speed = 300
				animated_sprite.play("Run")

		var window_position = Vector2(DisplayServer.window_get_position())
		var horizontal_velocity = fling_velocity.x
		if not is_idling:
			horizontal_velocity += direction.x * speed
		if abs(horizontal_velocity) > 1.0:
			direction.x = sign(horizontal_velocity)
			animated_sprite.flip_h = direction.x < 0
		window_position.x += horizontal_velocity * delta
		fling_velocity.x = move_toward(fling_velocity.x, 0.0, fling_damping * delta)

		fall_velocity += gravity * delta
		window_position.y += fall_velocity * delta

		var floor_y = screen_size.y - window_size.y
		if window_position.y >= floor_y:
			window_position.y = floor_y
			fall_velocity = -abs(fall_velocity) * bounce_strength
			if abs(fall_velocity) < stop_bounce_speed:
				fall_velocity = 0.0
		elif window_position.y <= 0:
			window_position.y = 0
			fall_velocity = abs(fall_velocity) * bounce_strength

		window_position.x = clamp(window_position.x, 0, screen_size.x - window_size.x)
		DisplayServer.window_set_position(Vector2i(window_position))
		
		if not is_idling and (window_position.x <= 0 or window_position.x >= screen_size.x - window_size.x):
			fling_velocity.x *= -bounce_strength
			direction.x = 1.0 if window_position.x <= 0 else -1.0
			animated_sprite.flip_h = direction.x < 0
			maybe_idle()

func maybe_idle():
	if randf() < 0.25:
		is_idling = true
		idle_timer = randf_range(1.0, 3.0)
		animated_sprite.play("Idle")
		speed = 0

func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			fling_velocity = Vector2()
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
		else:
			is_dragging = false
			fall_velocity = fling_velocity.y
			fling_velocity.y = 0.0
