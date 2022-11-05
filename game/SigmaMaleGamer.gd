extends KinematicBody

var speed := 0 * 1.5
var velocity = Vector3.FORWARD
var rng = RandomNumberGenerator.new()
var ticks_until_next_vel_change = 200
var last_pos:Vector3
var this_pos:Vector3

func _ready():
	rng.randomize()
	$MeshInstance.set_as_toplevel(true)
	this_pos = transform.origin

func _process(delta):
	$MeshInstance.transform.origin = last_pos.linear_interpolate(
		this_pos, Engine.get_physics_interpolation_fraction())
	Network.sigma_position = $MeshInstance.transform.origin


var target_velocity = velocity
func _physics_process(delta):
	last_pos = this_pos
	this_pos = transform.origin
	if ticks_until_next_vel_change == 0:
		target_velocity = speed * velocity.normalized().rotated(Vector3.UP, rng.randf_range(-3.0, 3.0))
		target_velocity.y = rng.randf_range(-speed, speed)
		ticks_until_next_vel_change = rng.randi_range(50, 100)
	
	velocity = velocity.linear_interpolate(target_velocity, 0.1)
	
#	if is_on_floor():
#		print("sigma floored")
#		velocity = Vector3.UP * 15
	
	velocity += delta * 5.0 * Vector3.DOWN
	
	velocity = move_and_slide(velocity)
	
	ticks_until_next_vel_change -= 1
