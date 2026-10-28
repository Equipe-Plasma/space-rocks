
extends RigidBody2D
signal lives_changed
signal dead

var reset_pos = false
var lives = 0: set = set_lives
signal shield_changed

@export var max_shield: float = 100.0
@export var shield_regen: float = 5.0

var shield: float = 100.0

@export var engine_power: float = 900.0
@export var spin_power: float = 18000.0
@export var fire_rate: float = 0.25

# Cena do laser
# Confira se o caminho corresponde ao seu projeto
const BULLET_SCENE: PackedScene = preload("res://bullet/bullet.tscn")


var can_shoot: bool = true

var thrust: Vector2 = Vector2.ZERO
var rotation_dir: float = 0.0
var screensize: Vector2 = Vector2.ZERO


enum {INIT, ALIVE, INVULNERABLE, DEAD}

var state = INIT


func _ready() -> void:
	screensize = get_viewport_rect().size

	$GunCooldown.wait_time = fire_rate
	$GunCooldown.one_shot = true
	$GunCooldown.stop()

	if not $GunCooldown.timeout.is_connected(
		_on_gun_cooldown_timeout
	):
		$GunCooldown.timeout.connect(
			_on_gun_cooldown_timeout
		)

	change_state(INIT)



func change_state(new_state):
	match new_state:
		INIT:
			$EngineSound.stop()
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5

		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			$Sprite2D.modulate.a = 1.0

		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()

		DEAD:
			$EngineSound.stop()
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			dead.emit()

	state = new_state


func _process(delta: float) -> void:
	get_input()

	if state == ALIVE and shield < max_shield:
		set_shield(shield + shield_regen * delta)
		
func get_input() -> void:
	$Exhaust.emitting = false
	thrust = Vector2.ZERO
	rotation_dir = 0

	# Bloquear controles durante a pausa
	if get_tree().paused:
		return

	# Bloquear controles fora do jogo
	if state in [DEAD, INIT]:
		return

	# Movimentação
	if Input.is_action_pressed("thrust"):
		$Exhaust.emitting = true
		thrust = transform.x * engine_power

		if not $EngineSound.playing:
			$EngineSound.play()
	else:
		$EngineSound.stop()


	# Rotação
	rotation_dir = Input.get_axis(
		"rotate_left",
        "rotate_right"
	)

	# Disparo
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()


func _physics_process(_delta):
	if state == ALIVE:
		constant_force = thrust
		constant_torque = rotation_dir * spin_power
	else:
		constant_force = Vector2.ZERO
		constant_torque = 0.0

func _integrate_forces(physics_state):
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		physics_state.linear_velocity = Vector2.ZERO
		physics_state.angular_velocity = 0.0
		reset_pos = false

	var xform = physics_state.transform

	xform.origin.x = wrapf(
		xform.origin.x, 0, screensize.x
	)

	xform.origin.y = wrapf(
		xform.origin.y, 0, screensize.y
	)

	physics_state.transform = xform

func shoot() -> void:
	$LaserSound.play()
	if state != ALIVE:
		return

	if not can_shoot:
		return

	can_shoot = false
	$GunCooldown.start()

	# Criar o laser
	var bullet = BULLET_SCENE.instantiate()

	# Adicionar à cena principal
	get_tree().current_scene.add_child(bullet)

	# Posicionar o laser na frente da nave
	bullet.start($Muzzle.global_transform)

	print("Laser disparado!")


func _on_gun_cooldown_timeout() -> void:
	can_shoot = true

func set_lives(value):
	lives = value
	lives_changed.emit(lives)
	set_shield(max_shield)

	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)
		
func reset():
	reset_pos = true
	
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)
	set_shield(max_shield)


func _on_invulnerability_timer_timeout() -> void:
	change_state(ALIVE)


func _on_body_entered(body: Node2D) -> void:
	if state != ALIVE:
		return

	if body.is_in_group("rocks"):
		take_shield_damage(body.size * 25.0)
		body.explode()
		
func explode():
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")

	await $Explosion/AnimationPlayer.animation_finished

	$Explosion.hide()


func set_shield(value: float) -> void:
	shield = clampf(value, 0.0, max_shield)
	shield_changed.emit(shield / max_shield)
	if shield <= 0.0 and state == ALIVE:
		lives -= 1
		explode()

func take_shield_damage(amount: float) -> void:
	if state != ALIVE:
		return

	set_shield(shield - amount)
