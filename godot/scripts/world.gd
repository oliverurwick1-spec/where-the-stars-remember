extends Node3D

@export var player: CharacterBody3D
@export var dead_ground: MeshInstance3D
@export var world_environment: WorldEnvironment

const PLANET_RADIUS := 20.0

var rng := RandomNumberGenerator.new()
var crows: Array[Node3D] = []
var growths: Array[Node3D] = []
var stars: Array[Node3D] = []

func _ready() -> void:
    rng.seed = 1307
    _setup_environment()
    _build_space_backdrop()
    _build_surface_variation()
    _build_rocks()
    _build_dead_groves()
    _build_growths()
    _build_crows()

func _process(delta: float) -> void:
    var time: float = Time.get_ticks_msec() * 0.001
    _animate_stars(time)
    _animate_growths(time)
    _animate_crows(time, delta)

func _setup_environment() -> void:
    if world_environment and world_environment.environment:
        var env: Environment = world_environment.environment
        env.background_color = Color("03050d")
        env.ambient_light_color = Color("6575a6")
        env.ambient_light_energy = 0.72
        env.fog_light_color = Color("111425")
        env.fog_density = 0.0014
    if dead_ground and dead_ground.material_override:
        var mat := dead_ground.material_override as StandardMaterial3D
        mat.albedo_color = Color("2a2433")
        mat.roughness = 0.92

    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(-18, 118, 0)
    rim.light_color = Color("809cff")
    rim.light_energy = 1.9
    rim.shadow_enabled = false
    add_child(rim)

    var warm := DirectionalLight3D.new()
    warm.rotation_degrees = Vector3(-38, -55, 0)
    warm.light_color = Color("ffb48f")
    warm.light_energy = 1.25
    warm.shadow_enabled = true
    add_child(warm)

func _mat(color: Color, emission: float = 0.0, unshaded: bool = false) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.88
    if emission > 0.0:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = emission
    if unshaded:
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func _surface_dir() -> Vector3:
    var v := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
    if v.length_squared() < 0.001:
        v = Vector3.UP
    return v.normalized()

func _align(node: Node3D, normal: Vector3) -> void:
    var forward := Vector3.FORWARD
    if absf(forward.dot(normal)) > 0.92:
        forward = Vector3.RIGHT
    forward = (forward - normal * forward.dot(normal)).normalized()
    var right := normal.cross(forward).normalized()
    forward = right.cross(normal).normalized()
    node.global_transform.basis = Basis(right, normal, forward)

func _build_space_backdrop() -> void:
    var star_colors: Array[Color] = [Color("fff3dc"), Color("dbe7ff"), Color("a9c5ff"), Color("ffd0c6")]
    for i in range(720):
        var star := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.045, 0.16)
        mesh.height = mesh.radius * 2.0
        star.mesh = mesh
        star.material_override = _mat(star_colors[i % star_colors.size()], rng.randf_range(2.5, 7.0), true)
        star.global_position = _surface_dir() * rng.randf_range(75.0, 165.0)
        star.set_meta("phase", rng.randf_range(0.0, TAU))
        star.set_meta("base", rng.randf_range(0.75, 1.5))
        add_child(star)
        stars.append(star)

    for i in range(18):
        var bright := MeshInstance3D.new()
        var bm := SphereMesh.new()
        bm.radius = rng.randf_range(0.18, 0.42)
        bm.height = bm.radius * 2.0
        bright.mesh = bm
        bright.material_override = _mat(Color("f7fbff"), rng.randf_range(7.0, 14.0), true)
        bright.global_position = _surface_dir() * rng.randf_range(90.0, 150.0)
        add_child(bright)

    var galaxy_center := Vector3(-88.0, 46.0, -110.0)
    var galaxy_colors: Array[Color] = [Color("6e78c6"), Color("9a72bd"), Color("d59ac2"), Color("ffe2be")]
    for i in range(18):
        var layer := MeshInstance3D.new()
        var gm := SphereMesh.new()
        gm.radius = 4.8 - i * 0.14
        gm.height = gm.radius * 2.0
        layer.mesh = gm
        layer.global_position = galaxy_center + Vector3(rng.randf_range(-6.0, 6.0), rng.randf_range(-1.6, 1.6), rng.randf_range(-3.0, 3.0))
        layer.scale = Vector3(3.2 - i * 0.08, 0.10 + i * 0.012, 1.25 - i * 0.02)
        layer.rotation = Vector3(0.28, -0.58, 0.34)
        layer.material_override = _mat(galaxy_colors[i % galaxy_colors.size()], 0.8 + i * 0.08, true)
        add_child(layer)

    var nebula_colors: Array[Color] = [Color("6c3f86"), Color("944b76"), Color("395789"), Color("70425f")]
    for i in range(22):
        var neb := MeshInstance3D.new()
        var nm := SphereMesh.new()
        nm.radius = rng.randf_range(3.5, 7.5)
        nm.height = nm.radius * 2.0
        neb.mesh = nm
        neb.global_position = Vector3(92.0, -20.0, -126.0) + Vector3(rng.randf_range(-15.0, 15.0), rng.randf_range(-8.0, 8.0), rng.randf_range(-8.0, 8.0))
        neb.scale = Vector3(rng.randf_range(1.2, 2.8), rng.randf_range(0.12, 0.35), rng.randf_range(0.7, 1.8))
        neb.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))
        neb.material_override = _mat(nebula_colors[i % nebula_colors.size()], rng.randf_range(0.35, 0.9), true)
        add_child(neb)

    var nova_pos := Vector3(72.0, 58.0, 118.0)
    var nova := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 1.5
    sm.height = 3.0
    nova.mesh = sm
    nova.global_position = nova_pos
    nova.material_override = _mat(Color("fff4cf"), 13.0, true)
    add_child(nova)

    for i in range(5):
        var halo := MeshInstance3D.new()
        var hm := TorusMesh.new()
        hm.inner_radius = 2.3 + i * 1.35
        hm.outer_radius = 2.55 + i * 1.35
        halo.mesh = hm
        halo.global_position = nova_pos
        halo.rotation = Vector3(1.0 + i * 0.08, 0.25 + i * 0.33, 0.45)
        halo.material_override = _mat(Color("ffad86"), 4.2 - i * 0.5, true)
        add_child(halo)

    var nova_light := OmniLight3D.new()
    nova_light.global_position = nova_pos
    nova_light.light_color = Color("ffb58c")
    nova_light.light_energy = 8.0
    nova_light.omni_range = 180.0
    add_child(nova_light)

