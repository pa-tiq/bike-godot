extends RigidBody2D
class_name Motorcycle

# Signals (Observer pattern)
signal speed_changed(new_speed: float)
signal crashed
signal position_updated(new_position: Vector2)

# Motorcycle properties
@export var wheel_torque: float = 2000.0
@export var max_wheel_speed: float = 20.0
@export var suspension_strength: float = 1000.0
@export var suspension_damping: float = 50.0

# Wheel references
@onready var back_wheel: RigidBody2D = $BackWheel
@onready var front_wheel: RigidBody2D = $FrontWheel
@onready var back_joint: PinJoint2D = $BackWheel/WheelJoint
@onready var front_joint: PinJoint2D = $FrontWheel/WheelJoint

var current_speed: float = 0.0
var wheel_input: float = 0.0

func _ready():
	# Set up camera to follow
	$Camera2D.enabled = true
	
	# Create motorcycle body texture (red rectangle)
	create_body_texture()
	
	# Create wheel textures and setup
	setup_wheels()
	
	# Configure physics
	gravity_scale = 1.0
	lock_rotation = false  # Allow motorcycle to rotate
	
	# Set up joints
	setup_wheel_joints()

func create_body_texture():
	var image := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	var texture := ImageTexture.create_from_image(image)
	$Sprite2D.texture = texture

func setup_wheels():
	# Create wheel textures (black circles)
	var wheel_image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	wheel_image.fill(Color.TRANSPARENT)
	
	# Draw a black circle
	for y in range(24):
		for x in range(24):
			var distance = Vector2(x - 12, y - 12).length()
			if distance <= 12:
				wheel_image.set_pixel(x, y, Color.BLACK)
	
	var wheel_texture := ImageTexture.create_from_image(wheel_image)
	
	# Set wheel textures
	back_wheel.get_node("Sprite2D").texture = wheel_texture
	front_wheel.get_node("Sprite2D").texture = wheel_texture
	
	# Position wheels relative to motorcycle body
	back_wheel.position = Vector2(-20, 20)  # Back and below
	front_wheel.position = Vector2(20, 20)  # Front and below
	
	# Set up wheel collision shapes (circles)
	var wheel_shape = CircleShape2D.new()
	wheel_shape.radius = 12
	
	back_wheel.get_node("CollisionShape2D").shape = wheel_shape
	front_wheel.get_node("CollisionShape2D").shape = wheel_shape
	
	# Configure wheel physics
	back_wheel.gravity_scale = 1.0
	front_wheel.gravity_scale = 1.0
	
	# Set wheel mass (lighter than main body)
	back_wheel.mass = 0.5
	front_wheel.mass = 0.5

func setup_wheel_joints():
	# Connect wheels to motorcycle body with PinJoints
	back_joint.node_a = get_path()
	back_joint.node_b = back_wheel.get_path()
	back_joint.position = Vector2(-20, 20)
	
	front_joint.node_a = get_path()
	front_joint.node_b = front_wheel.get_path()
	front_joint.position = Vector2(20, 20)

func _process(delta):
	handle_input()
	apply_wheel_physics(delta)
	
	# Update speed for observers
	current_speed = linear_velocity.length()
	speed_changed.emit(current_speed)
	position_updated.emit(global_position)

func handle_input():
	# Get left/right input
	wheel_input = Input.get_axis("ui_left", "ui_right")

func apply_wheel_physics(delta):
	if wheel_input != 0 and back_wheel_touching_ground():
		# Apply torque to back wheel only
		var torque_force = wheel_input * wheel_torque
		
		# Calculate the force direction based on wheel contact
		var wheel_contact_normal = get_wheel_ground_normal(back_wheel)
		if wheel_contact_normal != Vector2.ZERO:
			# Apply force tangent to the ground surface
			var forward_direction = Vector2(-wheel_contact_normal.y, wheel_contact_normal.x)
			if wheel_input < 0:  # Reverse
				forward_direction = -forward_direction
			
			# Apply force to both motorcycle and wheel
			var force = forward_direction * abs(torque_force) * delta
			apply_force(force * 2)  # Apply to motorcycle body
			back_wheel.apply_force(force)  # Apply to wheel
			
			# Add some angular velocity to the back wheel for visual effect
			back_wheel.angular_velocity = wheel_input * max_wheel_speed
	
	# Front wheel rotates based on contact and movement (no traction)
	if front_wheel_touching_ground() and linear_velocity.length() > 0.1:
		var wheel_rotation_speed = linear_velocity.x / 12.0  # 12 is wheel radius
		front_wheel.angular_velocity = wheel_rotation_speed

func back_wheel_touching_ground() -> bool:
	return is_wheel_touching_ground(back_wheel)

func front_wheel_touching_ground() -> bool:
	return is_wheel_touching_ground(front_wheel)

func is_wheel_touching_ground(wheel: RigidBody2D) -> bool:
	# Check if wheel is in contact with ground
	var space_state = wheel.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		wheel.global_position,
		wheel.global_position + Vector2(0, 15)  # Ray down from wheel center
	)
	var result = space_state.intersect_ray(query)
	return result.size() > 0

func get_wheel_ground_normal(wheel: RigidBody2D) -> Vector2:
	var space_state = wheel.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		wheel.global_position,
		wheel.global_position + Vector2(0, 15)
	)
	var result = space_state.intersect_ray(query)
	if result.size() > 0:
		return result.normal
	return Vector2.ZERO

func _on_body_entered(body: Node):
	if body.name == "Ground":
		return  # Normal ground contact
	else:
		# Hit an obstacle
		crashed.emit()
