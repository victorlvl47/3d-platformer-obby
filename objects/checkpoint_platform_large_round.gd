extends Area3D

@export var respawn_offset := Vector3(0, 1.5, 0)

var activated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if activated:
		return

	if body.has_method("set_checkpoint"):
		activated = true
		body.set_checkpoint(global_position + respawn_offset)
		print("Checkpoint reached")
