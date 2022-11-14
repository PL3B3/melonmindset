extends KinematicBody

var enabled = true
var rng = RandomNumberGenerator.new()
var last_pos:Vector3
var speed := 1.0
var velocity = Vector3.FORWARD * speed
var jump_height := 0.5
var jump_duration := 0.45
var gravity := (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force := gravity * jump_duration

func _ready():
	last_pos = transform.origin
	rng.randomize()
	$MeshInstance.set_as_toplevel(true)

func _process(delta):
	$MeshInstance.transform.origin = last_pos.linear_interpolate(
		transform.origin, Engine.get_physics_interpolation_fraction())
	var h_dir = Vector3(velocity.x, 0, velocity.z)
#	print(h_dir)
	$MeshInstance.look_at($MeshInstance.transform.origin + h_dir, Vector3.UP)
	Network.sigma_position = $MeshInstance.transform.origin

var target_velocity = velocity
var curve = 0
func _physics_process(delta):
	if not enabled:
		return
	last_pos = global_transform.origin
	if rng.randf() > 0.99:
#		target_velocity = speed * velocity.normalized().rotated(Vector3.UP, rng.randf_range(-3.0, 3.0))
		curve = rng.randf_range(-3.0, 3.0)
#	target_velocity.y = velocity.y
#	velocity = velocity.linear_interpolate(target_velocity, delta * accel_ground)
	velocity = velocity.rotated(Vector3.UP, curve * delta)
	if rng.randf() > 0.99 and transform.origin.y < jump_height:
		velocity.y = jump_force
	velocity += delta * gravity * Vector3.DOWN
	velocity = clamp_h_vel(velocity, speed)
	var collision = move_and_collide(velocity * delta)
	if collision: velocity = velocity.bounce(collision.normal)

func clamp_h_vel(vel:Vector3, speed_lim:float) -> Vector3:
	var y_tmp = vel.y
	vel.y = 0
	if vel.length() > speed_lim:
		vel *= speed_lim / vel.length()
	vel.y = y_tmp
	return vel
