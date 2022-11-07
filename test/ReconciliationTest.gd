extends KinematicBody

var moves = []
var rng = RandomNumberGenerator.new()

#func _ready():
#	rng.randomize()

func add_moves():
	for i in 5:
		var random_move = Vector3(
			rng.randf_range(0, 5), 
			rng.randf_range(-2, 2), 
			rng.randf_range(0, 5)
		)
		for j in 5:
			moves.append(random_move)

var last_moves = moves
var pos_at_begin = transform.origin
func _physics_process(delta):
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
		add_moves()
		last_moves = moves.duplicate()
		pos_at_begin = transform.origin
	if Input.is_action_just_pressed("alt_click"):
		transform.origin = pos_at_begin
		force_update_transform()
		for i in range(last_moves.size() - 1, -1, -1):
			move_and_slide_with_snap(last_moves[i], Vector3.DOWN)
		print("Final sim position: %s" % transform.origin)
