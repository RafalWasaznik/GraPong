extends "res://paletka_bazowa.gd"

const PROMIEN_PILKI = 13.0

var nieprzewidywalny_czas = 0.0
var nieprzewidywalne_odchylenie = 0.0
func _kolor_paletki() -> Color:
	return Color("#ff647a")


func _glosnosc_dasha() -> float:
	return -9.0


func _ton_dasha() -> float:
	return 0.92


func _physics_process(delta: float) -> void:
	if Ustawienia.tryb == "online":
		if not Siec.czy_host():
			return
		var kierunek_online = sieciowy_kierunek
		if not is_zero_approx(kierunek_online):
			ostatni_kierunek = signf(kierunek_online)
		if sieciowy_dash_zadany and dash_odnowienie <= 0.0:
			var kierunek_dashu_online = signf(kierunek_online) if not is_zero_approx(kierunek_online) else ostatni_kierunek
			_rozpocznij_dash(kierunek_dashu_online)
		sieciowy_dash_zadany = false
		wykonaj_ruch(delta, kierunek_online * SPEED_PALETKI)
		return

	var docelowa_predkosc_y = 0.0
	if Ustawienia.tryb == "2graczy" or (Ustawienia.tryb == "arena" and Ustawienia.arena_dwoch_graczy):
		var kierunek = Input.get_axis("prawy_gora", "prawy_dol")
		if not is_zero_approx(kierunek):
			ostatni_kierunek = signf(kierunek)
		if Input.is_action_just_pressed("dash_gracza_2") and dash_odnowienie <= 0.0:
			var kierunek_dashu = signf(kierunek) if not is_zero_approx(kierunek) else ostatni_kierunek
			_rozpocznij_dash(kierunek_dashu)
		docelowa_predkosc_y = kierunek * SPEED_PALETKI
	else:
		docelowa_predkosc_y = _wyznacz_ruch_bota(delta)

	wykonaj_ruch(delta, docelowa_predkosc_y)


func _wyznacz_ruch_bota(delta: float) -> float:
	var predkosc_bota = 500.0
	var margines = 5.0

	match Ustawienia.trudnosc:
		"latwy":
			predkosc_bota = 350.0
			margines = 16.0
		"sredni":
			predkosc_bota = 450.0
			margines = 12.0
		"trudny":
			predkosc_bota = 550.0
			margines = 6.0
		"niemozliwy":
			predkosc_bota = 650.0
			margines = 0.0

	var pilka_cel = _wybierz_nadlatujaca_pilke()
	var nadlatuje = pilka_cel != null
	var przewidziane_y = _przewidz_przeciecie_y(pilka_cel) if nadlatuje else (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
	var cel_y = przewidziane_y

	match Ustawienia.charakter_bota:
		"defensywny":
			if not nadlatuje:
				cel_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5

		"ofensywny":
			if nadlatuje:
				var polowa_do_ostrego_odbicia = _polowa_wysokosci_paletki()
				var trafienie_celowe = 0.72 if przewidziane_y < (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5 else -0.72
				cel_y -= trafienie_celowe * polowa_do_ostrego_odbicia
			else:
				cel_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5

		"agresywny":
			if not nadlatuje:
				cel_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5

		"nieprzewidywalny":
			nieprzewidywalny_czas -= delta
			if nieprzewidywalny_czas <= 0.0:
				var maksymalne_odchylenie = 58.0
				match Ustawienia.trudnosc:
					"sredni":
						maksymalne_odchylenie = 46.0
					"trudny":
						maksymalne_odchylenie = 34.0
					"niemozliwy":
						maksymalne_odchylenie = 22.0
				nieprzewidywalne_odchylenie = randf_range(-maksymalne_odchylenie, maksymalne_odchylenie)
				nieprzewidywalny_czas = randf_range(0.7, 1.5)
			cel_y += nieprzewidywalne_odchylenie if nadlatuje else nieprzewidywalne_odchylenie * 0.35

	var polowa_paletki = _polowa_wysokosci_paletki()
	cel_y = clampf(cel_y, Ustawienia.gorna_granica + polowa_paletki, Ustawienia.dolna_granica - polowa_paletki)
	var roznica = cel_y - position.y
	if nadlatuje and dash_odnowienie <= 0.0:
		var czas_do_paletki = maxf(0.0, (position.x - pilka_cel.position.x) / maxf(pilka_cel.velocity.x * pilka_cel.mnoznik_ruchu_chwilowy(), 1.0))
		var prog_dasha = polowa_paletki + predkosc_bota * czas_do_paletki + 35.0
		if czas_do_paletki > CZAS_DASHU * 1.5 and czas_do_paletki < 0.65 and absf(roznica) > prog_dasha:
			_rozpocznij_dash(signf(roznica))

	if absf(roznica) > margines:
		var predkosc_ruchu = minf(predkosc_bota, absf(roznica) / maxf(delta, 0.001))
		return signf(roznica) * predkosc_ruchu
	return 0.0


func _wybierz_nadlatujaca_pilke() -> CharacterBody2D:
	var wybrana_pilka: CharacterBody2D = null
	var najkrotszy_czas = INF

	for kandydat in get_tree().get_nodes_in_group("pilki"):
		if not is_instance_valid(kandydat):
			continue
		if kandydat.velocity.x <= 0.0:
			continue

		var predkosc_pozioma = kandydat.velocity.x * kandydat.mnoznik_ruchu_chwilowy()
		var czas_do_paletki = (position.x - kandydat.position.x) / predkosc_pozioma
		if czas_do_paletki < 0.0:
			continue
		if czas_do_paletki < najkrotszy_czas:
			najkrotszy_czas = czas_do_paletki
			wybrana_pilka = kandydat

	return wybrana_pilka


func _przewidz_przeciecie_y(pilka: CharacterBody2D) -> float:
	var roznica_x = position.x - pilka.position.x
	var mnoznik = pilka.mnoznik_ruchu_chwilowy()
	var czas_do_paletki = maxf(0.0, roznica_x / maxf(pilka.velocity.x * mnoznik, 1.0))
	var przyspieszenie_y = 0.0
	if Ustawienia.tryb == "arena":
		var gra := get_parent() as GraPongAPI
		var manager_areny := gra.menedzer_areny() if gra != null else null
		if manager_areny != null:
			przyspieszenie_y = manager_areny.przyspieszenie_y(pilka.velocity.x)
	var przewidziane_y = pilka.position.y + pilka.velocity.y * mnoznik * czas_do_paletki + 0.5 * przyspieszenie_y * czas_do_paletki * czas_do_paletki
	var gora = Ustawienia.gorna_granica + PROMIEN_PILKI
	var dol = Ustawienia.dolna_granica - PROMIEN_PILKI
	var zakres = maxf(dol - gora, 1.0)
	var pozycja_zawijana = fposmod(przewidziane_y - gora, zakres * 2.0)
	if pozycja_zawijana > zakres:
		return dol - (pozycja_zawijana - zakres)
	return gora + pozycja_zawijana
