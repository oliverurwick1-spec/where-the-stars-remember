extends Node3D

@export var player: CharacterBody3D
@export var seed_shrine: Node3D
@export var dead_ground: MeshInstance3D
@export var world_environment: WorldEnvironment

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

func _handle_puzzle() -> void:
    if awakened:
        return
    var nearest: int = -1
    var nearest_dist := 99.0
    for i in range(resonators.size()):
        var d := resonators[i].global_position.distance_to(player.global_position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = i
    if nearest >= 0 and nearest_dist < 1.8 and Input.is_action_just_pressed("interact"):
        var r := resonators[nearest]
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
        var f := flowers[i]
        var d := f.global_position.distance_to(player.global_position)
        var bend := clamp((1.8 - d) / 1.8, 0.0, 1.0)
        f.rotation.z = sin(time * 2.1 + i * 0.73) * 0.045 + bend * 0.32
        f.rotation.x = cos(time * 1.55 + i * 0.41) * 0.035
    for i in range(grasses.size()):
        var g := grasses[i]
        var d := g.global_position.distance_to(player.global_position)
        var push := clamp((1.25 - d) / 1.25, 0.0, 1.0)
        g.rotation.z = sin(time * 1.9 + i * 0.37) * 0.04 + push * 0.26
    for i in range(birds.size()):
        var b := birds[i]
        var angle := time * (0.28 + i * 0.045) + i * 1.8
        var radius := 6.5 + i * 1.25
        var center := Vector3(-1.5, 0.0, -1.0)
        b.position = center + Vector3(cos(angle) * radius, 4.7 + sin(angle * 2.0) * 0.55, sin(angle) * radius)
        b.look_at(center + Vector3(cos(angle + 0.16) * radius, b.position.y, sin(angle + 0.16) * radius), Vector3.UP)
        var escape := clamp((4.5 - b.global_position.distance_to(player.global_position)) / 4.5, 0.0, 1.0)
        b.position.y += escape * 2.7
        for child in b.get_children():
            if child is MeshInstance3D:
                child.rotation.z += sin(time * 9.0 + i) * 0.018
    for i in range(fireflies.size()):
        var f := fireflies[i]
        f.position.y = 0.7 + sin(time * 1.8 + i) * 0.35
        f.rotation.y += 0.01

func _apply_bloom(time: float) -> void:
    if dead_ground and dead_ground.material_override:
        var mat := dead_ground.material_override as StandardMaterial3D
        mat.albedo_color = Color("4b4148").lerp(Color("688a55"), bloom)
        mat.roughness = lerp(0.98, 0.72, bloom)
    if world_environment and world_environment.environment:
        var env := world_environment.environment
        env.background_color = Color("211b2b").lerp(Color("768bb2"), bloom * 0.82)
        env.ambient_light_color = Color("7f7896").lerp(Color("c6d5bd"), bloom)
        env.fog_light_color = Color("30283a").lerp(Color("b8c5c7"), bloom)
    for i in range(flowers.size()):
        var f := flowers[i]
        var dist := f.global_position.distance_to(bloom_origin)
        var wave := bloom * 20.0 - dist
        var life := clamp(wave * 0.55, 0.0, 1.0)
        f.scale = Vector3.ONE * max(0.001, ease(life, -1.8))
    for i in range(grasses.size()):
        var g := grasses[i]
        var dist := g.global_position.distance_to(bloom_origin)
        var life := clamp((bloom * 19.0 - dist) * 0.45, 0.0, 1.0)
        g.scale.y = max(0.05, ease(life, -1.4))
    for i in range(fireflies.size()):
        fireflies[i].visible = bloom > 0.35
    if seed_shrine:
        seed_shrine.rotation.y = sin(time * 0.7) * 0.05
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
        var r := rng.randf_range(3.0, 11.0)
        var rock := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = rng.randf_range(0.18, 0.55)
        mesh.height = mesh.radius * 1.4
        rock.mesh = mesh
        rock.material_override = rock_mat
        rock.position = Vector3(cos(a) * r, rng.randf_range(0.02, 0.16), sin(a) * r)
        rock.scale = Vector3(rng.randf_range(0.8, 1.6), rng.randf_range(0.45, 0.9), rng.randf_range(0.8, 1.4))
        rock.rotation = Vector3(rng.randf(), rng.randf() * TAU, rng.randf())
        add_child(rock)

func _build_dead_trees() -> void:
    var trunk_mat := _mat(Color("4a3d42"))
    for i in range(7):
        var tree := Node3D.new()
        var a := i / 7.0 * TAU + 0.3
        var r := 7.8 + (i % 2) * 1.5
        tree.position = Vector3(cos(a) * r, 0.0, sin(a) * r)
        add_child(tree)
        var trunk := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.11
        mesh.bottom_radius = 0.28
        mesh.height = 2.4 + (i % 3) * 0.35
        trunk.mesh = mesh
        trunk.position.y = mesh.height * 0.5
        trunk.rotation.z = (i - 3) * 0.035
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
        var r := rng.randf_range(1.5, 11.7)
        var blade := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.035, rng.randf_range(0.22, 0.42), 0.08)
        blade.mesh = mesh
        blade.position = Vector3(cos(a) * r, mesh.size.y * 0.5, sin(a) * r)
        blade.rotation.y = rng.randf_range(0.0, TAU)
        blade.scale.y = 0.05
        blade.material_override = grass_mat
        add_child(blade)
        grasses.append(blade)

func _build_foliage() -> void:
    var palette: Array[Color] = [Color("f1a9c2"), Color("d8b2ff"), Color("f7df8d"), Color("9fd4ff"), Color("f4f1df")]
    for i in range(130):
        var angle := rng.randf_range(0.0, TAU)
        var radius := rng.randf_range(2.2, 11.5)
        var p := Vector3(cos(angle) * radius, 0.05, sin(angle) * radius)
        if p.distance_to(seed_shrine.position) < 1.3:
            continue
        var flower := Node3D.new()
        flower.position = p
        flower.scale = Vector3.ONE * 0.001
        add_child(flower)
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
        var r := rng.randf_range(2.5, 9.5)
        glow.position = Vector3(cos(a) * r, 0.7, sin(a) * r)
        glow.visible = false
        add_child(glow)
        fireflies.append(glow)

func _build_resonators() -> void:
    var positions := [Vector3(-8.0, 0.0, 1.5), Vector3(2.5, 0.0, -8.0), Vector3(7.0, 0.0, 4.5)]
    for i in range(3):
        var r := Node3D.new()
        r.position = positions[i]
        r.set_meta("active", false)
        add_child(r)
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
