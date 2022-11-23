extends Spatial

var query_shape := CylinderShape.new()
var shape_query = PhysicsShapeQueryParameters.new()

func _ready():
    shape_query.exclude = [self]
    shape_query.set_shape(query_shape)
    shape_query.transform.origin = global_transform.origin


func _physics_process(delta):
    for i in 100:
        collide_shape()

func collide_shape():
    var space_state = get_world().direct_space_state
    shape_query.exclude = [self]
    for i in 4:
        var result = space_state.get_rest_info(shape_query)
        if result:
            shape_query.exclude = shape_query.exclude + [result.rid]
        else:
            break
