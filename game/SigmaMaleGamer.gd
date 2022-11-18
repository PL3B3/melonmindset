extends KinematicBody

onready var raycast = get_node("RayCast")
onready var mesh = get_node("MeshInstance")
onready var anim = get_node("Anim")
var enabled = true
var rng = RandomNumberGenerator.new()
var last_pos:Vector3
var speed := 20.0
var velocity = Vector3.FORWARD * speed
var jump_height := 5.0
var jump_duration := 0.45
var gravity := (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force := gravity * jump_duration

func _ready():
    last_pos = transform.origin
    rng.randomize()
    mesh.set_as_toplevel(true)
    anim.play("Run")

func _process(delta):
    mesh.transform.origin = last_pos.linear_interpolate(
        transform.origin, Engine.get_physics_interpolation_fraction())
    var h_dir = Vector3(velocity.x, 0, velocity.z)
    mesh.look_at(mesh.transform.origin + h_dir, Vector3.UP)
    Network.sigma_position = mesh.transform.origin

var curve = 0
func _physics_process(delta):
    if not enabled:
        return
    last_pos = global_transform.origin
    if rng.randf() > 0.99:
        curve = rng.randf_range(-3.0, 3.0)
    velocity = velocity.rotated(Vector3.UP, curve * delta)
    if not raycast.is_colliding():
        velocity += delta * gravity * Vector3.DOWN
    elif rng.randf() > 0.98:
        velocity.y = jump_force
    
    velocity = normalize_h_vel(velocity, speed)
    var collision = move_and_collide(velocity * delta)
    if collision: velocity = velocity.bounce(collision.normal)

func normalize_h_vel(vel:Vector3, speed_lim:float) -> Vector3:
    var y_tmp = vel.y
    vel.y = 0
    vel *= speed_lim / vel.length()
    vel.y = y_tmp
    return vel
