extends Area2D
## Дверь: закрыта, пока не собраны все монеты (ЛР5, ЛР6)

signal reached
signal blocked

var is_open: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var open_texture: Texture2D = preload("res://assets/sprites/world/door_open.png")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func open() -> void:
	is_open = true
	sprite.texture = open_texture


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_open:
		reached.emit()
	else:
		blocked.emit()
