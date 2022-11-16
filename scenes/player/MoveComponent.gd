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

func _simulate(player, delta):
	var snap = Vector3.DOWN * snap_distance
	var input_z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var z_movement = player.visual_root.global_transform.basis.z * input_z
	var x_movement = player.visual_root.global_transform.basis.x * input_x
	var dv = (z_movement + x_movement).normalized()
	var h_velocity = Vector3(velocity.x, 0, velocity.z)
	if is_on_floor():
		var target_vel = Math.get_slope_velocity(dv * speed, get_floor_normal())
		velocity = velocity.linear_interpolate(target_vel, accel_ground * delta)
		if h_velocity.length() > max_ground_speed:
			velocity.x *= max_ground_speed / h_velocity.length()
			velocity.z *= max_ground_speed / h_velocity.length()
		if Input.is_action_pressed("jump"):
			velocity.y = jump_force
			snap = Vector3()
	else:
		if h_velocity.dot(dv) <= speed:
			velocity += dv * (speed - h_velocity.dot(dv)) * accel_air * delta
		velocity.y -= gravity * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)