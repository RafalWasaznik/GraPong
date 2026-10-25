extends "res://paletka_bazowa.gd"

var nieprzewidywalny_czas = 0.0
var nieprzewidywalne_odchylenie = 0.0
var czas_do_reakcji = 0.0
var czas_do_zmiany_bledu = 0.0
var odchylenie_celowania = 0.0
@onready var zapamietany_cel_y: float = position.y

const GRUBOSC_SCIANY = 20.0
const KROK_PREDYKCJI = 1.0 / 120.0
const MAKS_CZAS_PREDYKCJI = 4.0
const PROMIEN_SCIANY_SRODKA = 54.0
const SZEROKOSC_SCIANY_SRODKA = 10.0
const MNOZNIK_STREFY_PREDYKCJI = 1.05


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
	var predkosc_bota = 370.0
	var margines = 5.0
	var blad_celowania = 90.0
	var czas_reakcji = 0.35

	match Ustawienia.trudnosc:
		"latwy":
			predkosc_bota = 290.0
			margines = 12.0
			blad_celowania = 110.0
			czas_reakcji = 0.42
		"sredni":
			predkosc_bota = 355.0
			margines = 10.0
			blad_celowania = 100.0
			czas_reakcji = 0.37
		"trudny":
			predkosc_bota = 395.0
			margines = 8.0
			blad_celowania = 82.0
			czas_reakcji = 0.30
		"niemozliwy":
			predkosc_bota = 450.0
			margines = 4.0
			blad_celowania = 75.0
			czas_reakcji = 0.28

	var pilka_cel = _wybierz_nadlatujaca_pilke()
	var nadlatuje = pilka_cel != null
	# Utrzymuj błąd dłużej, żeby kolejne korekty nie uśredniały go do zera.
	czas_do_zmiany_bledu -= delta
	if czas_do_zmiany_bledu <= 0.0:
		odchylenie_celowania = randf_range(-blad_celowania, blad_celowania)
		czas_do_zmiany_bledu = randf_range(0.8, 1.2)
	czas_do_reakcji -= delta
	var aktualizacja_celu = czas_do_reakcji <= 0.0
	if aktualizacja_celu:
		zapamietany_cel_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
		if nadlatuje:
			zapamietany_cel_y = _przewidz_przeciecie_y(pilka_cel) + odchylenie_celowania
		czas_do_reakcji = czas_reakcji * randf_range(0.85, 1.15)
	var przewidziane_y = zapamietany_cel_y
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
	if aktualizacja_celu and nadlatuje and not dash_aktywne and dash_odnowienie <= 0.0:
		var lot = _symuluj_lot_pilki(pilka_cel, position.x)
		var czas_do_paletki = float(lot["czas"])
		var blisko_bramki = bool(lot["nadlatuje"]) and czas_do_paletki < 0.4
		if blisko_bramki and czas_do_paletki > 0.0 and czas_do_paletki < 0.4:
			var roznica_zagrozenia = przewidziane_y - position.y
			var kierunek_ratunku = signf(roznica_zagrozenia)
			var minimum_y = Ustawienia.gorna_granica + polowa_paletki
			var maksimum_y = Ustawienia.dolna_granica - polowa_paletki
			var zasieg_dasha = minf(ODLEGLOSC_DASHU, (maksimum_y - minimum_y) * 0.8)
			var cel_dasha = clampf(position.y + kierunek_ratunku * zasieg_dasha, minimum_y, maksimum_y)
			var pozycja_z_dashem = position.y
			# Oszacuj zwykły ruch do zapamiętanego celu, wraz ze zwalnianiem.
			var krok_ruchu = minf(maxf(delta, 0.001), czas_do_paletki)
			var pozycja_bez_dasha = position.y
			var czas_ruchu = czas_do_paletki
			while czas_ruchu > 0.0:
				var krok = minf(krok_ruchu, czas_ruchu)
				var pozostala_roznica = cel_y - pozycja_bez_dasha
				var predkosc_ruchu = minf(predkosc_bota, absf(pozostala_roznica) / maxf(czas_reakcji, delta))
				pozycja_bez_dasha += signf(pozostala_roznica) * predkosc_ruchu * krok
				czas_ruchu = maxf(0.0, czas_ruchu - krok)
				var uplynelo = czas_do_paletki - czas_ruchu
				if uplynelo - krok < CZAS_DASHU:
					var postep = minf(uplynelo / CZAS_DASHU, 1.0)
					pozycja_z_dashem = lerpf(position.y, cel_dasha, postep * postep * (3.0 - 2.0 * postep))
				var krok_po_dashu = minf(krok, maxf(0.0, uplynelo - CZAS_DASHU))
				var roznica_po_dashu = cel_y - pozycja_z_dashem
				pozycja_z_dashem += signf(roznica_po_dashu) * minf(predkosc_bota, absf(roznica_po_dashu) / maxf(czas_reakcji, delta)) * krok_po_dashu
			var zasieg_odbicia = polowa_paletki + pilka_cel.promien_aktualny()
			var poza_zasiegiem = absf(przewidziane_y - pozycja_bez_dasha) > zasieg_odbicia
			var dash_ratuje = absf(przewidziane_y - pozycja_z_dashem) <= zasieg_odbicia
			if poza_zasiegiem and dash_ratuje and not is_equal_approx(cel_dasha, position.y):
				_rozpocznij_dash(kierunek_ratunku)

	if nadlatuje or absf(roznica) > margines:
		var predkosc_ruchu = minf(predkosc_bota, absf(roznica) / maxf(czas_reakcji, delta))
		return signf(roznica) * predkosc_ruchu
	return 0.0


