extends Node3D

@export var player: CharacterBody3D
@export var dead_ground: MeshInstance3D
@export var world_environment: WorldEnvironment

const PLANET_RADIUS := 20.0

var rng := RandomNumberGenerator.new()
var rocks: Array[Node3D] = []
var crows: Array[Node3D] = []
var strange_growths: Array[Node3D] = []

func _ready() -> void:
    rng.seed = 1307
    _build_rock_scatter()
    _build_dead_grove()
    _build_strange_growths()
    _build_crows()

func _process(delta: float) -> void:
    var time: float = Time.get_ticks_msec() * 0.001
    _animate_crows(time, delta)
    _animate_growths(time)

func _surface_point(x: float, z: float, lift: float = 0.0) -> Vector3:
    var rr: float = x * x + z * z
    var y: float = sqrt(maxf(0.0, PLANET_RADIUS * PLANET_RADIUS - rr))
    var p: Vector3 = Vector3(x, y, z)
    return p.normalized() * (PLANET_RADIUS + lift)

func _align_to_surface(node: Node3D, normal: Vector3) -> void:
    var forward: Vector3 = Vector3.FORWARD
    if absf(forward.dot(normal)) > 0.92:
        forward = Vector3.RIGHT
    forward = (forward - normal * forward.dot(normal)).normalized()
    var right: Vector3 = normal.cross(forward).normalized()
    forward = right.cross(normal).normalized()
    node.global_transform.basis = Basis(right, normal, forward)

func _mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.94
    if emission > 0.0:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = emission
    return mat

func _build_rock_scatter() -> void:
    var rock_mat: StandardMaterial3D = _mat(Color("494550"))
    for i in range(110):
        var angle: float = rng.randf_range(0.0, TAU)
        var radius: float = rng.randf_range(3.0, 18.5)
        var rock: MeshInstance3D = MeshInstance3D.new()
        var mesh: SphereMesh = SphereMesh.new()
        mesh.radius = rng.randf_range(0.12, 0.58)
        mesh.height = mesh.radius * 1.45
        rock.mesh = mesh
        rock.material_override = rock_mat
        rock.global_position = _surface_point(cos(angle) * radius, sin(angle) * radius, mesh.radius * 0.22)
        rock.scale = Vector3(rng.randf_range(0.65, 1.55), rng.randf_range(0.38, 0.82), rng.randf_range(0.7, 1.4))
        add_child(rock)
        _align_to_surface(rock, rock.global_position.normalized())
        rocks.append(rock)

func _build_dead_grove() -> void:
    var trunk_mat: StandardMaterial3D = _mat(Color("2d292f"))
    for i in range(26):
        var angle: float = rng.randf_range(0.0, TAU)
        var radius: float = rng.randf_range(5.0, 18.0)
        var tree: Node3D = Node3D.new()
        tree.global_position = _surface_point(cos(angle) * radius, sin(angle) * radius, 0.0)
        add_child(tree)
        _align_to_surface(tree, tree.global_position.normalized())
        tree.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))

        var trunk: MeshInstance3D = MeshInstance3D.new()
        var tm: CylinderMesh = CylinderMesh.new()
        tm.top_radius = rng.randf_range(0.07, 0.13)
        tm.bottom_radius = rng.randf_range(0.20, 0.34)
        tm.height = rng.randf_range(1.8, 3.4)
        trunk.mesh = tm
        trunk.material_override = trunk_mat
        trunk.position.y = tm.height * 0.5
        trunk.rotation.z = rng.randf_range(-0.18, 0.18)
        tree.add_child(trunk)

        for j in range(4):
            var branch: MeshInstance3D = MeshInstance3D.new()
            var bm: CylinderMesh = CylinderMesh.new()
            bm.top_radius = 0.025
            bm.bottom_radius = rng.randf_range(0.05, 0.09)
            bm.height = rng.randf_range(0.75, 1.35)
            branch.mesh = bm
            branch.material_override = trunk_mat
            branch.position = Vector3(0, tm.height * rng.randf_range(0.45, 0.90), 0)
            branch.rotation = Vector3(rng.randf_range(-0.2, 0.2), j * 1.55 + rng.randf_range(-0.35, 0.35), rng.randf_range(0.75, 1.20))
            tree.add_child(branch)

