extends Node3D

@export var player: CharacterBody3D
@export var seed_shrine: Node3D
@export var dead_ground: MeshInstance3D
@export var world_environment: WorldEnvironment

const PLANET_RADIUS := 12.0

var awakened: bool = false
var bloom: float = 0.0
var target_bloom: float = 0.0
var flowers: Array[Node3D] = []
var grasses: Array[Node3D] = []
var birds: Array[Node3D] = []
var fireflies: Array[Node3D] = []
var resonators: Array[Node3D] = []
var resonator_mats: Array[StandardMaterial3D] = []
var solved_count: int = 0
var rng := RandomNumberGenerator.new()
var bloom_origin := Vector3.ZERO

func _ready() -> void:
    rng.seed = 1307
    bloom_origin = seed_shrine.global_position
    _build_rocks()
    _build_dead_trees()
    _build_grass()
    _build_foliage()
    _build_birds()
    _build_fireflies()
    _build_resonators()
    $UI/Message.text = "Three sleeping stones guard the seed."

func _process(delta: float) -> void:
    var time: float = Time.get_ticks_msec() * 0.001
    _animate_environment(time)
    _handle_puzzle()
    bloom = lerp(bloom, target_bloom, 1.0 - exp(-0.82 * delta))
    _apply_bloom(time)

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

func _handle_puzzle() -> void:
    if awakened:
        return
    var nearest: int = -1
    var nearest_dist: float = 99.0
    for i in range(resonators.size()):
        var d: float = resonators[i].global_position.distance_to(player.global_position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = i
    if nearest >= 0 and nearest_dist < 1.8 and Input.is_action_just_pressed("interact"):
        var r: Node3D = resonators[nearest]
        if not r.get_meta("active", false):
            r.set_meta("active", true)
            solved_count += 1
            resonator_mats[nearest].emission_enabled = true
            resonator_mats[nearest].emission = Color("d8b2ff")
            resonator_mats[nearest].emission_energy_multiplier = 4.0
            $UI/Message.text = "The stone hums back. %d / 3" % solved_count
            if solved_count == 3:
                awakened = true
                target_bloom = 1.0
                $UI/Message.text = "The first seed remembers."

func _animate_environment(time: float) -> void:
    for i in range(flowers.size()):
        var f: Node3D = flowers[i]
        var d: float = f.global_position.distance_to(player.global_position)
        var bend: float = clampf((1.8 - d) / 1.8, 0.0, 1.0)
        f.rotate_object_local(Vector3.FORWARD, sin(time * 2.1 + i * 0.73) * 0.001 + bend * 0.003)
    for i in range(grasses.size()):
        var g: Node3D = grasses[i]
        var d: float = g.global_position.distance_to(player.global_position)
        var push: float = clampf((1.25 - d) / 1.25, 0.0, 1.0)
        g.rotate_object_local(Vector3.FORWARD, sin(time * 1.9 + i * 0.37) * 0.0008 + push * 0.003)
    for i in range(birds.size()):
        var b: Node3D = birds[i]
        var angle: float = time * (0.28 + i * 0.045) + i * 1.8
        var radius: float = 15.5 + i * 0.55
        b.position = Vector3(cos(angle) * radius, 6.0 + sin(angle * 2.0) * 1.1, sin(angle) * radius)
        b.look_at(Vector3(cos(angle + 0.16) * radius, b.position.y, sin(angle + 0.16) * radius), Vector3.UP)
        var escape: float = clampf((4.5 - b.global_position.distance_to(player.global_position)) / 4.5, 0.0, 1.0)
        b.position += b.global_position.normalized() * escape * 2.5
    for i in range(fireflies.size()):
        var fly: Node3D = fireflies[i]
        var n := fly.global_position.normalized()
        fly.global_position = n * (PLANET_RADIUS + 0.8 + sin(time * 1.8 + i) * 0.25)

func _apply_bloom(time: float) -> void:
    if dead_ground and dead_ground.material_override:
        var mat: StandardMaterial3D = dead_ground.material_override as StandardMaterial3D
        mat.albedo_color = Color("4b4148").lerp(Color("688a55"), bloom)
        mat.roughness = lerpf(0.98, 0.72, bloom)
    if world_environment and world_environment.environment:
        var env: Environment = world_environment.environment
        env.background_color = Color("211b2b").lerp(Color("768bb2"), bloom * 0.82)
        env.ambient_light_color = Color("7f7896").lerp(Color("c6d5bd"), bloom)
        env.fog_light_color = Color("30283a").lerp(Color("b8c5c7"), bloom)
    for i in range(flowers.size()):
        var flower: Node3D = flowers[i]
        var dist: float = flower.global_position.distance_to(bloom_origin)
        var wave: float = bloom * 24.0 - dist
        var life: float = clampf(wave * 0.5, 0.0, 1.0)
        flower.scale = Vector3.ONE * maxf(0.001, ease(life, -1.8))
    for i in range(grasses.size()):
        var grass: Node3D = grasses[i]
        var dist: float = grass.global_position.distance_to(bloom_origin)
        var life: float = clampf((bloom * 24.0 - dist) * 0.42, 0.0, 1.0)
        grass.scale = Vector3.ONE * Vector3(1.0, maxf(0.05, ease(life, -1.4)), 1.0)
    for i in range(fireflies.size()):
        fireflies[i].visible = bloom > 0.35
    if seed_shrine:
        seed_shrine.scale = Vector3.ONE * (1.0 + sin(time * 4.0) * 0.025)

func _mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    if emission > 0.0:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = emission
    return mat

func _build_rocks() -> void:
    var rock_mat := _mat(Color("5f5663"))
    for i in range(34):
        var a := rng.randf_range(0.0, TAU)
        var r := rng.randf_range(2.5, 10.5)
        var rock := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.18, 0.55)
        mesh.height = mesh.radius * 1.4
        rock.mesh = mesh
        rock.material_override = rock_mat
        rock.global_position = _surface_point(cos(a) * r, sin(a) * r, mesh.radius * 0.35)
        rock.scale = Vector3(rng.randf_range(0.8, 1.6), rng.randf_range(0.45, 0.9), rng.randf_range(0.8, 1.4))
        add_child(rock)
        _align_to_surface(rock, rock.global_position.normalized())

