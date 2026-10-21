class_name ArenaManager
extends ArenaManagerAPI

const CZAS_OSTRZEZENIA = 3.0
const PRZESUNIECIE_SCIAN = 48.0
const POSZERZENIE_ARENY_X = 40.0
const POSZERZENIE_ARENY_Y = 32.0
const PREDKOSC_ZAKRETU = 0.65
const MNOZNIK_PREDKOSCI = 1.12
const SILA_PRZYCIAGANIA_DO_SRODKA = 560.0
const SZEROKOSC_STREFY = 104.0
const MNOZNIK_STREFY = 1.05
const MAKS_KAT_ZAKRETU = deg_to_rad(72.0)

const CZAS_WYGASZANIA_PO_PUNKCIE = 0.20
const CZAS_PRZYWRACANIA_PO_PUNKCIE = 0.45

const KATALOG = preload("res://arena_katalog.gd")

var gra: GraPongAPI
var tryb_zdalny = false
var stan = "oczekiwanie"
var czas_do_zmiany = 0.0
var aktywne_wydarzenie = ""
var drugie_wydarzenie = ""
var poprzednie_wydarzenie = ""
var kierunek_wiatru = 1.0
var bazowa_lewa = 0.0
var bazowa_prawa = 0.0
var bazowa_gora = 0.0
var bazowy_dol = 0.0
var wariant_bramki = ""
var sciana_srodka: ScianaSrodkaArena
var ruchoma_sciana: RuchomaScianaArena


func uruchom(gra_glowna: GraPongAPI, zdalny: bool = false, oczekuj_na_gracza: bool = false) -> void:
	gra = gra_glowna
	sciana_srodka = ScianaSrodkaArena.new()
	sciana_srodka.name = "ScianaSrodka"
	add_child(sciana_srodka)
	sciana_srodka.uruchom(gra)
	ruchoma_sciana = RuchomaScianaArena.new()
	ruchoma_sciana.name = "RuchomaSciana"
	add_child(ruchoma_sciana)
	ruchoma_sciana.uruchom(gra, zdalny)
	tryb_zdalny = zdalny
	bazowa_gora = Ustawienia.gorna_granica
	bazowy_dol = Ustawienia.dolna_granica
	bazowa_lewa = Ustawienia.lewa_granica
	bazowa_prawa = Ustawienia.prawa_granica
	stan = "oczekiwanie"
	aktywne_wydarzenie = ""
	drugie_wydarzenie = ""
	czas_do_zmiany = randf_range(7.0, 10.0)
	set_process(not zdalny and not oczekuj_na_gracza)
	set_physics_process(zdalny or not oczekuj_na_gracza)
	gra.pokaz_informacje_graczowi("TRYB ARENA", "Uważaj na zmieniające się warunki gry", Color("#72e0f2"), 4.0)


func rozpocznij() -> void:
	if tryb_zdalny:
		return
	set_process(true)
	set_physics_process(true)


func dane_sieciowe() -> Dictionary:
	var stan_sieciowy := {
		"stan": stan,
		"czas": czas_do_zmiany,
		"wydarzenie": aktywne_wydarzenie,
		"drugie": drugie_wydarzenie,
		"wiatr": kierunek_wiatru,
		"wariant_bramki": wariant_bramki
	}
	stan_sieciowy.merge(ruchoma_sciana.dane_sieciowe())
	return stan_sieciowy