func _build_strange_growths() -> void:
    var stem_mat: StandardMaterial3D = _mat(Color("34303d"))
    var eye_mat: StandardMaterial3D = _mat(Color("57415f"), 0.22)
    for i in range(48):
        var angle: float = rng.randf_range(0.0, TAU)
        var radius: float = rng.randf_range(2.5, 18.0)
        var growth: Node3D = Node3D.new()
        growth.global_position = _surface_point(cos(angle) * radius, sin(angle) * radius, 0.0)
        add_child(growth)
        _align_to_surface(growth, growth.global_position.normalized())
        growth.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))

        var stalk: MeshInstance3D = MeshInstance3D.new()
        var stalk_mesh: CylinderMesh = CylinderMesh.new()
        stalk_mesh.top_radius = rng.randf_range(0.025, 0.055)
        stalk_mesh.bottom_radius = rng.randf_range(0.06, 0.11)
        stalk_mesh.height = rng.randf_range(0.5, 1.35)
        stalk.mesh = stalk_mesh
        stalk.material_override = stem_mat
        stalk.position.y = stalk_mesh.height * 0.5
        stalk.rotation.z = rng.randf_range(-0.30, 0.30)
        growth.add_child(stalk)

        var pod: MeshInstance3D = MeshInstance3D.new()
        var pod_mesh: SphereMesh = SphereMesh.new()
        pod_mesh.radius = rng.randf_range(0.10, 0.20)
        pod_mesh.height = pod_mesh.radius * 1.7
        pod.mesh = pod_mesh
        pod.material_override = eye_mat
        pod.position = Vector3(0, stalk_mesh.height + 0.05, 0)
        pod.scale = Vector3(0.7, 1.15, 0.7)
        growth.add_child(pod)

        for j in range(3):
            var tendril: MeshInstance3D = MeshInstance3D.new()
            var tendril_mesh: CylinderMesh = CylinderMesh.new()
            tendril_mesh.top_radius = 0.018
            tendril_mesh.bottom_radius = 0.035
            tendril_mesh.height = rng.randf_range(0.34, 0.72)
            tendril.mesh = tendril_mesh
            tendril.material_override = stem_mat
            tendril.position = Vector3(0, rng.randf_range(0.12, 0.5), 0)
            tendril.rotation = Vector3(0, j * 2.1, rng.randf_range(0.75, 1.15))
            growth.add_child(tendril)
        strange_growths.append(growth)

func _build_crows() -> void:
    var crow_mat: StandardMaterial3D = _mat(Color("121118"))
    for i in range(14):
        var crow: Node3D = Node3D.new()
        add_child(crow)
        crow.set_meta("phase", rng.randf_range(0.0, TAU))
        crow.set_meta("radius", rng.randf_range(22.0, 29.0))
        crow.set_meta("speed", rng.randf_range(0.16, 0.30))

        var body: MeshInstance3D = MeshInstance3D.new()
        var body_mesh: SphereMesh = SphereMesh.new()
        body_mesh.radius = 0.13
        body_mesh.height = 0.34
        body.mesh = body_mesh
        body.scale = Vector3(0.9, 0.75, 1.5)
        body.material_override = crow_mat
        crow.add_child(body)

        for side in [-1.0, 1.0]:
            var wing: MeshInstance3D = MeshInstance3D.new()
            var wing_mesh: BoxMesh = BoxMesh.new()
            wing_mesh.size = Vector3(0.52, 0.025, 0.18)
            wing.mesh = wing_mesh
            wing.position.x = 0.26 * side
            wing.rotation.z = 0.28 * side
            wing.material_override = crow_mat
            wing.set_meta("wing_side", side)
            crow.add_child(wing)
        crows.append(crow)

func _animate_crows(time: float, delta: float) -> void:
    for i in range(crows.size()):
        var crow: Node3D = crows[i]
        var phase: float = float(crow.get_meta("phase"))
        var radius: float = float(crow.get_meta("radius"))
        var speed: float = float(crow.get_meta("speed"))
        var angle: float = phase + time * speed
        crow.global_position = Vector3(cos(angle) * radius, 9.0 + sin(angle * 1.8 + phase) * 2.6, sin(angle) * radius)
        var next_pos: Vector3 = Vector3(cos(angle + 0.08) * radius, crow.global_position.y, sin(angle + 0.08) * radius)
        crow.look_at(next_pos, crow.global_position.normalized())
        for child in crow.get_children():
            if child is MeshInstance3D and child.has_meta("wing_side"):
                var side: float = float(child.get_meta("wing_side"))
                child.rotation.z = side * (0.25 + sin(time * 8.0 + phase) * 0.34)
        if crow.global_position.distance_to(player.global_position) < 5.0:
            crow.global_position += crow.global_position.normalized() * 3.0 * delta

func _animate_growths(time: float) -> void:
    for i in range(strange_growths.size()):
        var growth: Node3D = strange_growths[i]
        growth.rotation.z = sin(time * 0.7 + i * 0.73) * 0.018
