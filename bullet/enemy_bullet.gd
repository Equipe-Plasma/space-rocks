
extends Area2D

@export var speed: float = 1000.0
@export var damage: float = 15.0

var direction: Vector2 = Vector2.RIGHT


func start(_pos: Vector2, _dir: Vector2) -> void:
	global_position = _pos
	direction = _dir.normalized()
	rotation = direction.angle()


func _process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_shield_damage"):
		body.take_shield_damage(damage)

	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
