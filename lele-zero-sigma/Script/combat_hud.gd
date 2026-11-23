extends Control
## Menampilkan sisa musuh dan fase dari Combat area yang sedang aktif.
## Hanya MEMBACA variabel Combat, jadi combat_area.gd tidak perlu diubah.

@export var enemy_label: Label
@export var phase_label: Label
## Kalau true, teks disamarkan saat tidak ada pertarungan berlangsung.
@export var hide_when_idle := false


func _process(_delta: float) -> void:
	var combat := _find_active_combat()
	if combat == null:
		# Tidak ada pertarungan aktif: teks terakhir dibiarkan (mis. "Phase 2 / 0" setelah selesai)
		_set_labels_alpha(0.0 if hide_when_idle else 1.0)
		return

	_set_labels_alpha(1.0)
	# Combat memasukkan musuh ke grup Phase_1_Enemy / Phase_2_Enemy sesuai fase
	var enemies := get_tree().get_nodes_in_group("Phase_%d_Enemy" % combat.phase)
	enemy_label.text = "Enemy left: %d" % enemies.size()
	phase_label.text = "Phase %d" % combat.phase


func _find_active_combat() -> Combat:
	# Combat menambahkan dirinya ke grup "NoContactDamage" di _ready()
	for node in get_tree().get_nodes_in_group("NoContactDamage"):
		if node is Combat and node.is_combat:
			return node
	return null


func _set_labels_alpha(a: float) -> void:
	enemy_label.modulate.a = a
	phase_label.modulate.a = a
