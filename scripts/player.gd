extends CharacterBody2D

signal damaged

@export var speed: float = 220.0
@export var acceleration: float = 2400.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -830.0
@export var coyote_time: float = 0.1 
@export var jump_buffer_time: float = 0.1

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote: float = 0.0
var jump_buffer: float = 0.0
var invulnerable: float = 0.0
var shake_time: float = 0.0
var can_control: bool = true
var spawn_position: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var jump_sound: AudioStreamPlayer = $JumpSound


func _ready() -> void:
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var dir := 0.0
	if can_control:
		dir = Input.get_axis("move_left", "move_right")

		if is_on_floor():
			coyote = coyote_time
		else:
			coyote -= delta
		if Input.is_action_just_pressed("jump"):
			jump_buffer = jump_buffer_time
		else:
			jump_buffer -= delta

		if jump_buffer > 0.0 and coyote > 0.0:
			velocity.y = jump_velocity
			jump_buffer = 0.0
			coyote = 0.0
			jump_sound.play()

		# Короткое нажатие — низкий прыжок
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= 0.5

	# Горизонтальное движение с разгоном и торможением
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * speed, acceleration * delta)
		sprite.flip_h = dir < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_animation(dir)
	_update_effects(delta)


func _update_animation(dir: float) -> void:
	if not is_on_floor():
		sprite.play("jump")
	elif absf(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")


func _update_effects(delta: float) -> void:
	# Мигание при неуязвимости
	if invulnerable > 0.0:
		invulnerable -= delta
		sprite.visible = int(invulnerable * 20.0) % 2 == 0
	else:
		sprite.visible = true

	# Тряска камеры
	if shake_time > 0.0:
		shake_time -= delta
		camera.offset = Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
	else:
		camera.offset = Vector2.ZERO


## Вызывается шипами. Возвращает true, если урон засчитан.
func hurt() -> bool:
	if invulnerable > 0.0 or not can_control:
		return false
	invulnerable = 1.0
	shake_time = 0.25
	var away := -1.0 if not sprite.flip_h else 1.0
	velocity = Vector2(away * 200.0, -250.0)
	damaged.emit()
	return true


func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	invulnerable = 1.0
