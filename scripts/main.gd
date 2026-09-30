extends Node2D
## Главный скрипт уровня: счёт, здоровье, состояния игры, пауза (ЛР5, ЛР6)

enum State { PLAYING, PAUSED, WON, LOST }

const MAX_HEALTH := 3
const HEART_FULL := preload("res://assets/sprites/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/sprites/ui/heart_empty.png")

var state: State = State.PLAYING
var health: int = MAX_HEALTH
var coins: int = 0
var total_coins: int = 0

@onready var player: CharacterBody2D = $Level/Player
@onready var door: Area2D = $Level/Door
@onready var hearts: Array = $UI/HUD/Hearts.get_children()
@onready var coin_label: Label = $UI/HUD/CoinLabel
@onready var hint_label: Label = $UI/HUD/HintLabel
@onready var pause_panel: Control = $UI/PausePanel
@onready var end_panel: Control = $UI/EndPanel
@onready var end_title: Label = $UI/EndPanel/Box/TitleLabel
@onready var end_info: Label = $UI/EndPanel/Box/InfoLabel
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	get_tree().paused = false
	total_coins = $Level/Coins.get_child_count()
	for coin in $Level/Coins.get_children():
		coin.collected.connect(_on_coin_collected)
	door.reached.connect(_on_door_reached)
	door.blocked.connect(_on_door_blocked)
	player.damaged.connect(_on_player_damaged)
	$Level/FallZone.body_entered.connect(_on_fall_zone_entered)

	$UI/PausePanel/Box/ResumeButton.pressed.connect(_toggle_pause)
	$UI/PausePanel/Box/RestartButton.pressed.connect(_restart)
	$UI/EndPanel/Box/RestartButton.pressed.connect(_restart)
	music.finished.connect(music.play)

	_update_hud()
	_show_hint("A/D или стрелки — движение, Пробел — прыжок, Esc — пауза, R — рестарт", 6.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart()
	elif event.is_action_pressed("pause") and (state == State.PLAYING or state == State.PAUSED):
		_toggle_pause()


# ---------- события игры ----------

func _on_coin_collected() -> void:
	if state != State.PLAYING:
		return
	coins += 1
	_update_hud()
	if coins >= total_coins:
		door.open()
		$DoorSound.play()
		_show_hint("Все монеты собраны — дверь открыта!", 3.0)


func _on_player_damaged() -> void:
	$HurtSound.play()
	_change_health(-1)


func _on_fall_zone_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or state != State.PLAYING:
		return
	# Падение в пропасть: минус жизнь и возврат на старт
	$HurtSound.play()
	if _change_health(-1):
		player.respawn()


func _on_door_blocked() -> void:
	_show_hint("Дверь закрыта. Собери все монеты: %d / %d" % [coins, total_coins], 2.5)


func _on_door_reached() -> void:
	if state != State.PLAYING:
		return
	state = State.WON
	player.can_control = false
	music.stop()
	$WinSound.play()
	_show_end("Победа!", "Собрано монет: %d / %d\nОсталось жизней: %d" % [coins, total_coins, health])


## Возвращает true, если игрок остался жив.
func _change_health(delta: int) -> bool:
	health = clampi(health + delta, 0, MAX_HEALTH)
	_update_hud()
	if health <= 0 and state == State.PLAYING:
		state = State.LOST
		player.can_control = false
		music.stop()
		$LoseSound.play()
		_show_end("Поражение", "Жизни закончились.\nСобрано монет: %d / %d" % [coins, total_coins])
		return false
	return true


# ---------- интерфейс ----------

func _update_hud() -> void:
	coin_label.text = "Монеты: %d / %d" % [coins, total_coins]
	for i in hearts.size():
		hearts[i].texture = HEART_FULL if i < health else HEART_EMPTY


func _show_hint(text: String, seconds: float) -> void:
	hint_label.text = text
	hint_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.6)


func _show_end(title: String, info: String) -> void:
	end_title.text = title
	end_info.text = info
	end_panel.visible = true
	$UI/EndPanel/Box/RestartButton.grab_focus()


func _toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
		pause_panel.visible = true
		$UI/PausePanel/Box/ResumeButton.grab_focus()
	elif state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false
		pause_panel.visible = false


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
