extends Node3D

@export_group("Properties")
@export var target: Node3D

@export_group("Zoom")
@export var zoom_minimum := 4.0
@export var zoom_maximum := 16.0
@export var zoom_speed := 1.0

@export_group("Rotation")
@export var mouse_sensitivity := 0.25
@export var rotation_smoothness := 8.0

var camera_rotation: Vector3
var zoom := 10.0
var rotating_camera := false

@onready var camera: Camera3D = $Camera


func _ready() -> void:
	camera_rotation = rotation_degrees


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating_camera = event.pressed

			if rotating_camera:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom -= zoom_speed

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom += zoom_speed

		zoom = clamp(zoom, zoom_minimum, zoom_maximum)

	if event is InputEventMouseMotion and rotating_camera:
		camera_rotation.y -= event.relative.x * mouse_sensitivity
		camera_rotation.x -= event.relative.y * mouse_sensitivity
		camera_rotation.x = clamp(camera_rotation.x, -80.0, -10.0)

	if event.is_action_pressed("ui_cancel"):
		rotating_camera = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta: float) -> void:
	if target == null:
		return

	position = position.lerp(target.position, delta * 4.0)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * rotation_smoothness)
	camera.position = camera.position.lerp(Vector3(0, 0, zoom), delta * 8.0)
