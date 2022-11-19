extends Spatial

onready var Target = preload("res://test/KinematicTarget.tscn")
var target:KinematicBody
var targets = []

func _ready():
    target = Target.instance()
    target.set_as_toplevel(true)
    add_child(target)
#    for i in 40:
#        var t = Target.instance()
#        add_child(t)
#        t.hide()
#        targets.append(t)

#func _process(delta):
#	for i in 10:
#		targets[i].collider.disabled = true
#		targets[i].collider.disabled = false

#var casting = false
#func _unhandled_input(event):
#    if event.is_action_pressed("click"):
#        target.transform.origin = Vector3(0, 5, 0)
#        target.force_update_transform()
#        casting = true

func _physics_process(delta):
    for t in targets:
        t.transform.origin = Vector3(0, 5, 0)
        t.force_update_transform()
        t.get_node("CollisionShape").disabled = true
        t.get_node("CollisionShape").disabled = false
        
    

    if Input.is_action_just_pressed("click"):
        target.transform.origin = Vector3(0, 4, 0)
        target.move_and_slide(Vector3(0, 1.0 / delta, 0))
        target.force_update_transform()
        print(target.transform.origin)
#        target.get_node("CollisionShape").disabled = true
#        target.get_node("CollisionShape").disabled = false
        var space_state = get_world().direct_space_state
        var ray_start = Vector3(5, 5, 0)
        var ray_end = Vector3(0, 5, 0)
        var result = space_state.intersect_ray(ray_start, ray_end)
        if result and is_instance_valid(result.collider):
            print("Hit ", result.collider)
        else:
            print("no hit")
        target.transform.origin = Vector3()
