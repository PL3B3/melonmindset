extends Spatial

onready var body = get_node("KinematicBody")

func _ready():
    var a := Vector3(-0.18, -0.7, 0.95).normalized()
    var b := Vector3(15, 2, -5).normalized()
    print(a)
    print(b)
    print(a.cross(b).cross(b).cross(b).cross(b).normalized())

func _physics_process(delta):
    if Input.is_action_just_pressed("ability_0"):
        body.transform.origin = Vector3(0, 2, 0)
        body.force_update_transform()
        body.move_and_slide_with_snap(Vector3.ZERO, Vector3.ZERO, Vector3.UP)
        print("Before: %s" % body.is_on_floor())
        body.move_and_slide_with_snap(Vector3.DOWN * 2 * (1.0 / delta), Vector3.ZERO, Vector3.UP)
        print("After : %s" % body.is_on_floor())
