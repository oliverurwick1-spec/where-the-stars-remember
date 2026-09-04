extends CharacterBody3D

@export var move_speed: float = 6.2
@export var turn_speed: float = 10.0
@export var camera_pivot: Node3D
@export var camera: Camera3D

const PLANET_CENTER := Vector3.ZERO
const PLANET_RADIUS := 20.0

var gravity_strength: float = 28.0
var mouse_sensitivity: float = 0.0022
var orbit_yaw: float = 0.0
var orbit_pitch: float = -0.22
var zoom_distance: float = 7.2
var min_zoom: float = 3.8
var max_zoom: float = 58.0
var visual_forward_offset: float = PI
var walk_time: float = 0.0

@onready var girl: Node3D = get_node_or_null("Girl") as Node3D
@onready var arm_l: Node3D = get_node_or_null("Girl/ArmLPivot") as Node3D
@onready var arm_r: Node3D = get_node_or_null("Girl/ArmRPivot") as Node3D
@onready var leg_l: Node3D = get_node_or_null("Girl/LegLPivot") as Node3D
@onready var leg_r: Node3D = get_node_or_null("Girl/LegRPivot") as Node3D
@onready var foot_l: Node3D = get_node_or_null("Girl/LegLPivot/LowerLeg/Foot") as Node3D
@onready var foot_r: Node3D = get_node_or_null("Girl/LegRPivot/LowerLeg/Foot") as Node3D
@onready var skirt: Node3D = get_node_or_null("Girl/Skirt") as Node3D
@onready var hair_l: Node3D = get_node_or_null("Girl/HairLeft") as Node3D
@onready var hair_r: Node3D = get_node_or_null("Girl/HairRight") as Node3D
@onready var teddy: Node3D = get_node_or_null("Girl/Teddy") as Node3D
@onready var teddy_arm: Node3D = get_node_or_null("Girl/Teddy/ArmWave") as Node3D
@onready var teddy_ear_l: Node3D = get_node_or_null("Girl/Teddy/EarL") as Node3D
@onready var teddy_ear_r: Node3D = get_node_or_null("Girl/Teddy/EarR") as Node3D

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if camera:
        camera.top_level = true
    if camera_pivot:
        camera_pivot.visible = false

func _unhandled_input(event) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        orbit_yaw -= event.relative.x * mouse_sensitivity
        orbit_pitch = clampf(orbit_pitch - event.relative.y * mouse_sensitivity, -0.85, 0.35)
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_distance = maxf(min_zoom, zoom_distance - 2.4)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_distance = minf(max_zoom, zoom_distance + 3.2)
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    var up: Vector3 = (global_position - PLANET_CENTER).normalized()
    up_direction = up

    var radial_velocity: float = velocity.dot(up)
    var tangential_velocity: Vector3 = velocity - up * radial_velocity

    var cam_forward: Vector3 = -camera.global_transform.basis.z
    cam_forward = (cam_forward - up * cam_forward.dot(up)).normalized()
    if cam_forward.length_squared() < 0.01:
        cam_forward = transform.basis.z.cross(up).normalized()
    var cam_right: Vector3 = cam_forward.cross(up).normalized()

    var input_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction: Vector3 = cam_right * input_vec.x + cam_forward * -input_vec.y
    var moving: bool = direction.length_squared() > 0.01

    if moving:
        direction = direction.normalized()
        tangential_velocity = tangential_velocity.lerp(direction * move_speed, 1.0 - exp(-10.0 * delta))
        _face_direction(direction, up, delta)
    else:
        tangential_velocity = tangential_velocity.lerp(Vector3.ZERO, 1.0 - exp(-10.0 * delta))

    radial_velocity -= gravity_strength * delta
    velocity = tangential_velocity + up * radial_velocity
    move_and_slide()

    var speed_ratio: float = clampf(tangential_velocity.length() / move_speed, 0.0, 1.0)
    _animate_character(delta, speed_ratio)
    _update_camera(delta)

