extends Node3D

@export var player: CharacterBody3D
@export var dead_ground: MeshInstance3D
@export var world_environment: WorldEnvironment

const PLANET_RADIUS := 20.0

var rng := RandomNumberGenerator.new()
var rocks: Array[Node3D] = []
var crows: Array[Node3D] = []
var strange_growths: Array[Node3D] = []
var stars: Array[Node3D] = []

func _ready() -> void:
    rng.seed = 1307
    _build_space_backdrop()
    _build_rock_scatter()
    _build_ridges()
    _build_dead_grove()
    _build_strange_growths()
    _build_crows()

func _process(delta: float) -> void:
    var time: float = Time.get_ticks_msec() * 0.001
    _animate_crows(time, delta)
    _animate_growths(time)
    _animate_stars(time)

func _surface_point(x: float, z: float, lift: float = 0.0) -> Vector3:
    var rr: float = x * x + z * z
    var y: float = sqrt(maxf(0.0, PLANET_RADIUS * PLANET_RADIUS - rr))
    var p: Vector3 = Vector3(x, y, z)
    return p.normalized() * (PLANET_RADIUS + lift)

func _surface_dir() -> Vector3:
    var v := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
    if v.length_squared() < 0.001:
        v = Vector3.UP
    return v.normalized()

func _align_to_surface(node: Node3D, normal: Vector3) -> void:
    var forward: Vector3 = Vector3.FORWARD
    if absf(forward.dot(normal)) > 0.92:
        forward = Vector3.RIGHT
    forward = (forward - normal * forward.dot(normal)).normalized()
    var right: Vector3 = normal.cross(forward).normalized()
    forward = right.cross(normal).normalized()
    node.global_transform.basis = Basis(right, normal, forward)

func _mat(color: Color, emission: float = 0.0, unshaded: bool = false) -> StandardMaterial3D:
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    if emission > 0.0:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = emission
    if unshaded:
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func _build_space_backdrop() -> void:
    var star_colors: Array[Color] = [Color("fff4dd"), Color("d9e7ff"), Color("ffd0bd"), Color("c7cfff")]
    for i in range(340):
        var star := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.025, 0.09)
        mesh.height = mesh.radius * 2.0
        star.mesh = mesh
        star.material_override = _mat(star_colors[i % star_colors.size()], rng.randf_range(1.6, 4.5), true)
        var distance: float = rng.randf_range(82.0, 145.0)
        star.global_position = _surface_dir() * distance
        star.set_meta("phase", rng.randf_range(0.0, TAU))
        star.set_meta("base_scale", rng.randf_range(0.7, 1.7))
        add_child(star)
        stars.append(star)

    var galaxy := MeshInstance3D.new()
    var galaxy_mesh := SphereMesh.new()
    galaxy_mesh.radius = 7.0
    galaxy_mesh.height = 14.0
    galaxy.mesh = galaxy_mesh
    galaxy.global_position = Vector3(-72.0, 36.0, -94.0)
    galaxy.scale = Vector3(2.5, 0.18, 1.0)
    galaxy.rotation = Vector3(0.3, -0.6, 0.25)
    galaxy.material_override = _mat(Color("675f9f"), 1.15, true)
    add_child(galaxy)

    var nebula := MeshInstance3D.new()
    var nebula_mesh := SphereMesh.new()
    nebula_mesh.radius = 9.0
    nebula_mesh.height = 18.0
    nebula.mesh = nebula_mesh
    nebula.global_position = Vector3(88.0, -22.0, -112.0)
    nebula.scale = Vector3(1.9, 0.35, 1.2)
    nebula.rotation = Vector3(-0.4, 0.35, -0.55)
    nebula.material_override = _mat(Color("7e425f"), 0.8, true)
    add_child(nebula)

    var nova := MeshInstance3D.new()
    var nova_mesh := SphereMesh.new()
    nova_mesh.radius = 1.3
    nova_mesh.height = 2.6
    nova.mesh = nova_mesh
    nova.global_position = Vector3(64.0, 48.0, 108.0)
    nova.material_override = _mat(Color("fff0c8"), 9.0, true)
    add_child(nova)

    for i in range(3):
        var halo := MeshInstance3D.new()
        var halo_mesh := TorusMesh.new()
        halo_mesh.inner_radius = 1.8 + i * 1.1
        halo_mesh.outer_radius = 2.05 + i * 1.1
        halo.mesh = halo_mesh
        halo.global_position = nova.global_position
        halo.rotation = Vector3(1.1, 0.25 + i * 0.4, 0.4)
        halo.material_override = _mat(Color("f3b78a"), 2.2 - i * 0.35, true)
        add_child(halo)

