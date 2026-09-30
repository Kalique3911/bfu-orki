extends Area2D
## Монета: триггер подбора (ЛР5) + звук и частицы (ЛР7)

signal collected

var taken: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sound: AudioStreamPlayer = $PickupSound
@onready var particles: CPUParticles2D = $Particles


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.play("spin")


func _on_body_entered(body: Node2D) -> void:
	if taken or not body.is_in_group("player"):
		return
	taken = true
	collected.emit()
	sound.play()
	particles.emitting = true
	sprite.visible = false
	await get_tree().create_timer(0.7).timeout
	queue_free()