func ustaw_stan_zdalny(dane: Dictionary) -> void:
	if not tryb_zdalny:
		return
	var nowy_stan = str(dane.get("stan", "oczekiwanie"))
	var nowe_wydarzenie = str(dane.get("wydarzenie", ""))
	var nowe_drugie = str(dane.get("drugie", ""))
	var nowy_wariant = str(dane.get("wariant_bramki", ""))
	var zmieniono_wydarzenie = stan != nowy_stan or aktywne_wydarzenie != nowe_wydarzenie or drugie_wydarzenie != nowe_drugie or wariant_bramki != nowy_wariant
	if zmieniono_wydarzenie and stan == "aktywne":
		_przywroc_efekty_modyfikatorow(0.8)
	stan = nowy_stan
	aktywne_wydarzenie = nowe_wydarzenie
	drugie_wydarzenie = nowe_drugie
	wariant_bramki = nowy_wariant
	kierunek_wiatru = float(dane.get("wiatr", 1.0))
	czas_do_zmiany = float(dane.get("czas", 0.0))
	if zmieniono_wydarzenie and stan == "aktywne":
		gra.odtworz_dzwiek_modyfikatora()
		_zastosuj_modyfikatory_zdalne()
	if zmieniono_wydarzenie and stan == "ostrzezenie":
		gra.pokaz_informacje_graczowi(_nazwa_aktywnych_modyfikatorow(), _opis_aktywnych_modyfikatorow(), Color("#ffb454"), CZAS_OSTRZEZENIA)
	ruchoma_sciana.ustaw_stan_zdalny(dane, wariant_bramki)
	set_physics_process(tryb_zdalny and ruchoma_sciana.istnieje())
	gra._odswiez_rysowanie()


func _zastosuj_modyfikatory_zdalne() -> void:
	for modyfikator in _aktywne_modyfikatory():
		_aktywuj_modyfikator(modyfikator, true)


func _process(delta: float) -> void:
	czas_do_zmiany -= delta

	match stan:
		"oczekiwanie":
			if czas_do_zmiany <= CZAS_OSTRZEZENIA:
				_zapowiedz_wydarzenie()
		"ostrzezenie":
			if czas_do_zmiany <= 0.0:
				_rozpocznij_wydarzenie()
		"aktywne":
			if czas_do_zmiany <= 0.0:
				_zakoncz_wydarzenie()


func _physics_process(delta: float) -> void:
	ruchoma_sciana.aktualizuj(delta, stan == "aktywne" and _czy_aktywne("ruchoma_bramka"))


func _losuj_wydarzenie() -> String:
	var mozliwe = KATALOG.DEFINICJE_MODYFIKATOROW.keys()
	mozliwe.erase(poprzednie_wydarzenie)
	return str(mozliwe.pick_random())


func _zapowiedz_wydarzenie() -> void:
	aktywne_wydarzenie = _losuj_wydarzenie()
	drugie_wydarzenie = ""
	if randf() < 0.30:
		var mozliwe_drugie = KATALOG.DEFINICJE_MODYFIKATOROW.keys()
		mozliwe_drugie.erase(aktywne_wydarzenie)
		for kandydat in mozliwe_drugie.duplicate():
			if not KATALOG.para_kompatybilna(aktywne_wydarzenie, str(kandydat)):
				mozliwe_drugie.erase(kandydat)
		if not mozliwe_drugie.is_empty():
			drugie_wydarzenie = str(mozliwe_drugie.pick_random())
	if aktywne_wydarzenie == "wiatr_gora" or drugie_wydarzenie == "wiatr_gora":
		kierunek_wiatru = -1.0
	elif aktywne_wydarzenie == "wiatr_dol" or drugie_wydarzenie == "wiatr_dol":
		kierunek_wiatru = 1.0
	if aktywne_wydarzenie == "ruchoma_bramka" or drugie_wydarzenie == "ruchoma_bramka":
		wariant_bramki = ["fala", "podwojne_przejscie", "pulsujace_przejscie"].pick_random()
	else:
		wariant_bramki = ""
	stan = "ostrzezenie"
	czas_do_zmiany = CZAS_OSTRZEZENIA

	gra.pokaz_informacje_graczowi(_nazwa_aktywnych_modyfikatorow(), _opis_aktywnych_modyfikatorow(), Color("#ffb454"), CZAS_OSTRZEZENIA)


func _nazwa_aktywnych_modyfikatorow() -> String:
	var nazwy = PackedStringArray()
	for modyfikator in _aktywne_modyfikatory():
		nazwy.append(KATALOG.nazwa(modyfikator))
	return " + ".join(nazwy)


