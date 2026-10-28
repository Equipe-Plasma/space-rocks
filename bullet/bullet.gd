
extends Area2D

@export var speed: float = 1000.0

var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Configurar o detector de saída da tela
	var notifier = get_node_or_null(
        "VisibleOnScreenNotifier2D"
	)

	if notifier != null:
		if not notifier.screen_exited.is_connected(
			_on_visible_on_screen_notifier_2d_screen_exited
		):
			notifier.screen_exited.connect(
				_on_visible_on_screen_notifier_2d_screen_exited
			)
	else:
		push_warning(
            "VisibleOnScreenNotifier2D não encontrado!"
		)

	# Configurar a detecção de colisões
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func start(_transform: Transform2D) -> void:
	global_transform = _transform
	velocity = global_transform.x * speed

	print("Laser criado!")
	print("Posição: ", global_position)
	print("Velocidade: ", velocity)


func _process(delta: float) -> void:
	global_position += velocity * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("rocks"):
		if body.has_method("explode"):
			body.explode()

		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		area.take_damage(1)
		queue_free()
