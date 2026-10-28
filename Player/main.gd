
extends Node2D

# Cena dos asteroides
const ROCK_SCENE: PackedScene = preload(
    "res://rock/rock.tscn"
)

# Variáveis do jogo
var screensize: Vector2 = Vector2.ZERO
var level: int = 0
var score: int = 0
var playing: bool = false
@export var enemy_scene: PackedScene

func _ready() -> void:
	setup_background()
	randomize()
	$Player.lives_changed.connect($HUD.update_lives)
	$Player.dead.connect(game_over)
	screensize = get_viewport().get_visible_rect().size

	# Conectar o sinal do HUD
	if not $HUD.start_game.is_connected(new_game):
		$HUD.start_game.connect(new_game)
	if not $Player.shield_changed.is_connected($HUD.update_shield):
		$Player.shield_changed.connect($HUD.update_shield)
	


# Iniciar nova partida
func new_game() -> void:
	playing = false
	get_tree().paused = false

	$EnemyTimer.stop()
	$Music.play()

	get_tree().call_group("rocks", "queue_free")
	get_tree().call_group("enemies", "queue_free")

	level = 0
	score = 0

	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")

	$Player.reset()

	await $HUD/Timer.timeout

	playing = true

# Iniciar nova fase
func new_level() -> void:
	level += 1

	$HUD.show_message("Wave %s" % level)
	$LevelupSound.play()

	for i in range(level):
		spawn_rock(3)
		
	$EnemyTimer.start(randf_range(5.0, 10.0))

# Verificar fim da fase
func _process(_delta: float) -> void:
	if not playing:
		return

	if get_tree().get_nodes_in_group("rocks").is_empty():
		new_level()


# Criar asteroides
func spawn_rock(
	size: int,
	pos = null,
	vel = null
) -> void:

	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position

	if vel == null:
		vel = (
			Vector2.RIGHT.rotated(
				randf_range(0.0, TAU)
			)
			* randf_range(50.0, 125.0)
		)

	var rock = ROCK_SCENE.instantiate()

	rock.screensize = screensize
	rock.start(pos, vel, size)

	rock.exploded.connect(_on_rock_exploded)

	call_deferred("add_child", rock)


# Dividir asteroides
func _on_rock_exploded(
	size: int,
	radius: float,
	pos: Vector2,
	vel: Vector2
) -> void:
	score += 100 * (4 - size)
	$HUD.update_score(score)
	$ExplosionSound.play()
	
	if size <= 1:
		return

	for offset in [-1, 1]:
		var dir = (
			$Player.position.direction_to(pos)
			.orthogonal() * offset
		)

		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1

		spawn_rock(size - 1, newpos, newvel)


func game_over() -> void:
	# Encerrar a partida
	playing = false

	# Parar o surgimento de inimigos
	$EnemyTimer.stop()
	$Music.stop()

	# Remover todos os asteroides
	get_tree().call_group("rocks", "queue_free")

	# Remover todas as naves inimigas
	get_tree().call_group("enemies", "queue_free")

	# Mostrar a tela de Game Over
	$HUD.game_over()



func _input(event: InputEvent) -> void:

	# Reiniciar o jogo com R
	if event.is_action_pressed("restart") and not event.is_echo():
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	if event.is_action_pressed("test_death"):
		$Player.lives = 0

	# Pausar ou continuar com P
	if event.is_action_pressed("pause") and not event.is_echo():
		if not playing:
			return

		get_tree().paused = not get_tree().paused

		var message = $HUD/VBoxContainer/Message

		if get_tree().paused:
			message.text = "Paused"
			message.show()
		else:
			message.text = ""
			message.hide()


func _on_enemy_timer_timeout() -> void:

	if not playing:
		return

	if enemy_scene == null:
		push_error("Enemy Scene não configurada!")
		return

	# Criar o inimigo
	var enemy = enemy_scene.instantiate()

	# Adicionar à cena principal
	add_child(enemy)

	# Informar quem é o jogador
	enemy.target = $Player

	# Programar o próximo inimigo
	$EnemyTimer.start(
		randf_range(20.0, 40.0)
	)


func setup_background() -> void:
	var bg: Sprite2D = $Background

	if bg.texture == null:
		return

	var screen_size = get_viewport_rect().size
	var texture_size = bg.texture.get_size()

	# Posicionar a imagem na origem da tela
	bg.centered = false
	bg.position = Vector2.ZERO

	# Preencher toda a tela
	bg.scale = Vector2(
		screen_size.x / texture_size.x,
		screen_size.y / texture_size.y
	)

	# Ignorar transformações herdadas
	bg.top_level = true
	bg.global_position = Vector2.ZERO

	# Manter o fundo atrás dos objetos
	bg.z_index = -10
