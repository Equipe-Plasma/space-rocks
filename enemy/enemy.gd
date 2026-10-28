
extends Area2D

# ==================================
# CONFIGURAÇÕES DO INIMIGO
# ==================================

@export var bullet_scene: PackedScene
@export var speed: float = 150.0
@export var rotation_speed: float = 120.0
@export var health: int = 3
@export var bullet_spread: float = 0.2
# Nó que seguirá o caminho
var follow: PathFollow2D = PathFollow2D.new()

# Referência ao jogador
var target: Node2D = null


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:

	# Escolher uma aparência aleatória
	$Sprite2D.frame = randi() % 3

	# Obter os caminhos disponíveis
	var paths = $EnemyPaths.get_children()

	if paths.is_empty():
		push_error("Nenhum Path2D encontrado!")
		return

	# Escolher um caminho aleatório
	var path = paths.pick_random()

	# Adicionar o seguidor ao caminho
	path.add_child(follow)

	# Impedir que o caminho reinicie
	follow.loop = false

	# Evitar que PathFollow2D gire automaticamente
	follow.rotates = false

	# Iniciar no começo do caminho
	follow.progress_ratio = 0.0

	# Posicionar a nave
	global_position = follow.global_position


# ==================================
# MOVIMENTAÇÃO DO INIMIGO
# ==================================

func _physics_process(delta: float) -> void:

	if follow.get_parent() == null:
		return

	# Girar a nave
	rotation += deg_to_rad(rotation_speed) * delta

	# Avançar pelo caminho
	follow.progress += speed * delta

	# Atualizar posição da nave
	global_position = follow.global_position

	# Remover ao terminar o caminho
	if follow.progress_ratio >= 1.0:
		queue_free()


# ==================================
# TEMPORIZADOR DE TIRO
# ==================================

func _on_gun_cooldown_timeout() -> void:
	shoot()


func shoot() -> void:
	$ShootSound.play()
	if target == null or not is_instance_valid(target):
		return

	if bullet_scene == null:
		push_error("Enemy Bullet não configurada!")
		return

	var dir = global_position.direction_to(
		target.global_position
	)

	dir = dir.rotated(
		randf_range(-bullet_spread, bullet_spread)
	)

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.start(global_position, dir)


var exploding: bool = false


func take_damage(amount: int = 1) -> void:
	if exploding:
		return

	health -= amount

	if health <= 0:
		explode()
	else:
		$AnimationPlayer.play("flash")


func explode() -> void:
	$ExplosionSound.play()
	if exploding:
		return

	exploding = true
	speed = 0.0

	$GunCooldown.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()

	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")

	await $Explosion/AnimationPlayer.animation_finished

	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("rocks"):
		return

	if body.has_method("take_shield_damage"):
		body.take_shield_damage(50.0)
		explode()