func _animate_character(delta: float, speed_ratio: float) -> void:
    walk_time += delta * lerpf(2.2, 8.7, speed_ratio)
    var stride: float = sin(walk_time) * 0.62 * speed_ratio
    var knee: float = maxf(0.0, -sin(walk_time)) * 0.28 * speed_ratio
    var idle: float = sin(Time.get_ticks_msec() * 0.0022)

    if arm_l:
        arm_l.rotation.x = lerpf(arm_l.rotation.x, -stride * 0.72, 0.18)
        arm_l.rotation.z = -0.10
    if arm_r:
        arm_r.rotation.x = lerpf(arm_r.rotation.x, stride * 0.52, 0.18)
        arm_r.rotation.z = 0.23
    if leg_l:
        leg_l.rotation.x = lerpf(leg_l.rotation.x, stride, 0.22)
    if leg_r:
        leg_r.rotation.x = lerpf(leg_r.rotation.x, -stride, 0.22)
    if foot_l:
        foot_l.rotation.x = knee
    if foot_r:
        foot_r.rotation.x = maxf(0.0, sin(walk_time)) * 0.28 * speed_ratio
    if girl:
        girl.position.y = absf(sin(walk_time * 2.0)) * 0.035 * speed_ratio + idle * 0.012
        girl.rotation.z = sin(walk_time) * 0.018 * speed_ratio
    if skirt:
        skirt.rotation.z = sin(walk_time + 0.5) * 0.025 * speed_ratio
    if hair_l:
        hair_l.rotation.x = -stride * 0.05 + idle * 0.02
    if hair_r:
        hair_r.rotation.x = stride * 0.05 - idle * 0.02

    if teddy:
        teddy.rotation.z = -0.13 + sin(walk_time * 1.25) * 0.05 * speed_ratio + idle * 0.025
        teddy.rotation.x = sin(walk_time * 1.6) * 0.035 * speed_ratio
        teddy.position.y = 1.56 + absf(sin(walk_time * 2.0 + 0.8)) * 0.025 * speed_ratio
    if teddy_arm:
        teddy_arm.rotation.z = -0.55 + sin(Time.get_ticks_msec() * 0.004) * 0.18
    if teddy_ear_l:
        teddy_ear_l.rotation.z = sin(Time.get_ticks_msec() * 0.003) * 0.08
    if teddy_ear_r:
        teddy_ear_r.rotation.z = -sin(Time.get_ticks_msec() * 0.003) * 0.08

func _face_direction(direction: Vector3, up: Vector3, delta: float) -> void:
    var desired_forward: Vector3 = -direction
    var desired_right: Vector3 = up.cross(desired_forward).normalized()
    desired_forward = desired_right.cross(up).normalized()
    var desired_basis: Basis = Basis(desired_right, up, desired_forward).rotated(up, visual_forward_offset)
    var current_q: Quaternion = Quaternion(global_transform.basis.orthonormalized())
    var target_q: Quaternion = Quaternion(desired_basis.orthonormalized())
    global_transform.basis = Basis(current_q.slerp(target_q, 1.0 - exp(-turn_speed * delta)))

func _update_camera(delta: float) -> void:
    if not camera:
        return

    var up: Vector3 = (global_position - PLANET_CENTER).normalized()
    var reference_forward: Vector3 = Vector3.FORWARD
    if absf(reference_forward.dot(up)) > 0.92:
        reference_forward = Vector3.RIGHT
    reference_forward = (reference_forward - up * reference_forward.dot(up)).normalized()

    var orbit_basis: Basis = Basis(up, orbit_yaw)
    var tangent_forward: Vector3 = orbit_basis * reference_forward
    var tangent_right: Vector3 = tangent_forward.cross(up).normalized()
    tangent_forward = Basis(tangent_right, orbit_pitch) * tangent_forward

    var zoom_t: float = clampf((zoom_distance - 14.0) / (max_zoom - 14.0), 0.0, 1.0)
    zoom_t = smoothstep(0.0, 1.0, zoom_t)

    var close_target: Vector3 = global_position + up * 1.35
    var target: Vector3 = close_target.lerp(PLANET_CENTER, zoom_t)
    var close_pos: Vector3 = close_target - tangent_forward * zoom_distance + up * 0.8
    var orbit_dir: Vector3 = (up * 0.52 - tangent_forward * 0.86).normalized()
    var far_pos: Vector3 = PLANET_CENTER + orbit_dir * zoom_distance
    var desired_pos: Vector3 = close_pos.lerp(far_pos, zoom_t)

    camera.global_position = camera.global_position.lerp(desired_pos, 1.0 - exp(-9.0 * delta))
    var desired_up: Vector3 = up.lerp(Vector3.UP, zoom_t).normalized()
    camera.look_at(target, desired_up)
