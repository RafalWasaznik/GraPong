extends "res://paletka_bazowa.gd"


func _physics_process(delta: float) -> void:
	var lokalna_pauza_online = Ustawienia.tryb == "online" and Siec.pauza_lokalna
	var kierunek = 0.0 if lokalna_pauza_online else Input.get_axis("lewy_gora", "lewy_dol")
	if Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy):
		kierunek += Input.get_axis("prawy_gora", "prawy_dol")
	if not is_zero_approx(kierunek):
		ostatni_kierunek = signf(kierunek)
	if not lokalna_pauza_online and Input.is_action_just_pressed("dash_gracza_1") and dash_odnowienie <= 0.0:
		var kierunek_dashu = signf(kierunek) if not is_zero_approx(kierunek) else ostatni_kierunek
		_rozpocznij_dash(kierunek_dashu)
	var predkosc_y = clampf(kierunek, -1.0, 1.0) * SPEED_PALETKI
	wykonaj_ruch(delta, predkosc_y)
