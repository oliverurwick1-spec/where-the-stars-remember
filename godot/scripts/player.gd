extends CharacterBody3D

@export var move_speed: float = 4.8
@export var turn_speed: float = 11.0
@export var camera_pivot: Node3D
@export var camera: Camera3D

var gravity: float = 18.0
var mouse_sensitivity: float = 0.0026
var pitch: float = -0.20
var yaw: float = 0.0

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    yaw = rotation.y
    _update_camera_rotation()

func _unhandled_input(event) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * mouse_sensitivity
        pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -0.58, 0.08)
        _update_camera_rotation()
    elif event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2

    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var cam_forward := -camera.global_transform.basis.z
    cam_forward.y = 0.0
    cam_forward = cam_forward.normalized()
    var cam_right := camera.global_transform.basis.x
    cam_right.y = 0.0
    cam_right = cam_right.normalized()

    var direction := cam_right * input_vec.x + cam_forward * -input_vec.y
    if direction.length() > 0.01:
        direction = direction.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        var target_yaw := atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.5 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.5 * delta)

    move_and_slide()

func _update_camera_rotation() -> void:
    if camera_pivot:
        camera_pivot.rotation.y = yaw
        camera_pivot.rotation.x = pitch
