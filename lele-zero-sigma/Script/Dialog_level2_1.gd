extends DialogTrigger


func _init() -> void:
	auto_start = true
	is_tutorial = true
	lines = [
		{"text": "Setiap lantai menara ini memberikan buff, yaitu tambahan status untuk Zeke."},
		{"text": "Di awal setiap lantai, pilih 1 dari 3 buff yang tersedia."},
		{"text": "Buff yang muncul berbeda-beda, tergantung karakteristik masing-masing lantai."},
		{"text": "Hanya satu buff yang bisa diambil, jadi pilihlah dengan baik."},
	]