func _build_dead_trees() -> void:
    var trunk_mat := _mat(Color("4a3d42"))
    for i in range(7):
        var tree := Node3D.new()
        var a := i / 7.0 * TAU + 0.3
        var r := 7.2 + (i % 2) * 1.3
        tree.global_position = _surface_point(cos(a) * r, sin(a) * r, 0.0)
        add_child(tree)
        _align_to_surface(tree, tree.global_position.normalized())
        var trunk := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.11
        mesh.bottom_radius = 0.28
        mesh.height = 2.4 + (i % 3) * 0.35
        trunk.mesh = mesh
        trunk.position.y = mesh.height * 0.5
        trunk.material_override = trunk_mat
        tree.add_child(trunk)
        for j in range(3):
            var branch := MeshInstance3D.new()
            var bm := CylinderMesh.new()
            bm.top_radius = 0.045
            bm.bottom_radius = 0.09
            bm.height = 1.15
            branch.mesh = bm
            branch.material_override = trunk_mat
            branch.position = Vector3(0, 1.45 + j * 0.28, 0)
            branch.rotation = Vector3(0.0, j * 2.1 + i, 0.75 + j * 0.12)
            tree.add_child(branch)

func _build_grass() -> void:
    var grass_mat := _mat(Color("6e7d59"))
    for i in range(180):
        var a := rng.randf_range(0.0, TAU)
        var r := rng.randf_range(1.0, 10.8)
        var blade := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.035, rng.randf_range(0.22, 0.42), 0.08)
        blade.mesh = mesh
        blade.global_position = _surface_point(cos(a) * r, sin(a) * r, mesh.size.y * 0.5)
        blade.material_override = grass_mat
        add_child(blade)
        _align_to_surface(blade, blade.global_position.normalized())
        blade.scale = Vector3(1.0, 0.05, 1.0)
        grasses.append(blade)

