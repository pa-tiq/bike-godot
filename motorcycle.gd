extends CharacterBody2D
class_name Motorcycle

# Signals (Observer pattern)
signal speed_changed(new_speed: float)
signal crashed
signal position_updated(new_position: Vector2)

# Physics properties
@export var max_speed: float = 500.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0
@export var jump_force: float = 400.0

var current_speed: float = 0.0
var is_on_ground: bool = true

func _ready():
	# Set up camera to follow
	$Camera2D.enabled = true
	
	# Create a placeholder red square texture
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	
	var texture := ImageTexture.create_from_image(image)
	$Sprite2D.texture = texture

func _physics_process(delta):
	handle_input(delta)
	apply_physics(delta)
	move_and_slide()
	
	# Emit signals for observers
	speed_changed.emit(current_speed)
	position_updated.emit(global_position)

func handle_input(delta: float):
	var input_dir = Input.get_axis("ui_left", "ui_right")
	
	if input_dir != 0:
		current_speed = move_toward(current_speed, max_speed * input_dir, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, 0, friction * delta)
	
	if Input.is_action_just_pressed("ui_accept") and is_on_ground:
		velocity.y = -jump_force

func apply_physics(delta: float):
	velocity.x = current_speed
	velocity.y += get_gravity().y * delta
	
	is_on_ground = is_on_floor()
