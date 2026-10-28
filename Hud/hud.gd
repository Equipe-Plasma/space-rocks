
extends CanvasLayer

# Sinal para iniciar o jogo
signal start_game

# Referências aos nós da interface
@onready var lives_counter = $MarginContainer/HBoxContainer/LivesCounter.get_children()
@onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var message = $VBoxContainer/Message
@onready var start_button = $VBoxContainer/StartButton
@onready var shield_bar = $MarginContainer/HBoxContainer/ShieldBar

var bar_textures = {
	"green": preload("res://assets/bar_green_200.png"),
	"yellow": preload("res://assets/bar_yellow_200.png"),
	"red": preload("res://assets/bar_red_200.png")
}
func _ready() -> void:
	# Conectar botão Start
	if not start_button.pressed.is_connected(
		_on_start_button_pressed
	):
		start_button.pressed.connect(
			_on_start_button_pressed
		)

	# Conectar Timer
	if not $Timer.timeout.is_connected(
		_on_timer_timeout
	):
		$Timer.timeout.connect(
			_on_timer_timeout
		)

	update_score(0)
	update_lives(3)


# Mostrar mensagem temporária
func show_message(text_value: String) -> void:
	message.text = text_value
	message.show()
	$Timer.start()


# Atualizar pontuação
func update_score(value: int) -> void:
	score_label.text = str(value)


# Atualizar vidas
func update_lives(value: int) -> void:
	for item in range(3):
		lives_counter[item].visible = value > item


# Fim do jogo
func game_over() -> void:
	show_message("Game Over")

	await $Timer.timeout

	start_button.show()


# Quando clicar em Start
func _on_start_button_pressed() -> void:
	start_button.hide()
	start_game.emit()


# Quando o Timer terminar
func _on_timer_timeout() -> void:
	message.hide()
	message.text = ""




func update_shield(value: float) -> void:
	print("Valor do escudo: ", value)

	if value < 0.4:
		shield_bar.texture_progress = bar_textures["red"]
		print("COR: VERMELHO")

	elif value < 0.7:
		shield_bar.texture_progress = bar_textures["yellow"]
		print("COR: AMARELO")

	else:
		shield_bar.texture_progress = bar_textures["green"]
		print("COR: VERDE")

	shield_bar.value = value

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
