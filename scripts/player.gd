class_name ActionRPGPlayer
extends CharacterBody3D

@export var stats: PlayerStats = PlayerStats.new()

const CAMERA_DISTANCE: float = 7.5
const CAMERA_HEIGHT: float = 2.4
const CAMERA_SENSITIVITY: float = 0.012
const BASE_JUMP_VELOCITY: float = 7.0

var touch_move: Vector2 = Vector2.ZERO
var camera_yaw: float = 0.0
var camera_pitch: float = -0.20
var attack_cooldown: float = 0.0
var attack_flash_time: float = 0.0
var current_jump_velocity: float = BASE_JUMP_VELOCITY
var attack_interval: float = 0.42

var visual: MeshInstance3D
var camera_rig: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var attack_marker: MeshInstance3D

func _ready() -> void:
	_build_player_nodes()
	_apply_camera_rotation()
	if stats != null:
		stats.stat_changed.connect(_on_stat_changed)
		_sync_derived_stats()

func _build_player_nodes() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.35
	
	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.48
	capsule_shape.height = 1.9
	collision.shape = capsule_shape
	collision.position.y = 0.95
	add_child(collision)
	
	visual = MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.48
	capsule_mesh.height = 1.9
	capsule_mesh.radial_segments = 16
	capsule_mesh.rings = 8
	visual.mesh = capsule_mesh
	visual.position.y = 0.95
	visual.material_override = _make_material(Color("#3b82f6"), 0.15)
	add_child(visual)
	
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.34
	head_mesh.height = 0.68
	head.mesh = head_mesh
	head.position = Vector3(0.0, 2.05, 0.0)
	head.material_override = _make_material(Color("#f2c6a0"), 0.0)
	add_child(head)
	
	camera_rig = Node3D.new()
	camera_rig.name = "CameraRig"
	camera_rig.position = Vector3(0.0, CAMERA_HEIGHT, 0.0)
	add_child(camera_rig)
	
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	spring_arm.spring_length = CAMERA_DISTANCE
	spring_arm.margin = 0.25
	spring_arm.collision_mask = 1
	camera_rig.add_child(spring_arm)
	
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 68.0
	spring_arm.add_child(camera)
	
	attack_marker = MeshInstance3D.new()
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(0.18, 0.18, 1.35)
	attack_marker.mesh = marker_mesh
	attack_marker.position = Vector3(0.0, 1.0, -0.85)
	attack_marker.material_override = _make_material(Color("#facc15"), 0.0)
	attack_marker.visible = false
	add_child(attack_marker)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	attack_flash_time = maxf(attack_flash_time - delta, 0.0)
	attack_marker.visible = attack_flash_time > 0.0
	
	var input_vector := _get_movement_input()
	var camera_basis := camera.global_transform.basis
	var forward := -camera_basis.z
	var right := camera_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var movement := (right * input_vector.x + forward * input_vector.y)
	if movement.length_squared() > 1.0:
		movement = movement.normalized()
	
	var target_speed := stats.get_move_speed()
	velocity.x = move_toward(velocity.x, movement.x * target_speed, 30.0 * delta)
	velocity.z = move_toward(velocity.z, movement.z * target_speed, 30.0 * delta)
	if movement.length_squared() > 0.01:
		var target_angle := atan2(movement.x, movement.z)
		rotation.y = lerp_angle(rotation.y, target_angle, minf(delta * 12.0, 1.0))
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = current_jump_velocity
	else:
		velocity.y -= get_gravity().length() * delta
	
	if Input.is_action_just_pressed("attack"):
		basic_attack()
	move_and_slide()
	
	if attack_flash_time > 0.0:
		attack_marker.rotation.y = sin(attack_flash_time * 24.0) * 0.8

func _get_movement_input() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var combined := keyboard + touch_move
	return combined.limit_length(1.0)

func basic_attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = attack_interval
	attack_flash_time = 0.22
	stats.sword_skill += 0.1

func rotate_camera_by(delta_pixels: Vector2) -> void:
	camera_yaw -= delta_pixels.x * CAMERA_SENSITIVITY
	camera_pitch = clampf(camera_pitch - delta_pixels.y * CAMERA_SENSITIVITY, -0.95, 0.35)
	_apply_camera_rotation()

func _on_stat_changed(_stat_name: String, _new_value: int) -> void:
	_sync_derived_stats()

func _sync_derived_stats() -> void:
	if stats == null:
		return
	current_jump_velocity = BASE_JUMP_VELOCITY + float(maxi(stats.agility - 1, 0)) * 0.4
	attack_interval = maxf(0.16, 0.42 - float(maxi(stats.agility - 1, 0)) * 0.025)
	# Movement speed is read from stats every physics frame, so Speed is immediate.

func _apply_camera_rotation() -> void:
	if camera_rig == null:
		return
	camera_rig.rotation = Vector3(camera_pitch, camera_yaw, 0.0)

func _make_material(color: Color, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.72
	return material
