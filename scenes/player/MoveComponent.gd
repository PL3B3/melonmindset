extends KinematicBody

# -- Movement Settings --
var velocity = Vector3()
var speed: float = 10.0
var max_ground_speed:float = speed * 1.2
var accel_air:float = 5.0
var accel_ground:float= 12.0
var jump_height:float = 3.5
var jump_duration:float = 0.35
var gravity:float = (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force:float = gravity * jump_duration
var snap_distance:float = 0.5

func _simulate(player, delta, input_frame):
	player.last_position = global_transform.origin
	var snap = Vector3.DOWN * snap_distance
	var direction = input_frame[Inputs.Z_MOTION] * Vector3.FORWARD + input_frame[Inputs.X_MOTION] * Vector3.RIGHT
	direction = direction.rotated(Vector3.UP, deg2rad(input_frame[Inputs.YAW])).normalized()
	# var input_z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	# var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	# var z_movement = player.visual_root.global_transform.basis.z * input_z
	# var x_movement = player.visual_root.global_transform.basis.x * input_x
	# var dv = (z_movement + x_movement).normalized()
	var h_velocity = Vector3(velocity.x, 0, velocity.z)
	if is_on_floor():
		var target_vel = Math.get_slope_velocity(direction * speed, get_floor_normal())
		velocity = velocity.linear_interpolate(target_vel, clamp(accel_ground * delta, 0.0, 1.0))
		if h_velocity.length() > max_ground_speed:
			velocity.x *= max_ground_speed / h_velocity.length()
			velocity.z *= max_ground_speed / h_velocity.length()
		if Input.is_action_pressed("jump"):
			velocity.y = jump_force
			snap = Vector3()
	else:
		if h_velocity.dot(direction) <= speed:
			velocity += direction * (speed - h_velocity.dot(direction)) * accel_air * delta
		velocity.y -= gravity * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)