func _opis_aktywnych_modyfikatorow() -> String:
	var opisy = PackedStringArray()
	for modyfikator in _aktywne_modyfikatory():
		opisy.append(KATALOG.opis(modyfikator))
	return " ".join(opisy)


func _czy_aktywne(nazwa: String) -> bool:
	return aktywne_wydarzenie == nazwa or drugie_wydarzenie == nazwa


func _aktywne_modyfikatory() -> Array[String]:
	var wynik: Array[String] = []
	if not aktywne_wydarzenie.is_empty():
		wynik.append(aktywne_wydarzenie)
	if not drugie_wydarzenie.is_empty():
		wynik.append(drugie_wydarzenie)
	return wynik


func _czas_aktywnego_zestawu() -> float:
	var czas = 0.0
	for modyfikator in _aktywne_modyfikatory():
		czas = maxf(czas, float(KATALOG.definicja(modyfikator).get("czas", 0.0)))
	return czas


func _rozpocznij_wydarzenie() -> void:
	stan = "aktywne"
	if is_instance_valid(gra):
		gra.odtworz_dzwiek_modyfikatora()
	czas_do_zmiany = _czas_aktywnego_zestawu()
	for modyfikator in _aktywne_modyfikatory():
		_aktywuj_modyfikator(modyfikator)


func _aktywuj_modyfikator(modyfikator: String, zdalny: bool = false) -> void:
	match modyfikator:
		"waska_arena":
			gra.animuj_granice_areny(bazowa_gora + PRZESUNIECIE_SCIAN, bazowy_dol - PRZESUNIECIE_SCIAN, 0.8)
		"wieksza_arena":
			gra.animuj_wymiary_areny(bazowa_lewa - POSZERZENIE_ARENY_X, bazowa_prawa + POSZERZENIE_ARENY_X, bazowa_gora - POSZERZENIE_ARENY_Y, bazowy_dol + POSZERZENIE_ARENY_Y, 0.8)
		"strefa_przyspieszenia":
			if not zdalny:
				for pilka in get_tree().get_nodes_in_group("pilki"):
					pilka.set_meta("w_strefie_przyspieszenia", absf(pilka.position.x - _srodek_planszy_x()) <= SZEROKOSC_STREFY * 0.5)
			gra.animuj_strefe_przyspieszenia(true, 0.65)
		"krotsze_paletki":
			gra.animuj_wysokosc_paletek(0.72, 0.45)
		"duza_paletka":
			gra.animuj_wysokosc_paletek(1.28, 0.55)
		"duza_pilka":
			gra.animuj_rozmiar_pilki(1.35, 0.65)
		"sciana_srodka":
			_utworz_sciane_srodka()
		"mocne_sciany":
			gra._odswiez_rysowanie()
		"ruchoma_bramka":
			if not zdalny:
				ruchoma_sciana.aktywuj(wariant_bramki)


func _zakoncz_wydarzenie() -> void:
	# Jeśli punkt uruchomił już wygaszanie, poczekaj na jego koniec, żeby nie
	# usuwać bramki natychmiast przy granicy czasu wydarzenia.
	if _czy_aktywne("ruchoma_bramka") and ruchoma_sciana.istnieje():
		if not ruchoma_sciana.wygaszanie:
			_wygasz_bramke()
		return
	_przywroc_efekty_modyfikatorow(0.8)
	_ustaw_nastepne_wydarzenie()


func _przywroc_efekty_modyfikatorow(czas_animacji: float) -> void:
	for modyfikator in _aktywne_modyfikatory():
		_cofnij_modyfikator(modyfikator, czas_animacji)
	if is_instance_valid(gra):
		gra._odswiez_rysowanie()


