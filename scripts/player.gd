extends CharacterBody3D

signal coin_collected

@export_subgroup("Components")
@export var view: Node3D

@export_subgroup("Properties")
@export var movement_speed = 250
@export var jump_strength = 7
@export var allow_double_jump := false
@export var normal_deceleration := 10.0
@export var ice_deceleration := 0.03

var movement_velocity: Vector3
var rotation_direction: float
var gravity = 0
var respawn_position: Vector3

var previously_floored = false

var jump_single = true
var jump_double = false

var coins = 0

@onready var particles_trail = $ParticlesTrail
@onready var sound_footsteps = $SoundFootsteps
@onready var model = $Character
@onready var animation = $Character/AnimationPlayer
@onready var ground_ray_cast: RayCast3D = $GroundRayCast

# Functions

func _ready() -> void:
	rotation_direction = rotation.y
	respawn_position = global_position


func _physics_process(delta):

	# Handle functions

	handle_controls(delta)
	handle_gravity(delta)

	handle_effects(delta)

	# Movement

	var applied_velocity: Vector3
	var has_input := movement_velocity.length() > 0.01

	if has_input:
		applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	else:
		var deceleration := normal_deceleration

		if is_on_ice():
			deceleration = ice_deceleration

		applied_velocity = velocity
		applied_velocity.x = move_toward(velocity.x, 0, deceleration)
		applied_velocity.z = move_toward(velocity.z, 0, deceleration)

	applied_velocity.y = -gravity

	velocity = applied_velocity
	move_and_slide()

	# Rotation

	if Vector2(velocity.z, velocity.x).length() > 0:
		rotation_direction = Vector2(velocity.z, velocity.x).angle()

	rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10)

	# Falling/respawning

	if position.y < -10:
		respawn()

	# Animation for scale (jumping and landing)

	model.scale = model.scale.lerp(Vector3(1, 1, 1), delta * 10)

	# Animation when landing

	if is_on_floor() and gravity > 2 and !previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		Audio.play("res://sounds/land.ogg")

	previously_floored = is_on_floor()

# Handle animation(s)

func handle_effects(delta):

	particles_trail.emitting = false
	sound_footsteps.stream_paused = true

	if is_on_floor():
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		var speed_factor = horizontal_velocity.length() / movement_speed / delta
		var has_movement_input := Vector2(movement_velocity.x, movement_velocity.z).length() > 0.01

		if speed_factor > 0.05 and has_movement_input:
			if animation.current_animation != "walk":
				animation.play("walk", 0.1)

			if speed_factor > 0.3:
				sound_footsteps.stream_paused = false
				sound_footsteps.pitch_scale = speed_factor

			if speed_factor > 0.75:
				particles_trail.emitting = true

		elif animation.current_animation != "idle":
			animation.play("idle", 0.1)
			
		if animation.current_animation == "walk":
			animation.speed_scale = speed_factor
		else:
			animation.speed_scale = 1.0
			
	elif animation.current_animation != "jump":
		animation.play("jump", 0.1)

# Handle movement input

func handle_controls(delta):

	# Movement

	var input := Vector3.ZERO

	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")

	input = input.rotated(Vector3.UP, view.rotation.y)

	if input.length() > 1:
		input = input.normalized()

	movement_velocity = input * movement_speed * delta

	# Jumping

	if Input.is_action_just_pressed("jump"):

		if jump_single or (allow_double_jump and jump_double):
			jump()

# Handle gravity

func handle_gravity(delta):

	gravity += 25 * delta

	if gravity > 0 and is_on_floor():

		jump_single = true
		jump_double = false
		gravity = 0

# Surface detection

func is_on_ice() -> bool:
	if !ground_ray_cast.is_colliding():
		return false

	var collider := ground_ray_cast.get_collider()

	return is_ice_node(collider)


func is_ice_node(node: Object) -> bool:
	var current := node as Node

	while current != null:
		if current.is_in_group("ice_platform"):
			return true

		current = current.get_parent()

	return false

# Jumping

func jump():

	Audio.play("res://sounds/jump.ogg")

	gravity = -jump_strength

	model.scale = Vector3(0.5, 1.5, 0.5)

	if jump_single:
		jump_single = false;
		jump_double = allow_double_jump;
	else:
		jump_double = false;


func set_checkpoint(new_position: Vector3) -> void:
	respawn_position = new_position


func respawn() -> void:
	global_position = respawn_position
	velocity = Vector3.ZERO
	movement_velocity = Vector3.ZERO
	gravity = 0
	jump_single = true
	jump_double = false
	previously_floored = false

# Collecting coins

func collect_coin():

	coins += 1

	coin_collected.emit(coins)