func _build_foliage() -> void:
    var palette: Array[Color] = [Color("f1a9c2"), Color("d8b2ff"), Color("f7df8d"), Color("9fd4ff"), Color("f4f1df")]
    for i in range(130):
        var angle := rng.randf_range(0.0, TAU)
        var radius := rng.randf_range(1.8, 10.6)
        var flower := Node3D.new()
        flower.global_position = _surface_point(cos(angle) * radius, sin(angle) * radius, 0.0)
        flower.scale = Vector3.ONE * 0.001
        add_child(flower)
        _align_to_surface(flower, flower.global_position.normalized())
        var stem := MeshInstance3D.new()
        var stem_mesh := CylinderMesh.new()
        stem_mesh.top_radius = 0.018
        stem_mesh.bottom_radius = 0.028
        stem_mesh.height = rng.randf_range(0.32, 0.62)
        stem.mesh = stem_mesh
        stem.position.y = stem_mesh.height * 0.5
        stem.material_override = _mat(Color("4c8754"))
        flower.add_child(stem)
        var blossom := MeshInstance3D.new()
        var blossom_mesh := SphereMesh.new()
        blossom_mesh.radius = rng.randf_range(0.08, 0.14)
        blossom_mesh.height = blossom_mesh.radius * 1.1
        blossom.mesh = blossom_mesh
        blossom.position.y = stem_mesh.height + 0.04
        blossom.scale = Vector3(1.45, 0.5, 1.45)
        blossom.material_override = _mat(palette[i % palette.size()], 0.35)
        flower.add_child(blossom)
        flowers.append(flower)

func _build_birds() -> void:
    var bird_mat := _mat(Color("303743"))
    for i in range(6):
        var bird := Node3D.new()
        add_child(bird)
        for side in [-1.0, 1.0]:
            var wing := MeshInstance3D.new()
            var mesh := BoxMesh.new()
            mesh.size = Vector3(0.42, 0.028, 0.15)
            wing.mesh = mesh
            wing.position.x = 0.2 * side
            wing.rotation.z = 0.28 * side
            wing.material_override = bird_mat
            bird.add_child(wing)
        birds.append(bird)

func _build_fireflies() -> void:
    for i in range(18):
        var glow := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.035
        mesh.height = 0.07
        glow.mesh = mesh
        glow.material_override = _mat(Color("ffe89a"), 5.0)
        var a := rng.randf_range(0.0, TAU)
        var r := rng.randf_range(2.0, 9.0)
        glow.global_position = _surface_point(cos(a) * r, sin(a) * r, 0.8)
        glow.visible = false
        add_child(glow)
        fireflies.append(glow)

func _build_resonators() -> void:
    var xz: Array[Vector2] = [Vector2(-7.4, 1.5), Vector2(2.5, -7.4), Vector2(6.4, 4.2)]
    for i in range(3):
        var r := Node3D.new()
        r.global_position = _surface_point(xz[i].x, xz[i].y, 0.0)
        r.set_meta("active", false)
        add_child(r)
        _align_to_surface(r, r.global_position.normalized())
        var base := MeshInstance3D.new()
        var bm := CylinderMesh.new()
        bm.top_radius = 0.42
        bm.bottom_radius = 0.62
        bm.height = 0.6
        base.mesh = bm
        base.position.y = 0.3
        base.material_override = _mat(Color("51485a"))
        r.add_child(base)
        var crystal := MeshInstance3D.new()
        var cm := PrismMesh.new()
        cm.size = Vector3(0.5, 1.25, 0.5)
        crystal.mesh = cm
        crystal.position.y = 1.15
        var mat := _mat(Color("7b7186"), 0.0)
        crystal.material_override = mat
        r.add_child(crystal)
        resonators.append(r)
        resonator_mats.append(mat)
