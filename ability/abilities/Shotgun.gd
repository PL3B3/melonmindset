extends Spatial

onready var Tracer = preload("res://scenes/Tracer.tscn")
onready var fire_sound = preload("res://arms/assets/shot.wav")
onready var muzzle = get_node("Muzzle")
onready var audio = get_node("AudioPlayer")
onready var anim = get_node("Anim")
onready var rng = RandomNumberGenerator.new()

var spread:Vector2 = Vector2(deg2rad(3), deg2rad(3))
var rays_per_shot:int = 15
var max_range:float = 200.0
var fire_ticks:int = 40
var fire_timer:int = 0
var player = null
var ignored_objects = []

func fire(camera_transform):
	fire_timer = fire_ticks
	var fire_rate_seconds = fire_ticks * 1.0 / Engine.iterations_per_second
	var recoil_anim_length = anim.get_animation("Recoil").length
	anim.stop()
	anim.play("Recoil", -1, recoil_anim_length / fire_rate_seconds)
	audio.stop()
	audio.set_stream(fire_sound)
	audio.play()
	var results = []
	for i in rays_per_shot:
		var end = raycast(
			camera_transform.origin, camera_transform.basis, results
		)
		tracer_ends.append(end)
	var hit_counter = 0
	for result in results:
		if result and is_instance_valid(result.collider) and result.collider.is_in_group("sigma"):
			hit_counter += 1
	print("%d / %d bullets landed" % [hit_counter, rays_per_shot])

var tracer_ends = []
func render():
	while tracer_ends: draw_tracer(tracer_ends.pop_back())

func _physics_process(delta):
	fire_timer -= 1
	if Input.is_action_just_pressed("click") and fire_timer <= 0:
		fire(player.camera.global_transform)

# always called from within physics_process
func simulate():
	pass

func raycast(start, basis, results) -> Vector3:
	var space_state = get_world().direct_space_state
	var ray_vec = (max_range * -basis.z).rotated(
		basis.x, rng.randf_range(-spread.x, spread.x)
	).rotated(
		basis.y, rng.randf_range(-spread.y, spread.y)
	)
	var end = start + ray_vec
	var result = space_state.intersect_ray(start, end, [self] + ignored_objects)
	results.push_back(result)
	return result.position if result else end

func draw_tracer(end):
	var tracer = Tracer.instance()
	tracer.instantiate(muzzle.global_transform.origin, end)
	muzzle.add_child(tracer)
