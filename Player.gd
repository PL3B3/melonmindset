extends KinematicBody
class_name Player

onready var Tracer = preload("res://Tracer.tscn")
onready var visual_root:Spatial = get_node("VisualRoot")
onready var camera:Camera = get_node("VisualRoot/Camera")
onready var ability_root:Spatial = get_node("VisualRoot/Camera/AbilityRoot")

# ----------------------------------------------------------------Input settings
var mouse_sensitivity := 0.05
var last_position = Vector3()
var rng = RandomNumberGenerator.new()

# -------------------------------------------------------------Movement Settings
var velocity = Vector3()
var speed := 10.0
var accel_air := 4.0
var accel_ground := 16.0
var jump_height := 3.5
var jump_duration := 0.35
var gravity := (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force := gravity * jump_duration
var ground_snap = 100

func _ready():
	rng.randomize()
	visual_root.set_as_toplevel(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if (event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		visual_root.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x - (event.relative.y * mouse_sensitivity), -90.0, 90.0)
	
	elif event.is_action_pressed("toggle_camera"):
		camera.current = !camera.current
		
	elif event.is_action_pressed("toggle_mouse_mode"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	elif event.is_action_pressed("walk"):
		Engine.iterations_per_second = 7200 / Engine.iterations_per_second
#		Engine.time_scale = 0.5 / Engine.time_scale

func _process(delta):
	visual_root.global_transform.origin = last_position.linear_interpolate(
		global_transform.origin, Engine.get_physics_interpolation_fraction())
	# interpolating what gets rendered between physics frames
#	var position = global_transform.origin
#	var predicted_position = position + (position - last_position)
#	visual_root.global_transform.origin = position.linear_interpolate(
#		predicted_position, Engine.get_physics_interpolation_fraction())

var cooldown = 0
func _physics_process(delta):
	print(delta)
	var snap = Vector3.DOWN
	cooldown -= delta
	last_position = global_transform.origin
	if Input.is_action_pressed("click") and cooldown <= 0:
		raycast()
	var input_z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var z_movement = visual_root.global_transform.basis.z * input_z
	var x_movement = visual_root.global_transform.basis.x * input_x
	var dv = (z_movement + x_movement).normalized()
	if is_on_floor():
		var target_vel = Math.get_slope_velocity(dv * speed, get_floor_normal())
		velocity = velocity.linear_interpolate(target_vel, accel_ground * delta)
		if sqrt(h_vel()) > speed:
			velocity.x *= speed / sqrt(h_vel())
			velocity.z *= speed / sqrt(h_vel())
		if Input.is_action_pressed("jump"):
			velocity.y = jump_force
			snap = Vector3()
	else:
		var h_vel = Vector3(velocity.x, 0, velocity.z)
		if h_vel.dot(dv) <= speed:
			velocity += dv * (speed - h_vel.dot(dv)) * accel_air * delta
		velocity.y -= gravity * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)

func h_vel():
	return pow(velocity.x, 2) + pow(velocity.z, 2)

var spread = deg2rad(2.5)
func raycast():
	cooldown = 0.1
	var space_state = get_world().direct_space_state
	var ray_start = camera.global_transform.origin
	var ray_vec = -200 * camera.global_transform.basis.z
	ray_vec = ray_vec.rotated(camera.global_transform.basis.x, rng.randf_range(-spread, spread))
	ray_vec = ray_vec.rotated(camera.global_transform.basis.y, rng.randf_range(-spread, spread))
	var ray_end = ray_start + ray_vec
	var result = space_state.intersect_ray(ray_start, ray_end, [self])
	if result and is_instance_valid(result.collider):
		print("Hit ", result.collider)
		ray_end = result.position
	var tracer = Tracer.instance()
	tracer.calculate_lifetime((ray_end - ray_start).length())
	ability_root.add_child(tracer)
	tracer.look_at(ray_end, Vector3.UP)
	tracer.set_as_toplevel(true)
