extends Spatial

onready var mesh = get_node("Mesh")
var rng = RandomNumberGenerator.new()
var max_length:float = 100.0
var length:float = 8.0
var speed:float = 400.0
var target:Vector3
var lifetime:float = 0.3

func instantiate(start:Vector3, end:Vector3):
    length = min(max_length, (end - start).length())
    target = end

func _ready():
    rng.randomize()
    set_as_toplevel(true)
    look_at(target, Vector3.UP)
    speed *= rng.randf_range(0.2, 1.0)
    $Mesh.transform.origin.z -= 0.5 * length
    $Mesh.scale.z = length
    $Mesh.scale.x *= rng.randf_range(0.5, 3.0)
    $Mesh.scale.y *= rng.randf_range(0.5, 3.0)

func _process(delta):
    lifetime -= delta
    $Mesh.scale.z -= delta * speed
    $Mesh.transform.origin.z -= 0.5 * delta * speed
    if lifetime <= 0 or $Mesh.scale.z <= 0:
        queue_free()
