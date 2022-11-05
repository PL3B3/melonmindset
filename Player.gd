extends KinematicBody
class_name Player

onready var visual_root:Spatial = get_node("VisualRoot")
onready var camera:Camera = get_node("VisualRoot/Camera")

# ----------------------------------------------------------------Input settings
var mouse_sensitivity := 0.05
var jump_try_ticks_default := 7
var last_physics_frame_position = Vector3()

# -------------------------------------------------------------Movement Settings
var velocity = Vector3()
var speed := 10.0
var accel := 16.0
var accel_air := 2.0
var accel_ground := 16.0
var jump_height := 4.0
var jump_duration := 0.4
var gravity := (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force := gravity * jump_duration
var ground_snap = 100

func _ready():
	visual_root.set_as_toplevel(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if (event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		visual_root.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		camera.rotation_degrees.x = clamp(
			camera.rotation_degrees.x - (event.relative.y * mouse_sensitivity), -90.0, 90.0
		)
	elif event.is_action_pressed("click"):
		pass
	elif event.is_action_pressed("toggle_mouse_mode"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	# interpolating what gets rendered between physics frames
	visual_root.transform.origin = last_physics_frame_position.linear_interpolate(
		transform.origin, Engine.get_physics_interpolation_fraction())

func _physics_process(delta):
	var input_z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var z_movement = visual_root.global_transform.basis.z * input_z
	var x_movement = visual_root.global_transform.basis.x * input_x
	# var target_velocity = speed * (z_movement + x_movement).normalized()
	# target_velocity.y = velocity.y
	# velocity = velocity.linear_interpolate(target_velocity, accel * delta)
	var dv = (z_movement + x_movement).normalized()
	var dot_speed = velocity.dot(dv)
	if is_on_floor():
		accel = accel_ground
		velocity = velocity.linear_interpolate(dv * speed, accel_ground * delta)
		# prevents sliding down slopes, makes ramp transitions snappier
		velocity -= get_floor_normal() * ground_snap * delta
		if Input.is_action_pressed("jump"):
			velocity.y = jump_force
	else:
		accel = accel_air
		if dot_speed <= speed:
			velocity += dv * speed * accel_air * delta
		else:
			velocity *= speed / dot_speed
		velocity.y -= gravity * delta
	velocity = move_and_slide(velocity, Vector3.UP)
	last_physics_frame_position = transform.origin
