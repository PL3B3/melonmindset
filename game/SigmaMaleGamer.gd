extends KinematicBody

var enabled = true
var rng = RandomNumberGenerator.new()
var ticks_until_next_vel_change = 200
var last_pos:Vector3
var speed := 10.0
var velocity = Vector3.FORWARD * speed
var accel_air := 4.0
var accel_ground := 16.0
var jump_height := 4.5
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
	Network.sigma_position = $MeshInstance.transform.origin

var target_velocity = velocity
var curve = 0
func _physics_process(delta):
	if not enabled:
		return
	
	last_pos = global_transform.origin
	if rng.randf() > 0.99:
		target_velocity = speed * velocity.normalized().rotated(Vector3.UP, rng.randf_range(-3.0, 3.0))
		curve = rng.randf_range(-3.0, 3.0)
	
#	target_velocity.y = velocity.y
#	velocity = velocity.linear_interpolate(target_velocity, delta * accel_ground)
	velocity = velocity.rotated(Vector3.UP, curve * delta)
#	$RayCast.cast_to = velocity.normalized() * 2
	if rng.randf() > 0.99 and transform.origin.y < jump_height:
		velocity.y = jump_force
#	if is_on_wall():
#		print("on wall: ", $RayCast.get_collision_normal())
#		velocity = velocity.bounce($RayCast.get_collision_normal())
	velocity += delta * gravity * Vector3.DOWN

	var collision = move_and_collide(velocity * delta)
	if collision:
#		if collision.normal.dot(Vector3.UP) > 0.4:
#			velocity.y = jump_force
		velocity = velocity.bounce(collision.normal)
