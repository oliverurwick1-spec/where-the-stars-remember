extends Node3D

@export var player: CharacterBody3D
@export var seed_shrine: Node3D
@export var dead_ground: MeshInstance3D
@export var world_environment: WorldEnvironment

var awakened: bool = false
var bloom: float = 0.0
var target_bloom: float = 0.0
var flowers: Array[Node3D] = []
var birds: Array[Node3D] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 1307
    _build_foliage()
    _build_birds()

func _process(delta: float) -> void:
    var time: float = Time.get_ticks_msec() * 0.001
    for i in range(flowers.size()):
        var f: Node3D = flowers[i]
        var d: float = f.global_position.distance_to(player.global_position)
        var bend: float = clamp((2.0 - d) / 2.0, 0.0, 1.0)
        f.rotation.z = sin(time * 2.2 + i * 0.73) * 0.035 + bend * 0.22
        f.rotation.x = cos(time * 1.7 + i * 0.41) * 0.025

    for i in range(birds.size()):
        var b: Node3D = birds[i]
        var angle: float = time * (0.35 + i * 0.07) + i * 2.1
        var radius: float = 7.5 + i * 1.6
        b.position = Vector3(cos(angle) * radius, 5.2 + sin(angle * 1.8) * 0.7, sin(angle) * radius)
        b.look_at(Vector3(cos(angle + 0.2) * radius, b.position.y, sin(angle + 0.2) * radius), Vector3.UP)
        var escape: float = clamp((4.0 - b.global_position.distance_to(player.global_position)) / 4.0, 0.0, 1.0)
        b.position.y += escape * 2.5

    if not awakened and player.global_position.distance_to(seed_shrine.global_position) < 2.3 and Input.is_action_just_pressed("interact"):
        awakened = true
        target_bloom = 1.0
        $UI/Message.text = "The first seed remembers."
        $UI/Message.modulate.a = 1.0

    bloom = lerp(bloom, target_bloom, 1.0 - exp(-1.35 * delta))
    _apply_bloom()

func _apply_bloom() -> void:
    if dead_ground and dead_ground.material_override:
        var mat: StandardMaterial3D = dead_ground.material_override as StandardMaterial3D
        mat.albedo_color = Color(0.30, 0.27, 0.29).lerp(Color(0.34, 0.58, 0.34), bloom)
    for i in range(flowers.size()):
        var f: Node3D = flowers[i]
        var threshold: float = float(i) / max(1.0, float(flowers.size() - 1))
        var life: float = clamp((bloom - threshold * 0.72) * 5.0, 0.0, 1.0)
        f.scale = Vector3.ONE * max(0.001, life)
    if seed_shrine:
        seed_shrine.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.04)

func _build_foliage() -> void:
    var palette: Array[Color] = [Color("f1a9c2"), Color("d8b2ff"), Color("f7df8d"), Color("9fd4ff")]
    for i in range(95):
        var angle: float = rng.randf_range(0.0, TAU)
        var radius: float = rng.randf_range(2.8, 11.8)
        var p := Vector3(cos(angle) * radius, 0.22, sin(angle) * radius)
        if p.distance_to(seed_shrine.position) < 1.7:
            continue
        var flower := Node3D.new()
        flower.position = p
        flower.scale = Vector3.ONE * 0.001
        add_child(flower)
        var stem := MeshInstance3D.new()
        var stem_mesh := CylinderMesh.new()
        stem_mesh.top_radius = 0.025
        stem_mesh.bottom_radius = 0.035
        stem_mesh.height = rng.randf_range(0.28, 0.48)
        stem.mesh = stem_mesh
        stem.position.y = stem_mesh.height * 0.5
        var stem_mat := StandardMaterial3D.new()
        stem_mat.albedo_color = Color("4d8a58")
        stem.material_override = stem_mat
        flower.add_child(stem)
        var blossom := MeshInstance3D.new()
        var blossom_mesh := SphereMesh.new()
        blossom_mesh.radius = rng.randf_range(0.09, 0.15)
        blossom_mesh.height = blossom_mesh.radius * 1.2
        blossom.mesh = blossom_mesh
        blossom.position.y = stem_mesh.height + 0.04
        blossom.scale = Vector3(1.3, 0.55, 1.3)
        var blossom_mat := StandardMaterial3D.new()
        blossom_mat.albedo_color = palette[i % palette.size()]
        blossom_mat.emission_enabled = true
        blossom_mat.emission = blossom_mat.albedo_color * 0.18
        blossom.material_override = blossom_mat
        flower.add_child(blossom)
        flowers.append(flower)

func _build_birds() -> void:
    for i in range(4):
        var bird := Node3D.new()
        add_child(bird)
        for side in [-1.0, 1.0]:
            var wing := MeshInstance3D.new()
            var mesh := BoxMesh.new()
            mesh.size = Vector3(0.34, 0.035, 0.13)
            wing.mesh = mesh
            wing.position.x = 0.18 * side
            wing.rotation.z = 0.35 * side
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color("2f3540")
            wing.material_override = mat
            bird.add_child(wing)
        birds.append(bird)