func _cofnij_modyfikator(modyfikator: String, czas_animacji: float, wymus: bool = false) -> void:
	match modyfikator:
		"waska_arena":
			if is_instance_valid(gra):
				gra.animuj_granice_areny(bazowa_gora, bazowy_dol, czas_animacji)
		"wieksza_arena":
			if is_instance_valid(gra):
				gra.animuj_wymiary_areny(bazowa_lewa, bazowa_prawa, bazowa_gora, bazowy_dol, czas_animacji)
		"strefa_przyspieszenia":
			if is_instance_valid(gra):
				gra.animuj_strefe_przyspieszenia(false, czas_animacji)
		"krotsze_paletki", "duza_paletka":
			if is_instance_valid(gra):
				gra.animuj_wysokosc_paletek(1.0, czas_animacji)
		"duza_pilka":
			if is_instance_valid(gra):
				gra.animuj_rozmiar_pilki(1.0, czas_animacji)
		"sciana_srodka":
			if wymus:
				_usun_sciane_srodka()
			else:
				_wygasz_sciane_srodka()
		"mocne_sciany":
			if is_instance_valid(gra):
				gra._odswiez_rysowanie()
		"ruchoma_bramka":
			if wymus:
				ruchoma_sciana.zatrzymaj()
			elif ruchoma_sciana.istnieje():
				var czas_wygaszania = CZAS_WYGASZANIA_PO_PUNKCIE if czas_animacji <= CZAS_PRZYWRACANIA_PO_PUNKCIE else RuchomaScianaArena.CZAS_ZANIKANIA
				ruchoma_sciana.wygasz(czas_wygaszania)


func _ustaw_nastepne_wydarzenie(minimum: float = 3.5, maksimum: float = 6.0) -> void:
	if not aktywne_wydarzenie.is_empty():
		poprzednie_wydarzenie = aktywne_wydarzenie
	aktywne_wydarzenie = ""
	drugie_wydarzenie = ""
	stan = "oczekiwanie"
	czas_do_zmiany = randf_range(minimum, maksimum)


func po_zdobyciu_punktu() -> void:
	# Przerwij też zapowiedź, żeby modyfikator nie wystartował podczas nowej piłki.
	if stan == "aktywne":
		_przywroc_efekty_modyfikatorow(CZAS_PRZYWRACANIA_PO_PUNKCIE)
	_ustaw_nastepne_wydarzenie(6.0, 8.5)
	if is_instance_valid(gra):
		gra.ukryj_informacje_graczowi()


func mnoznik_predkosci() -> float:
	return MNOZNIK_PREDKOSCI if stan == "aktywne" and _czy_aktywne("przyspieszenie") else 1.0


func wzmocnij_odbicie_od_sciany(pilka: PilkaAPI, nazwa_sciany: String) -> void:
	if stan != "aktywne" or not _czy_aktywne("mocne_sciany"):
		return
	if nazwa_sciany not in ["górna ściana", "dolna ściana"]:
		return
	pilka.przyspiesz(1.05)
	pilka.pokaz_efekt_mocnego_odbicia()


func mocne_sciany_aktywne() -> bool:
	return stan == "aktywne" and _czy_aktywne("mocne_sciany")


func wieksza_arena_aktywna() -> bool:
	return stan == "aktywne" and _czy_aktywne("wieksza_arena")


func strefa_przyspieszenia_aktywna() -> bool:
	return stan == "aktywne" and _czy_aktywne("strefa_przyspieszenia")


func bramka_aktywna() -> bool:
	return ruchoma_sciana != null and ruchoma_sciana.aktywna() and (ruchoma_sciana.wygaszanie or (stan == "aktywne" and _czy_aktywne("ruchoma_bramka")))


func _wygasz_bramke(czas_wygaszania: float = RuchomaScianaArena.CZAS_ZANIKANIA) -> void:
	if ruchoma_sciana != null:
		ruchoma_sciana.wygasz(czas_wygaszania)


func dane_bramki() -> Array[Rect2]:
	return ruchoma_sciana.segmenty() if ruchoma_sciana != null and bramka_aktywna() else []


func przezroczystosc_bramki() -> float:
	return ruchoma_sciana.przezroczystosc() if ruchoma_sciana != null else 0.0


