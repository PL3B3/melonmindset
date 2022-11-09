extends KinematicBody

var speed:float = 10
var moves = []
var moves_idx = 0
var moves_count = 10
var repeat_count = 10
var last_moves = moves
var rng = RandomNumberGenerator.new()
onready var default_phys_ticks = Engine.iterations_per_second
onready var pos_at_begin = transform.origin

func _ready():
	rng.randomize()
	moves = get_moves(moves_count, repeat_count)

func get_moves(num_moves, repeats):
	var result = []
	for i in range(0, num_moves):
		var random_move = Vector3(
			rng.randf_range(-speed, speed), 
			rng.randf_range(-speed, speed),
			rng.randf_range(-speed, speed)
		)
		for j in repeats:
			result.append(random_move)
	return result

func _physics_process(delta):
	test_delta_compensation()

var p0 = Vector3()
var phase = 0
func test_delta_compensation():
	if moves_idx < moves.size():
		var delta_compensation = Engine.iterations_per_second / float(default_phys_ticks)
		var move = moves[moves_idx]
		move_and_slide_with_snap(move * delta_compensation, Vector3.DOWN)
		moves_idx += 1
		if moves_idx == moves.size():
			print("Move position at rate %s: %s" % [Engine.iterations_per_second, transform.origin])
			if phase == 0:
				Engine.iterations_per_second = 60
				p0 = transform.origin
				transform.origin = pos_at_begin
				force_update_transform()
				moves_idx = 0
				phase = 1
			else:
				print("Discrepancy: %s" % [(transform.origin - p0).length()])
				Engine.iterations_per_second = 100
				pos_at_begin = transform.origin
				moves = get_moves(moves_count, repeat_count)
				moves_idx = 0
				phase = 0

func simulate_move():
	if moves_idx < moves.size():
		var move = moves[moves_idx]
		moves_idx += 1

func test_reconciliation():
	if not moves.empty():
		move_and_slide_with_snap(moves.pop_back(), Vector3.DOWN)
		if moves.empty():
			var final_position = transform.origin
			print("Move position: %s" % transform.origin)
			transform.origin = pos_at_begin
			force_update_transform()
			for i in range(last_moves.size() - 1, -1, -1):
				move_and_slide_with_snap(last_moves[i], Vector3.DOWN)
			print("Calc position: %s" % transform.origin)
			print("Discrepancy: %s" % (transform.origin - final_position).length())
	if Input.is_action_just_pressed("click"):
		moves = get_moves(moves_count, repeat_count)
		last_moves = moves.duplicate()
		pos_at_begin = transform.origin
