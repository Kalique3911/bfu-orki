extends Area2D
## Шипы: препятствие, наносящее урон игроку (ЛР5)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt()