func _build_surface_variation() -> void:
    var patch_mats: Array[StandardMaterial3D] = [_mat(Color("221d2a")), _mat(Color("30283a")), _mat(Color("1d2230")), _mat(Color("3a2a38"))]
    for i in range(85):
        var normal := _surface_dir()
        if normal.y < -0.15:
            continue
        var patch := MeshInstance3D.new()
        var pm := SphereMesh.new()
        pm.radius = rng.randf_range(1.1, 3.6)
        pm.height = pm.radius * 2.0
        patch.mesh = pm
        patch.material_override = patch_mats[i % patch_mats.size()]
        patch.global_position = normal * (PLANET_RADIUS + 0.015)
        patch.scale = Vector3(rng.randf_range(0.8, 1.8), 0.025, rng.randf_range(0.7, 1.6))
        add_child(patch)
        _align(patch, normal)
        patch.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))

func _build_rocks() -> void:
    var mats: Array[StandardMaterial3D] = [_mat(Color("49414f")), _mat(Color("383744")), _mat(Color("5a4b59"))]
    for i in range(220):
        var normal := _surface_dir()
        if normal.y < -0.18:
            continue
        var rock := MeshInstance3D.new()
        var rm := SphereMesh.new()
        rm.radius = rng.randf_range(0.08, 0.68)
        rm.height = rm.radius * rng.randf_range(1.0, 1.8)
        rock.mesh = rm
        rock.material_override = mats[i % mats.size()]
        rock.global_position = normal * (PLANET_RADIUS + rm.radius * 0.16)
        rock.scale = Vector3(rng.randf_range(0.5, 1.8), rng.randf_range(0.3, 0.8), rng.randf_range(0.55, 1.6))
        add_child(rock)
        _align(rock, normal)
        rock.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))

    var crystal_mats: Array[StandardMaterial3D] = [_mat(Color("7f77b8"), 0.7), _mat(Color("4f8a92"), 0.55)]
    for i in range(36):
        var n := _surface_dir()
        if n.y < -0.05:
            continue
        var cluster := Node3D.new()
        cluster.global_position = n * PLANET_RADIUS
        add_child(cluster)
        _align(cluster, n)
        for j in range(rng.randi_range(2, 5)):
            var shard := MeshInstance3D.new()
            var cm := PrismMesh.new()
            cm.size = Vector3(rng.randf_range(0.08, 0.20), rng.randf_range(0.35, 0.95), rng.randf_range(0.08, 0.20))
            shard.mesh = cm
            shard.material_override = crystal_mats[(i + j) % crystal_mats.size()]
            shard.position = Vector3(rng.randf_range(-0.22, 0.22), cm.size.y * 0.5, rng.randf_range(-0.22, 0.22))
            shard.rotation.z = rng.randf_range(-0.24, 0.24)
            cluster.add_child(shard)

