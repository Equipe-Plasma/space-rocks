extends RigidBody2D

var screensize = Vector2.ZERO
var size
var radius
var scale_factor = 0.2
var exploding: bool = false
signal exploded(size, radius, pos, vel)

func start(_position, _velocity, _size):
	
	position = _position
	size = _size

	mass = 1.5 * size
	$Explosion.scale = Vector2.ONE * 0.75 * size
	$Sprite2D.scale = Vector2.ONE * scale_factor * size

	radius = int(
		$Sprite2D.texture.get_size().x / 2 *
		$Sprite2D.scale.x
	)

	var shape = CircleShape2D.new()
	shape.radius = radius

	$CollisionShape2D.shape = shape

	linear_velocity = _velocity
	angular_velocity = randf_range(-PI, PI)


func _integrate_forces(physics_state):
	var xform = physics_state.transform

	xform.origin.x = wrapf(
		xform.origin.x,
		-radius,
		screensize.x + radius
	)

	xform.origin.y = wrapf(
		xform.origin.y,
		-radius,
		screensize.y + radius
	)

	physics_state.transform = xform

func explode() -> void:
	# Evita explosões repetidas
	if exploding:
		return

	exploding = true

	# Desativar a colisão
	$CollisionShape2D.set_deferred("disabled", true)

	# Esconder a imagem do asteroide
	$Sprite2D.hide()

	# Mostrar a explosão
	$Explosion.show()

	# Reproduzir a animação
	$Explosion/AnimationPlayer.play("explosion")

	# Avisar a cena principal
	exploded.emit(
		size,
		radius,
		position,
		linear_velocity
	)

	# Parar o asteroide
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	# Esperar a animação terminar
	await $Explosion/AnimationPlayer.animation_finished

	# Remover o asteroide
	queue_free()
