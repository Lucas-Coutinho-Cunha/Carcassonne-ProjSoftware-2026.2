extends Camera3D
## Orthogonal camera looking straight down. Screen up = -Z = tile north.
## Mouse wheel zooms, middle-mouse drag pans.

@export var start_size := 14.0
@export var min_size := 6.0
@export var max_size := 40.0


func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = start_size  # vertical extent of the view in world units
	near = 0.1
	far = 100.0
	position = Vector3(0, 30, 0)
	rotation_degrees = Vector3(-90, 0, 0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			size = maxf(min_size, size * 0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			size = minf(max_size, size * 1.1)
		return
	var mm := event as InputEventMouseMotion
	if mm != null and (mm.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		var world_per_pixel := size / get_viewport().get_visible_rect().size.y
		position += Vector3(-mm.relative.x, 0.0, -mm.relative.y) * world_per_pixel