func _build_rock_scatter() -> void:
    var rock_mats: Array[StandardMaterial3D] = [_mat(Color("494550")), _mat(Color("3d3943")), _mat(Color("57505b"))]
    for i in range(180):
        var normal: Vector3 = _surface_dir()
        if normal.y < -0.15:
            continue
        var rock := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.10, 0.72)
        mesh.height = mesh.radius * rng.randf_range(1.1, 1.8)
        rock.mesh = mesh
        rock.material_override = rock_mats[i % rock_mats.size()]
        rock.global_position = normal * (PLANET_RADIUS + mesh.radius * 0.18)
        rock.scale = Vector3(rng.randf_range(0.55, 1.7), rng.randf_range(0.32, 0.9), rng.randf_range(0.6, 1.55))
        add_child(rock)
        _align_to_surface(rock, normal)
        rock.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))
        rocks.append(rock)

func _build_ridges() -> void:
    var ridge_mat := _mat(Color("302d35"))
    for i in range(34):
        var normal: Vector3 = _surface_dir()
        if normal.y < -0.05:
            continue
        var ridge := MeshInstance3D.new()
        var mesh := PrismMesh.new()
        mesh.size = Vector3(rng.randf_range(0.5, 1.8), rng.randf_range(0.18, 0.6), rng.randf_range(0.5, 1.4))
        ridge.mesh = mesh
        ridge.material_override = ridge_mat
        ridge.global_position = normal * (PLANET_RADIUS + 0.06)
        add_child(ridge)
        _align_to_surface(ridge, normal)
        ridge.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))

func _build_dead_grove() -> void:
    var trunk_mat: StandardMaterial3D = _mat(Color("27242b"))
    for i in range(44):
        var normal: Vector3 = _surface_dir()
        if normal.y < 0.05:
            continue
        var tree: Node3D = Node3D.new()
        tree.global_position = normal * PLANET_RADIUS
        add_child(tree)
        _align_to_surface(tree, normal)
        tree.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))

        var trunk: MeshInstance3D = MeshInstance3D.new()
        var tm: CylinderMesh = CylinderMesh.new()
        tm.top_radius = rng.randf_range(0.05, 0.12)
        tm.bottom_radius = rng.randf_range(0.18, 0.36)
        tm.height = rng.randf_range(1.7, 3.8)
        trunk.mesh = tm
        trunk.material_override = trunk_mat
        trunk.position.y = tm.height * 0.5
        trunk.rotation.z = rng.randf_range(-0.2, 0.2)
        tree.add_child(trunk)

        for j in range(5):
            var branch := MeshInstance3D.new()
            var bm := CylinderMesh.new()
            bm.top_radius = 0.018
            bm.bottom_radius = rng.randf_range(0.04, 0.085)
            bm.height = rng.randf_range(0.7, 1.45)
            branch.mesh = bm
            branch.material_override = trunk_mat
            branch.position = Vector3(0, tm.height * rng.randf_range(0.45, 0.92), 0)
            branch.rotation = Vector3(rng.randf_range(-0.18, 0.18), j * 1.25 + rng.randf_range(-0.25, 0.25), rng.randf_range(0.72, 1.28))
            tree.add_child(branch)