func _wybierz_nadlatujaca_pilke() -> CharacterBody2D:
	var wybrana_pilka: CharacterBody2D = null
	var najkrotszy_czas = INF

	for kandydat in get_tree().get_nodes_in_group("pilki"):
		if not is_instance_valid(kandydat):
			continue
		var lot = _symuluj_lot_pilki(kandydat, position.x)
		if not bool(lot["nadlatuje"]):
			continue
		var czas_do_paletki = float(lot["czas"])
		if czas_do_paletki < 0.0 or czas_do_paletki >= najkrotszy_czas:
			continue
		najkrotszy_czas = czas_do_paletki
		wybrana_pilka = kandydat

	return wybrana_pilka


func _symuluj_lot_pilki(pilka: CharacterBody2D, cel_x: float) -> Dictionary:
	var gra := get_parent() as GraPongAPI
	var arena := gra.menedzer_areny() if gra != null else null
	var pozycja = pilka.position
	var predkosc = pilka.velocity
	var czas = 0.0
	var promien = pilka.promien_aktualny()
	var byla_w_strefie = bool(pilka.get_meta("w_strefie_przyspieszenia", false))
	var cel_w_prawo = cel_x > pozycja.x
	for _krok in range(int(MAKS_CZAS_PREDYKCJI / KROK_PREDYKCJI)):
		var mnoznik = pilka.mnoznik_ruchu_chwilowy()
		if arena != null and arena.przyspieszenie_y(predkosc.x) != 0.0:
			var kat = arena.przyspieszenie_y(predkosc.x) / maxf(absf(predkosc.x), 1.0) * KROK_PREDYKCJI
			predkosc = predkosc.rotated(kat)
		var nowa_strefa = arena != null and arena.strefa_przyspieszenia_aktywna() and absf(pozycja.x - (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5) <= 52.0
		if nowa_strefa and not byla_w_strefie:
			predkosc *= MNOZNIK_STREFY_PREDYKCJI
		byla_w_strefie = nowa_strefa
		var poprzednia = pozycja
		pozycja += predkosc * mnoznik * KROK_PREDYKCJI
		var gora = Ustawienia.gorna_granica + GRUBOSC_SCIANY + promien
		var dol = Ustawienia.dolna_granica - GRUBOSC_SCIANY - promien
		if pozycja.y < gora or pozycja.y > dol:
			pozycja.y = clampf(pozycja.y, gora, dol)
			predkosc.y = absf(predkosc.y) if pozycja.y == gora else -absf(predkosc.y)
		if arena != null and arena.sciana_srodka_aktywna():
			var srodek = Vector2((Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5, (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5)
			var odleglosc = pozycja.distance_to(srodek)
			if odleglosc <= PROMIEN_SCIANY_SRODKA + promien + SZEROKOSC_SCIANY_SRODKA * 0.5:
				var normalna = (pozycja - srodek).normalized()
				pozycja = srodek + normalna * (PROMIEN_SCIANY_SRODKA + promien + SZEROKOSC_SCIANY_SRODKA * 0.5)
				predkosc = predkosc.bounce(normalna)
		if arena != null and arena.bramka_aktywna():
			for segment in arena.dane_bramki():
				var rozszerzony = segment.grow(promien)
				if rozszerzony.has_point(pozycja) or rozszerzony.has_point(poprzednia):
					pozycja.x = segment.position.x - promien if predkosc.x > 0.0 else segment.end.x + promien
					predkosc.x = -predkosc.x
					break
		czas += KROK_PREDYKCJI
		if (cel_w_prawo and predkosc.x > 0.0 and pozycja.x >= cel_x) or (not cel_w_prawo and predkosc.x < 0.0 and pozycja.x <= cel_x):
			return {"y": pozycja.y, "czas": czas, "nadlatuje": cel_w_prawo and predkosc.x > 0.0}
	return {"y": pozycja.y, "czas": INF, "nadlatuje": false}


func _przewidz_przeciecie_y(pilka: CharacterBody2D) -> float:
	var lot = _symuluj_lot_pilki(pilka, position.x)
	if bool(lot["nadlatuje"]):
		return float(lot["y"])
	var roznica_x = position.x - pilka.position.x
	var mnoznik = pilka.mnoznik_ruchu_chwilowy()
	var czas_do_paletki = maxf(0.0, roznica_x / maxf(pilka.velocity.x * mnoznik, 1.0))
	var przyspieszenie_y = 0.0
	if Ustawienia.tryb == "arena":
		var gra := get_parent() as GraPongAPI
		var manager_areny := gra.menedzer_areny() if gra != null else null
		if manager_areny != null:
			przyspieszenie_y = manager_areny.przyspieszenie_y(pilka.velocity.x)
	var przewidziane_y = pilka.position.y + pilka.velocity.y * mnoznik * czas_do_paletki
	var promien = pilka.promien_aktualny()
	var gora = Ustawienia.gorna_granica + GRUBOSC_SCIANY + promien
	var dol = Ustawienia.dolna_granica - GRUBOSC_SCIANY - promien
	var zakres = maxf(dol - gora, 1.0)
	if not is_zero_approx(przyspieszenie_y) and pilka.velocity.x > 0.0 and roznica_x > 0.0:
		# Wiatr obraca prędkość, a po odbiciu nadal działa w tym samym kierunku.
		var predkosc = pilka.velocity.length()
		var predkosc_przewidywana = pilka.velocity
		var pozycja_przewidywana = pilka.position
		var predkosc_katowa = przyspieszenie_y / pilka.velocity.x
		var minimalna_x = predkosc * cos(ArenaManager.MAKS_KAT_ZAKRETU)
		var pozostaly_czas = roznica_x / maxf(minimalna_x * mnoznik, 0.001)
		var krok_symulacji = maxf(1.0 / 120.0, pozostaly_czas / 512.0)
		for _krok in range(513):
			if pozostaly_czas <= 0.0 or pozycja_przewidywana.x >= position.x:
				break
			var krok = minf(krok_symulacji, pozostaly_czas)
			predkosc_przewidywana = predkosc_przewidywana.rotated(predkosc_katowa * krok)
			if predkosc_przewidywana.x < minimalna_x:
				var kierunek_y = signf(predkosc_przewidywana.y)
				if kierunek_y == 0.0:
					kierunek_y = signf(przyspieszenie_y)
				predkosc_przewidywana = Vector2(minimalna_x, kierunek_y * predkosc * sin(ArenaManager.MAKS_KAT_ZAKRETU))
			krok = minf(krok, (position.x - pozycja_przewidywana.x) / maxf(predkosc_przewidywana.x * mnoznik, 0.001))
			pozycja_przewidywana += predkosc_przewidywana * mnoznik * krok
			var zawiniete_y = fposmod(pozycja_przewidywana.y - gora, zakres * 2.0)
			if zawiniete_y > zakres:
				pozycja_przewidywana.y = dol - (zawiniete_y - zakres)
				predkosc_przewidywana.y = -predkosc_przewidywana.y
			else:
				pozycja_przewidywana.y = gora + zawiniete_y
			pozostaly_czas = maxf(0.0, pozostaly_czas - krok)
		return pozycja_przewidywana.y
	var pozycja_zawijana = fposmod(przewidziane_y - gora, zakres * 2.0)
	if pozycja_zawijana > zakres:
		return dol - (pozycja_zawijana - zakres)
	return gora + pozycja_zawijana
