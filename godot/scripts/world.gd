extends Node3D

@export var player: CharacterBody3D
@export var dead_ground: MeshInstance3D
@export var world_environment: WorldEnvironment

const PLANET_RADIUS := 20.0

var rng := RandomNumberGenerator.new()
var rocks: Array[Node3D] = []

func _ready() -> void:
    rng.seed = 1307
    _build_rock_scatter()

func _surface_point(x: float, z: float, lift: float = 0.0) -> Vector3:
    var rr: float = x * x + z * z
    var y: float = sqrt(maxf(0.0, PLANET_RADIUS * PLANET_RADIUS - rr))
    var p := Vector3(x, y, z)
    return p.normalized() * (PLANET_RADIUS + lift)

func _align_to_surface(node: Node3D, normal: Vector3) -> void:
    var forward := Vector3.FORWARD
    if absf(forward.dot(normal)) > 0.92:
        forward = Vector3.RIGHT
    forward = (forward - normal * forward.dot(normal)).normalized()
    var right := normal.cross(forward).normalized()
    forward = right.cross(normal).normalized()
    node.global_transform.basis = Basis(right, normal, forward)

func _mat(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.94
    return mat

func _build_rock_scatter() -> void:
    var rock_mat := _mat(Color("514a55"))
    for i in range(70):
        var angle: float = rng.randf_range(0.0, TAU)
        var radius: float = rng.randf_range(4.0, 18.0)
        var rock := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.18, 0.62)
        mesh.height = mesh.radius * 1.45
        rock.mesh = mesh
        rock.material_override = rock_mat
        rock.global_position = _surface_point(cos(angle) * radius, sin(angle) * radius, mesh.radius * 0.28)
        rock.scale = Vector3(rng.randf_range(0.7, 1.5), rng.randf_range(0.45, 0.85), rng.randf_range(0.75, 1.45))
        add_child(rock)
        _align_to_surface(rock, rock.global_position.normalized())
        rocks.append(rock)
