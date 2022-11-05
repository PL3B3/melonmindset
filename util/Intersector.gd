extends Reference

class_name Intersector

static func intersect_ray_sphere(ray_start:Vector3, ray_end:Vector3, 
sphere_pos:Vector3, sphere_radius:float) -> float:
	"""
		ray_start and ray_end are determined by a physics space raycast only
		detecting map geometry.
		sphere_pos should be the position of other player @ tick of fire
	"""
	var distance := -1.0
	
	var sphere_radius_sqr = sphere_radius * sphere_radius
	
	var ray = ray_end - ray_start
	var ray_sqr = ray.length_squared()
	
	var sphere_offset = sphere_pos - ray_start
	var dot = sphere_offset.dot(ray)
	
	if dot > 0:
		var projection = sphere_offset.project(ray)
		var projection_sqr = projection.length_squared()
		
		var sphere_to_ray = projection - sphere_offset
		var sphere_to_ray_sqr = sphere_to_ray.length_squared()
		
		if (sphere_to_ray_sqr < sphere_radius_sqr && 
		projection_sqr < ray_sqr):
			distance = projection_sqr
	
	return distance

static func get_closest_sphere_hit_by_ray(ray_start:Vector3, ray_end:Vector3, 
spheres:Dictionary):
	"""
		spheres is a {sphere_id : [Vector3 position, float radius]}
		where sphere_id >= 0
	"""
	
	var min_distance := -1.0
	var min_id := -1
	
	var ray = ray_end - ray_start
	var ray_sqr = ray.length_squared()
	
	for sphere_id in spheres:
		var sphere_pos = spheres[sphere_id][0]
		var sphere_radius = spheres[sphere_id][1]
		var sphere_radius_sqr = sphere_radius * sphere_radius
		
		var sphere_offset = sphere_pos - ray_start
		var dot = sphere_offset.dot(ray)
	
		if dot > 0:
			var projection = sphere_offset.project(ray)
			var projection_sqr = projection.length_squared()
			
			var sphere_to_ray = projection - sphere_offset
			var sphere_to_ray_sqr = sphere_to_ray.length_squared()
			
			# if our projection is within ray range and inside the sphere
			# and the hit is closer than any that came before it
			if (sphere_to_ray_sqr < sphere_radius_sqr && projection_sqr < ray_sqr &&
			(projection_sqr < min_distance || min_distance == -1.0)):
				min_distance = projection_sqr
				min_id = sphere_id
	
	return min_id