func przyspieszenie_y(predkosc_pozioma: float) -> float:
	if stan == "aktywne" and (_czy_aktywne("wiatr_gora") or _czy_aktywne("wiatr_dol")):
		return kierunek_wiatru * PREDKOSC_ZAKRETU * absf(predkosc_pozioma)
	return 0.0


func przygotuj_pilke(pilka: PilkaAPI, delta: float) -> float:
	if sciana_srodka_aktywna():
		sciana_srodka.aktualizuj_pozycje()
	if stan == "aktywne" and _czy_aktywne("strefa_przyspieszenia"):
		_obsluz_strefe_przyspieszenia(pilka)
	if stan == "aktywne" and _czy_aktywne("przyciaganie_srodka") and pilka.velocity.length_squared() > 0.0:
		var predkosc = pilka.velocity.length()
		var srodek = Vector2(_srodek_planszy_x(), (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5)
		var do_srodka = srodek - pilka.position
		if do_srodka.length_squared() > 0.0:
			pilka.velocity = (pilka.velocity + do_srodka.normalized() * SILA_PRZYCIAGANIA_DO_SRODKA * delta).normalized() * predkosc

	if stan == "aktywne" and (_czy_aktywne("wiatr_gora") or _czy_aktywne("wiatr_dol")) and pilka.velocity.length_squared() > 0.0:
		var predkosc = pilka.velocity.length()
		var kierunek_x = signf(pilka.velocity.x)
		var zakret = kierunek_wiatru * kierunek_x * PREDKOSC_ZAKRETU * delta
		var nowa_predkosc = pilka.velocity.rotated(zakret)
		var minimalna_skladowa_x = predkosc * cos(MAKS_KAT_ZAKRETU)

		# Piłka wyraźnie zakręca, ale wiatr nie zawraca jej całkowicie na drugą stronę.
		if signf(nowa_predkosc.x) != kierunek_x or absf(nowa_predkosc.x) < minimalna_skladowa_x:
			var kierunek_y = signf(nowa_predkosc.y)
			if kierunek_y == 0.0:
				kierunek_y = kierunek_wiatru
			nowa_predkosc = Vector2(
				kierunek_x * minimalna_skladowa_x,
				kierunek_y * predkosc * sin(MAKS_KAT_ZAKRETU)
			)

		pilka.velocity = nowa_predkosc
	return mnoznik_predkosci()


func _obsluz_strefe_przyspieszenia(pilka: PilkaAPI) -> void:
	var jest_w_strefie = absf(pilka.position.x - _srodek_planszy_x()) <= SZEROKOSC_STREFY * 0.5
	var byla_w_strefie = bool(pilka.get_meta("w_strefie_przyspieszenia", false))
	if jest_w_strefie and not byla_w_strefie:
		pilka.przyspiesz(MNOZNIK_STREFY)
		pilka.pokaz_efekt_strefy_przyspieszenia()
	pilka.set_meta("w_strefie_przyspieszenia", jest_w_strefie)


func _srodek_planszy_x() -> float:
	return (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5


func sciana_srodka_aktywna() -> bool:
	return sciana_srodka != null and sciana_srodka.aktywna()


func przezroczystosc_sciany_srodka() -> float:
	return sciana_srodka.przezroczystosc() if sciana_srodka != null else 0.0


func _utworz_sciane_srodka() -> void:
	if sciana_srodka != null:
		sciana_srodka.utworz()


func _usun_sciane_srodka() -> void:
	if sciana_srodka != null:
		sciana_srodka.zatrzymaj()


func _wygasz_sciane_srodka(czas: float = ScianaSrodkaArena.CZAS_ZANIKANIA) -> void:
	if sciana_srodka != null:
		sciana_srodka.wygasz(czas)


func zatrzymaj() -> void:
	set_process(false)
	set_physics_process(false)
	for modyfikator in _aktywne_modyfikatory():
		_cofnij_modyfikator(modyfikator, 0.3, true)
	if is_instance_valid(gra):
		gra._odswiez_rysowanie()
	stan = "zatrzymane"
	aktywne_wydarzenie = ""
	drugie_wydarzenie = ""