func _build_dead_groves() -> void:
    var trunk_mat := _mat(Color("211e27"))
    for i in range(58):
        var normal := _surface_dir()
        if normal.y < -0.05:
            continue
        var tree := Node3D.new()
        tree.global_position = normal * PLANET_RADIUS
        add_child(tree)
        _align(tree, normal)
        tree.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))
        var trunk := MeshInstance3D.new()
        var tm := CylinderMesh.new()
        tm.top_radius = rng.randf_range(0.04, 0.10)
        tm.bottom_radius = rng.randf_range(0.16, 0.32)
        tm.height = rng.randf_range(1.5, 4.6)
        trunk.mesh = tm
        trunk.material_override = trunk_mat
        trunk.position.y = tm.height * 0.5
        trunk.rotation.z = rng.randf_range(-0.28, 0.28)
        tree.add_child(trunk)
        for j in range(rng.randi_range(4, 7)):
            var branch := MeshInstance3D.new()
            var bm := CylinderMesh.new()
            bm.top_radius = 0.012
            bm.bottom_radius = rng.randf_range(0.03, 0.07)
            bm.height = rng.randf_range(0.65, 1.65)
            branch.mesh = bm
            branch.material_override = trunk_mat
            branch.position = Vector3(0, tm.height * rng.randf_range(0.42, 0.93), 0)
            branch.rotation = Vector3(rng.randf_range(-0.22, 0.22), j * 1.0 + rng.randf_range(-0.4, 0.4), rng.randf_range(0.72, 1.36))
            tree.add_child(branch)

func _build_growths() -> void:
    var stem_mat := _mat(Color("2c2936"))
    var pod_mats: Array[StandardMaterial3D] = [_mat(Color("7a5a8f"), 0.45), _mat(Color("496d78"), 0.35)]
    for i in range(110):
        var normal := _surface_dir()
        if normal.y < -0.12:
            continue
        var growth := Node3D.new()
        growth.global_position = normal * PLANET_RADIUS
        add_child(growth)
        _align(growth, normal)
        growth.rotate_object_local(Vector3.UP, rng.randf_range(0.0, TAU))
        var stalk := MeshInstance3D.new()
        var sm := CylinderMesh.new()
        sm.top_radius = rng.randf_range(0.012, 0.035)
        sm.bottom_radius = rng.randf_range(0.035, 0.085)
        sm.height = rng.randf_range(0.4, 1.8)
        stalk.mesh = sm
        stalk.material_override = stem_mat
        stalk.position.y = sm.height * 0.5
        stalk.rotation.z = rng.randf_range(-0.38, 0.38)
        growth.add_child(stalk)
        var pod := MeshInstance3D.new()
        var pm := SphereMesh.new()
        pm.radius = rng.randf_range(0.07, 0.17)
        pm.height = pm.radius * 1.8
        pod.mesh = pm
        pod.material_override = pod_mats[i % pod_mats.size()]
        pod.position.y = sm.height + 0.04
        pod.scale = Vector3(0.65, 1.25, 0.65)
        growth.add_child(pod)
        growths.append(growth)

func _build_crows() -> void:
    var crow_mat := _mat(Color("080910"))
    for i in range(24):
        var crow := Node3D.new()
        add_child(crow)
        crow.set_meta("phase", rng.randf_range(0.0, TAU))
        crow.set_meta("radius", rng.randf_range(24.0, 36.0))
        crow.set_meta("speed", rng.randf_range(0.12, 0.28))
        var body := MeshInstance3D.new()
        var bm := SphereMesh.new()
        bm.radius = 0.12
        bm.height = 0.34
        body.mesh = bm
        body.scale = Vector3(0.82, 0.72, 1.55)
        body.material_override = crow_mat
        crow.add_child(body)
        for side in [-1.0, 1.0]:
            var wing := MeshInstance3D.new()
            var wm := PrismMesh.new()
            wm.size = Vector3(0.52, 0.025, 0.20)
            wing.mesh = wm
            wing.position.x = 0.24 * side
            wing.material_override = crow_mat
            wing.set_meta("side", side)
            crow.add_child(wing)
        crows.append(crow)

func _animate_stars(time: float) -> void:
    for star in stars:
        var phase: float = float(star.get_meta("phase"))
        var base: float = float(star.get_meta("base"))
        var twinkle: float = 0.82 + sin(time * 1.9 + phase) * 0.18
        star.scale = Vector3.ONE * base * twinkle

func _animate_growths(time: float) -> void:
    for i in range(growths.size()):
        growths[i].rotation.z = sin(time * 0.55 + i * 0.61) * 0.015

func _animate_crows(time: float, delta: float) -> void:
    for crow in crows:
        var phase: float = float(crow.get_meta("phase"))
        var radius: float = float(crow.get_meta("radius"))
        var speed: float = float(crow.get_meta("speed"))
        var angle: float = phase + time * speed
        crow.global_position = Vector3(cos(angle) * radius, 8.0 + sin(angle * 1.6 + phase) * 3.8, sin(angle) * radius)
        var next_pos := Vector3(cos(angle + 0.08) * radius, crow.global_position.y, sin(angle + 0.08) * radius)
        crow.look_at(next_pos, crow.global_position.normalized())
        for child in crow.get_children():
            if child is MeshInstance3D and child.has_meta("side"):
                var side: float = float(child.get_meta("side"))
                child.rotation.z = side * (0.25 + sin(time * 8.3 + phase) * 0.34)
        if player and crow.global_position.distance_to(player.global_position) < 5.0:
            crow.global_position += crow.global_position.normalized() * 3.0 * delta
