extends Spatial

var rng = RandomNumberGenerator.new()
var length:float = 8.0
var speed:float = 400.0
var lifetime:float = 1.0

func calculate_lifetime(travel_distance: float):
	rng.randomize()
	speed *= rng.randf_range(0.5, 1.0)
	length = rng.randf_range(0.5, 1.0) * min(0.5 * travel_distance, length)
	lifetime = min((travel_distance - 2 * length) / speed, lifetime)

func _ready():
	$MeshInstance.transform.origin.z -= length
	$MeshInstance.scale.z = length
	

func _physics_process(delta):
	lifetime -= delta
	if lifetime < 0:
		queue_free()
	transform.origin -= global_transform.basis.z * speed * delta

