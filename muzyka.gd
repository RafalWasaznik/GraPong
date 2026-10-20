extends Node

const SCIEZKA_MUZYKI = "res://muzyka_arcade.wav"
const DLUGOSC_MUZYKI = 32.0

var odtwarzacz: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Ustawienia.wczytaj()

	var strumien = load(SCIEZKA_MUZYKI) as AudioStreamWAV
	if strumien == null:
		push_error("Nie udało się wczytać muzyki: " + SCIEZKA_MUZYKI)
		return

	strumien.loop_mode = AudioStreamWAV.LOOP_FORWARD
	strumien.loop_begin = 0
	strumien.loop_end = int(strumien.mix_rate * DLUGOSC_MUZYKI)

	odtwarzacz = AudioStreamPlayer.new()
	odtwarzacz.name = "OdtwarzaczMuzyki"
	odtwarzacz.bus = &"Muzyka"
	odtwarzacz.stream = strumien
	add_child(odtwarzacz)
	odtwarzacz.play()