func _build_strange_growths() -> void:
    var stem_mat: StandardMaterial3D = _mat(Color("34303d"))
    var eye_mat: StandardMaterial3D = _mat(Color("6b4f78"), 0.28)
    for i in range(72):
        var normal: Vector3 = _surface_dir()
        if normal.y < 0.0:
            continue
        var growth := Node3D.new()
        growth.global_position = normal * PLANET_RADIUS
        add_child(growth)
        _align_to_surface(growth, normal)
        growth.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))

        var stalk := MeshInstance3D.new()
        var stalk_mesh := CylinderMesh.new()
        stalk_mesh.top_radius = rng.randf_range(0.018, 0.05)
        stalk_mesh.bottom_radius = rng.randf_range(0.05, 0.11)
        stalk_mesh.height = rng.randf_range(0.45, 1.5)
        stalk.mesh = stalk_mesh
        stalk.material_override = stem_mat
        stalk.position.y = stalk_mesh.height * 0.5
        stalk.rotation.z = rng.randf_range(-0.32, 0.32)
        growth.add_child(stalk)

        var pod := MeshInstance3D.new()
        var pod_mesh := SphereMesh.new()
        pod_mesh.radius = rng.randf_range(0.08, 0.18)
        pod_mesh.height = pod_mesh.radius * 1.8
        pod.mesh = pod_mesh
        pod.material_override = eye_mat
        pod.position = Vector3(0, stalk_mesh.height + 0.03, 0)
        pod.scale = Vector3(0.65, 1.2, 0.65)
        growth.add_child(pod)
        strange_growths.append(growth)

func _build_crows() -> void:
    var crow_mat: StandardMaterial3D = _mat(Color("0f0e14"))
    for i in range(20):
        var crow := Node3D.new()
        add_child(crow)
        crow.set_meta("phase", rng.randf_range(0.0, TAU))
        crow.set_meta("radius", rng.randf_range(24.0, 34.0))
        crow.set_meta("speed", rng.randf_range(0.14, 0.28))

        var body := MeshInstance3D.new()
        var body_mesh := SphereMesh.new()
        body_mesh.radius = 0.12
        body_mesh.height = 0.34
        body.mesh = body_mesh
        body.scale = Vector3(0.82, 0.72, 1.55)
        body.material_override = crow_mat
        crow.add_child(body)

        for side in [-1.0, 1.0]:
            var wing := MeshInstance3D.new()
            var wing_mesh := PrismMesh.new()
            wing_mesh.size = Vector3(0.5, 0.035, 0.22)
            wing.mesh = wing_mesh
            wing.position.x = 0.24 * side
            wing.rotation.z = 0.28 * side
            wing.material_override = crow_mat
            wing.set_meta("wing_side", side)
            crow.add_child(wing)
        crows.append(crow)

func _animate_crows(time: float, delta: float) -> void:
    for crow in crows:
        var phase: float = float(crow.get_meta("phase"))
        var radius: float = float(crow.get_meta("radius"))
        var speed: float = float(crow.get_meta("speed"))
        var angle: float = phase + time * speed
        crow.global_position = Vector3(cos(angle) * radius, 8.0 + sin(angle * 1.8 + phase) * 3.3, sin(angle) * radius)
        var next_pos := Vector3(cos(angle + 0.08) * radius, crow.global_position.y, sin(angle + 0.08) * radius)
        crow.look_at(next_pos, crow.global_position.normalized())
        for child in crow.get_children():
            if child is MeshInstance3D and child.has_meta("wing_side"):
                var side: float = float(child.get_meta("wing_side"))
                child.rotation.z = side * (0.24 + sin(time * 8.5 + phase) * 0.34)
        if crow.global_position.distance_to(player.global_position) < 5.0:
            crow.global_position += crow.global_position.normalized() * 3.0 * delta

func _animate_growths(time: float) -> void:
    for i in range(strange_growths.size()):
        strange_growths[i].rotation.z = sin(time * 0.7 + i * 0.73) * 0.016

func _animate_stars(time: float) -> void:
    for i in range(stars.size()):
        var star: Node3D = stars[i]
        var phase: float = float(star.get_meta("phase"))
        var base_scale: float = float(star.get_meta("base_scale"))
        var twinkle: float = 0.82 + sin(time * 1.7 + phase) * 0.18
        star.scale = Vector3.ONE * base_scale * twinkle
