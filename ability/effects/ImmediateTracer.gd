extends Spatial

var fire_line_mesh
var fire_line_clear_timer

var fire_mode_settings
var fire_mode_phys_processing = [false, false, false]
var velocity_push_factor_universal = 10

func _ready():
	fire_line_clear_timer = Timer.new()
	fire_line_clear_timer.set_one_shot(true)
	fire_line_clear_timer.connect("timeout", self, "_clear_fire_lines")
	add_child(fire_line_clear_timer)
	fire_line_mesh = ImmediateGeometry.new()
	var line_material = SpatialMaterial.new()
	line_material.set_albedo(Color.gold)
	line_material.set_feature(SpatialMaterial.FEATURE_EMISSION, true)
	line_material.set_emission(Color.orange)
	fire_line_mesh.set_material_override(line_material)


func create_fire_lines_representation(origin, fire_lines):
	if not fire_lines:
		return
	var verts = PoolVector3Array()
	if not get_node("/root").has_node(fire_line_mesh.name):
		get_node("/root").add_child(fire_line_mesh)
	
	for line in fire_lines:
		verts.append(origin)
		verts.append(origin + line)
	fire_line_mesh.begin(Mesh.PRIMITIVE_LINES)
	for vert in verts:
		fire_line_mesh.add_vertex(vert)
	fire_line_mesh.end()
	fire_line_clear_timer.start(0.05)


func _clear_fire_lines():
	fire_line_mesh.clear()
	get_node("/root").remove_child(fire_line_mesh)

