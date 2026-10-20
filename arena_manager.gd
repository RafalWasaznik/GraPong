extends Node

const CZAS_OSTRZEZENIA = 3.0
const CZAS_AKTYWNEGO_WYDARZENIA = 5.5
const CZAS_KROTSZYCH_PALETEK = 8.0
const PRZESUNIECIE_SCIAN = 48.0
const POSZERZENIE_ARENY_X = 40.0
const POSZERZENIE_ARENY_Y = 32.0
const PREDKOSC_ZAKRETU = 0.65
const MNOZNIK_PREDKOSCI = 1.12
const SILA_PRZYCIAGANIA_DO_SRODKA = 560.0
const SZEROKOSC_STREFY = 104.0
const MNOZNIK_STREFY = 1.05
const MAKS_KAT_ZAKRETU = deg_to_rad(72.0)

const SZEROKOSC_BRAMKI = 20.0
const WYSOKOSC_OTWORU_BRAMKI = 156.0
const PREDKOSC_RUCHU_BRAMKI = 1.35
const CZAS_RUCHOMEJ_BRAMKI = 9.0
const CZAS_POJAWIENIA_BRAMKI = 0.7
const CZAS_ZANIKANIA_BRAMKI = 0.85
const CZAS_WYGASZANIA_PO_PUNKCIE = 0.45
const WYSOKOSC_PODWOJNEGO_OTWORU = 104.0
const ODSTEP_PODWOJNYCH_OTWOROW = 166.0
const PROMIEN_SCIANY_SRODKOWEJ = 54.0
const SZEROKOSC_SCIANY_SRODKOWEJ = 10.0
const LICZBA_SEGMENTOW_SCIANY_SRODKOWEJ = 48

const WYDARZENIA = ["wiatr_gora", "wiatr_dol", "przyspieszenie", "przyciaganie_srodka", "sciana_srodka", "waska_arena", "strefa_przyspieszenia", "krotsze_paletki", "duza_paletka", "duza_pilka", "mocne_sciany", "wieksza_arena", "ruchoma_bramka"]
const NIEKOMPATYBILNE_PARY = {
	# Przeciwne kierunki tego samego wiatru.
	"wiatr_gora": ["wiatr_dol"],
	"wiatr_dol": ["wiatr_gora"],
	# Oba wydarzenia sterują tymi samymi granicami planszy.
	"waska_arena": ["wieksza_arena"],
	"wieksza_arena": ["waska_arena"],
	# Oba wydarzenia używają jednego tweena wysokości paletek.
	"krotsze_paletki": ["duza_paletka"],
	"duza_paletka": ["krotsze_paletki"],
	# Obie modyfikacje nakładają przeszkody w tej samej części planszy.
	"sciana_srodka": ["ruchoma_bramka"],
	"ruchoma_bramka": ["sciana_srodka"]
}

var gra: Node2D
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
var bramka_cialo: AnimatableBody2D
var bramka_kolizje: Array[CollisionShape2D] = []
var bramka_ksztalty: Array[RectangleShape2D] = []
var bramka_faza = 0.0
var bramka_postep = 0.0
var bramka_czas_aktywna = 0.0
var bramka_kolizje_wlaczone = false
var bramka_wygaszanie = false
var bramka_czas_wygaszania = 0.0
var bramka_alfa_poczatkowa = 0.0
var bramka_czas_wygaszania_docelowy = CZAS_ZANIKANIA_BRAMKI
var wariant_bramki = ""
var sciana_srodka: StaticBody2D


func uruchom(gra_glowna: Node2D, zdalny: bool = false, oczekuj_na_gracza: bool = false) -> void:
	gra = gra_glowna
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
	gra.call("pokaz_informacje_graczowi", "TRYB ARENA", "Uważaj na zmieniające się warunki gry", Color("#72e0f2"), 4.0)


func rozpocznij() -> void:
	if tryb_zdalny:
		return
	set_process(true)
	set_physics_process(true)


func dane_sieciowe() -> Dictionary:
	return {
		"stan": stan,
		"czas": czas_do_zmiany,
		"wydarzenie": aktywne_wydarzenie,
		"drugie": drugie_wydarzenie,
		"wiatr": kierunek_wiatru,
		"wariant_bramki": wariant_bramki,
		"bramka": is_instance_valid(bramka_cialo),
		"bramka_faza": bramka_faza,
		"bramka_czas": bramka_czas_aktywna,
		"bramka_postep": bramka_postep,
		"bramka_wygaszanie": bramka_wygaszanie,
		"bramka_czas_wygaszania": bramka_czas_wygaszania,
		"bramka_alfa_poczatkowa": bramka_alfa_poczatkowa,
		"bramka_czas_docelowy": bramka_czas_wygaszania_docelowy
	}


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
		gra.call("odtworz_dzwiek_modyfikatora")
		_zastosuj_modyfikatory_zdalne()
	if zmieniono_wydarzenie and stan == "ostrzezenie":
		var tytul = _nazwa_wydarzenia(aktywne_wydarzenie)
		if not drugie_wydarzenie.is_empty():
			tytul += " + " + _nazwa_wydarzenia(drugie_wydarzenie)
		gra.call("pokaz_informacje_graczowi", tytul, "", Color("#ffb454"), CZAS_OSTRZEZENIA)
	if bool(dane.get("bramka", false)):
		if not is_instance_valid(bramka_cialo):
			_utworz_bramke()
		bramka_faza = float(dane.get("bramka_faza", 0.0))
		bramka_czas_aktywna = float(dane.get("bramka_czas", 0.0))
		bramka_postep = float(dane.get("bramka_postep", 0.0))
		bramka_wygaszanie = bool(dane.get("bramka_wygaszanie", false))
		bramka_czas_wygaszania = float(dane.get("bramka_czas_wygaszania", 0.0))
		bramka_alfa_poczatkowa = float(dane.get("bramka_alfa_poczatkowa", bramka_postep))
		bramka_czas_wygaszania_docelowy = float(dane.get("bramka_czas_docelowy", CZAS_ZANIKANIA_BRAMKI))
		bramka_kolizje_wlaczone = false
		_ustaw_pozycje_bramki()
	elif is_instance_valid(bramka_cialo):
		_usun_bramke()
	set_physics_process(tryb_zdalny and is_instance_valid(bramka_cialo))
	gra.call("_odswiez_rysowanie")


func _zastosuj_modyfikatory_zdalne() -> void:
	if _czy_aktywne("waska_arena"):
		gra.call("animuj_granice_areny", bazowa_gora + PRZESUNIECIE_SCIAN, bazowy_dol - PRZESUNIECIE_SCIAN, 0.8)
	if _czy_aktywne("wieksza_arena"):
		gra.call("animuj_wymiary_areny", bazowa_lewa - POSZERZENIE_ARENY_X, bazowa_prawa + POSZERZENIE_ARENY_X, bazowa_gora - POSZERZENIE_ARENY_Y, bazowy_dol + POSZERZENIE_ARENY_Y, 0.8)
	if _czy_aktywne("strefa_przyspieszenia"):
		gra.call("animuj_strefe_przyspieszenia", true, 0.65)
	if _czy_aktywne("krotsze_paletki"):
		gra.call("animuj_wysokosc_paletek", 0.72, 0.45)
	if _czy_aktywne("duza_paletka"):
		gra.call("animuj_wysokosc_paletek", 1.28, 0.55)
	if _czy_aktywne("duza_pilka"):
		gra.call("animuj_rozmiar_pilki", 1.35, 0.65)
	if _czy_aktywne("sciana_srodka"):
		_utworz_sciane_srodka()


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
	_aktualizuj_sciane_srodka()


func _physics_process(delta: float) -> void:
	if tryb_zdalny:
		if not is_instance_valid(bramka_cialo):
			set_physics_process(false)
			return
		bramka_faza += delta * PREDKOSC_RUCHU_BRAMKI
		if bramka_wygaszanie:
			bramka_czas_wygaszania += delta
			bramka_postep = bramka_alfa_poczatkowa * clampf(1.0 - bramka_czas_wygaszania / bramka_czas_wygaszania_docelowy, 0.0, 1.0)
			if bramka_postep <= 0.0:
				_usun_bramke()
				return
		else:
			bramka_czas_aktywna += delta
			bramka_postep = clampf(bramka_czas_aktywna / CZAS_POJAWIENIA_BRAMKI, 0.0, 1.0)
		_ustaw_pozycje_bramki()
		if is_instance_valid(gra):
			gra.call("_odswiez_rysowanie")
		return
	if not is_instance_valid(bramka_cialo):
		return
	if bramka_wygaszanie:
		bramka_czas_wygaszania += delta
		bramka_faza += delta * PREDKOSC_RUCHU_BRAMKI
		bramka_postep = bramka_alfa_poczatkowa * clampf(1.0 - bramka_czas_wygaszania / bramka_czas_wygaszania_docelowy, 0.0, 1.0)
		if bramka_postep <= 0.0:
			_usun_bramke()
			return
		_ustaw_pozycje_bramki()
		if is_instance_valid(gra):
			gra.call("_odswiez_rysowanie")
		return
	if stan != "aktywne" or not _czy_aktywne("ruchoma_bramka"):
		return
	bramka_faza += delta * PREDKOSC_RUCHU_BRAMKI
	bramka_czas_aktywna += delta
	bramka_postep = clampf(bramka_czas_aktywna / CZAS_POJAWIENIA_BRAMKI, 0.0, 1.0)
	if not bramka_kolizje_wlaczone and bramka_postep >= 0.35:
		bramka_kolizje_wlaczone = true
	_ustaw_pozycje_bramki()
	if is_instance_valid(gra):
		gra.call("_odswiez_rysowanie")


func _losuj_wydarzenie() -> String:
	var mozliwe = WYDARZENIA.duplicate()
	mozliwe.erase(poprzednie_wydarzenie)
	return str(mozliwe.pick_random())


func _zapowiedz_wydarzenie() -> void:
	aktywne_wydarzenie = _losuj_wydarzenie()
	drugie_wydarzenie = ""
	if randf() < 0.30:
		var mozliwe_drugie = WYDARZENIA.duplicate()
		mozliwe_drugie.erase(aktywne_wydarzenie)
		for kandydat in mozliwe_drugie.duplicate():
			if not _czy_para_kompatybilna(aktywne_wydarzenie, str(kandydat)):
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

	var tytul = _nazwa_wydarzenia(aktywne_wydarzenie)
	if not drugie_wydarzenie.is_empty():
		tytul += " + " + _nazwa_wydarzenia(drugie_wydarzenie)
	gra.call("pokaz_informacje_graczowi", tytul, "", Color("#ffb454"), CZAS_OSTRZEZENIA)


func _nazwa_wydarzenia(nazwa: String) -> String:
	match nazwa:
		"wiatr_gora":
			return "Podmuch w górę"
		"wiatr_dol":
			return "Podmuch w dół"
		"przyspieszenie":
			return "Przyspieszenie"
		"przyciaganie_srodka":
			return "Przyciąganie do środka"
		"waska_arena":
			return "Mała arena"
		"strefa_przyspieszenia":
			return "Strefa przyspieszenia"
		"krotsze_paletki":
			return "Krótsze paletki"
		"duza_paletka":
			return "Duża paletka"
		"duza_pilka":
			return "Duża piłka"
		"sciana_srodka":
			return "Ściana na środku"
		"mocne_sciany":
			return "Mocne odbicie od ściany"
		"wieksza_arena":
			return "Większa arena"
		"ruchoma_bramka":
			return "Ruchoma ściana"
	return ""


func _czy_aktywne(nazwa: String) -> bool:
	return aktywne_wydarzenie == nazwa or drugie_wydarzenie == nazwa


func _czy_para_kompatybilna(pierwsze: String, drugie: String) -> bool:
	var niezgodne_pierwsze: Array = NIEKOMPATYBILNE_PARY.get(pierwsze, [])
	var niezgodne_drugie: Array = NIEKOMPATYBILNE_PARY.get(drugie, [])
	return drugie not in niezgodne_pierwsze and pierwsze not in niezgodne_drugie


func _rozpocznij_wydarzenie() -> void:
	stan = "aktywne"
	if is_instance_valid(gra):
		gra.call("odtworz_dzwiek_modyfikatora")
	czas_do_zmiany = CZAS_AKTYWNEGO_WYDARZENIA
	if _czy_aktywne("krotsze_paletki"):
		czas_do_zmiany = maxf(czas_do_zmiany, CZAS_KROTSZYCH_PALETEK)
	if _czy_aktywne("ruchoma_bramka"):
		czas_do_zmiany = maxf(czas_do_zmiany, CZAS_RUCHOMEJ_BRAMKI)
	if _czy_aktywne("waska_arena"):
		var gora = bazowa_gora + PRZESUNIECIE_SCIAN
		var dol = bazowy_dol - PRZESUNIECIE_SCIAN
		gra.call("animuj_granice_areny", gora, dol, 0.8)
	if _czy_aktywne("wieksza_arena"):
		gra.call(
			"animuj_wymiary_areny",
			bazowa_lewa - POSZERZENIE_ARENY_X,
			bazowa_prawa + POSZERZENIE_ARENY_X,
			bazowa_gora - POSZERZENIE_ARENY_Y,
			bazowy_dol + POSZERZENIE_ARENY_Y,
			0.8
		)
	if _czy_aktywne("strefa_przyspieszenia"):
		for pilka in get_tree().get_nodes_in_group("pilki"):
			pilka.set_meta("w_strefie_przyspieszenia", absf(pilka.position.x - _srodek_planszy_x()) <= SZEROKOSC_STREFY * 0.5)
		gra.call("animuj_strefe_przyspieszenia", true, 0.65)
	if _czy_aktywne("krotsze_paletki"):
		gra.call("animuj_wysokosc_paletek", 0.72, 0.45)
	if _czy_aktywne("duza_paletka"):
		gra.call("animuj_wysokosc_paletek", 1.28, 0.55)
	if _czy_aktywne("duza_pilka"):
		gra.call("animuj_rozmiar_pilki", 1.35, 0.65)
	if _czy_aktywne("sciana_srodka"):
		_utworz_sciane_srodka()
	if _czy_aktywne("mocne_sciany"):
		gra.call("_odswiez_rysowanie")
	if _czy_aktywne("ruchoma_bramka"):
		_utworz_bramke()

func _zakoncz_wydarzenie() -> void:
	# Jeśli punkt uruchomił już wygaszanie, poczekaj na jego koniec, żeby nie
	# usuwać bramki natychmiast przy granicy czasu wydarzenia.
	if _czy_aktywne("ruchoma_bramka") and is_instance_valid(bramka_cialo):
		if not bramka_wygaszanie:
			_wygasz_bramke()
		return
	_przywroc_efekty_modyfikatorow(0.8)
	_ustaw_nastepne_wydarzenie()


func _przywroc_efekty_modyfikatorow(czas_animacji: float) -> void:
	if _czy_aktywne("waska_arena") and is_instance_valid(gra):
		gra.call("animuj_granice_areny", bazowa_gora, bazowy_dol, czas_animacji)
	if _czy_aktywne("wieksza_arena") and is_instance_valid(gra):
		gra.call("animuj_wymiary_areny", bazowa_lewa, bazowa_prawa, bazowa_gora, bazowy_dol, czas_animacji)
	if _czy_aktywne("strefa_przyspieszenia") and is_instance_valid(gra):
		gra.call("animuj_strefe_przyspieszenia", false, czas_animacji)
	if _czy_aktywne("krotsze_paletki") and is_instance_valid(gra):
		gra.call("animuj_wysokosc_paletek", 1.0, czas_animacji)
	if _czy_aktywne("duza_paletka") and is_instance_valid(gra):
		gra.call("animuj_wysokosc_paletek", 1.0, czas_animacji)
	if _czy_aktywne("duza_pilka") and is_instance_valid(gra):
		gra.call("animuj_rozmiar_pilki", 1.0, czas_animacji)
	if _czy_aktywne("sciana_srodka"):
		_usun_sciane_srodka()
	if _czy_aktywne("mocne_sciany") and is_instance_valid(gra):
		gra.call("_odswiez_rysowanie")
	if _czy_aktywne("ruchoma_bramka") and is_instance_valid(bramka_cialo):
		_wygasz_bramke(CZAS_WYGASZANIA_PO_PUNKCIE if czas_animacji <= CZAS_WYGASZANIA_PO_PUNKCIE else CZAS_ZANIKANIA_BRAMKI)
	if is_instance_valid(gra):
		gra.call("_odswiez_rysowanie")


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
		_przywroc_efekty_modyfikatorow(0.45)
	_ustaw_nastepne_wydarzenie(6.0, 8.5)
	if is_instance_valid(gra):
		gra.call("ukryj_informacje_graczowi")


func mnoznik_predkosci() -> float:
	return MNOZNIK_PREDKOSCI if stan == "aktywne" and _czy_aktywne("przyspieszenie") else 1.0


func wzmocnij_odbicie_od_sciany(pilka: CharacterBody2D, nazwa_sciany: String) -> void:
	if stan != "aktywne" or not _czy_aktywne("mocne_sciany"):
		return
	if nazwa_sciany not in ["górna ściana", "dolna ściana"]:
		return
	pilka.call("przyspiesz", 1.05)
	pilka.call("pokaz_efekt_mocnego_odbicia")


func mocne_sciany_aktywne() -> bool:
	return stan == "aktywne" and _czy_aktywne("mocne_sciany")


func wieksza_arena_aktywna() -> bool:
	return stan == "aktywne" and _czy_aktywne("wieksza_arena")


func strefa_przyspieszenia_aktywna() -> bool:
	return stan == "aktywne" and _czy_aktywne("strefa_przyspieszenia")


func bramka_aktywna() -> bool:
	return is_instance_valid(bramka_cialo) and (bramka_wygaszanie or (stan == "aktywne" and _czy_aktywne("ruchoma_bramka")))


func _wygasz_bramke(czas_wygaszania: float = CZAS_ZANIKANIA_BRAMKI) -> void:
	if not is_instance_valid(bramka_cialo) or bramka_wygaszanie:
		return
	bramka_wygaszanie = true
	bramka_czas_wygaszania = 0.0
	bramka_alfa_poczatkowa = bramka_postep
	bramka_czas_wygaszania_docelowy = maxf(czas_wygaszania, 0.01)
	bramka_kolizje_wlaczone = false
	# Kolizja znika od razu, a widoczne segmenty płynnie gasną.
	for kolizja in bramka_kolizje:
		if is_instance_valid(kolizja):
			kolizja.set_deferred("disabled", true)


func dane_bramki() -> Array[Rect2]:
	var segmenty: Array[Rect2] = []
	if not bramka_aktywna():
		return segmenty
	return _zamkniete_segmenty_bramki()


func przezroczystosc_bramki() -> float:
	return bramka_postep


func _utworz_bramke() -> void:
	_usun_bramke()
	bramka_cialo = AnimatableBody2D.new()
	bramka_cialo.name = "RuchomaBramka"
	bramka_cialo.collision_layer = 1
	bramka_cialo.collision_mask = 1
	bramka_cialo.sync_to_physics = true
	bramka_kolizje.clear()
	bramka_ksztalty.clear()
	bramka_kolizje_wlaczone = false
	bramka_postep = 0.0
	bramka_czas_aktywna = 0.0
	for i in range(3):
		var kolizja = CollisionShape2D.new()
		kolizja.name = "Segment%d" % i
		kolizja.disabled = true
		var ksztalt = RectangleShape2D.new()
		ksztalt.size = Vector2(SZEROKOSC_BRAMKI, 1.0)
		kolizja.shape = ksztalt
		bramka_cialo.add_child(kolizja)
		bramka_kolizje.append(kolizja)
		bramka_ksztalty.append(ksztalt)
	gra.add_child(bramka_cialo)
	bramka_faza = 0.0
	_dopasuj_faze_bramki_do_pilek()
	_ustaw_pozycje_bramki()
	gra.call("_odswiez_rysowanie")


func _dopasuj_faze_bramki_do_pilek() -> void:
	var pilki = get_tree().get_nodes_in_group("pilki")
	if pilki.is_empty():
		return
	var najlepsza_faza = 0.0
	var najmniejszy_blad = INF
	for i in range(120):
		var testowana_faza = TAU * float(i) / 120.0
		var otwory = _otwory_bramki(testowana_faza)
		var suma_bledu = 0.0
		for pilka in pilki:
			var blad_pilki = INF
			for otwor in otwory:
				var odleglosc = maxf(maxf(otwor.x - pilka.global_position.y, pilka.global_position.y - otwor.y), 0.0)
				blad_pilki = minf(blad_pilki, odleglosc)
			suma_bledu += blad_pilki
		var czestotliwosc = 1.25 if wariant_bramki == "podwojne_przejscie" else 1.0
		var kara_za_powolny_start = (1.0 - absf(cos(testowana_faza * czestotliwosc))) * 18.0
		var ocena_fazy = suma_bledu + kara_za_powolny_start
		if ocena_fazy < najmniejszy_blad:
			najmniejszy_blad = ocena_fazy
			najlepsza_faza = testowana_faza
	bramka_faza = najlepsza_faza


func _ustaw_pozycje_bramki() -> void:
	if not is_instance_valid(bramka_cialo):
		return
	var srodek_planszy = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
	bramka_cialo.position = Vector2((Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5, srodek_planszy)
	var segmenty = _zamkniete_segmenty_bramki()
	for i in range(bramka_kolizje.size()):
		var kolizja = bramka_kolizje[i]
		if i < segmenty.size():
			var segment = segmenty[i]
			bramka_ksztalty[i].size = Vector2(SZEROKOSC_BRAMKI, maxf(segment.size.y, 1.0))
			kolizja.position = segment.get_center() - bramka_cialo.position
			if kolizja.disabled == bramka_kolizje_wlaczone:
				kolizja.set_deferred("disabled", not bramka_kolizje_wlaczone)
		else:
			if not kolizja.disabled:
				kolizja.set_deferred("disabled", true)


func _otwory_bramki(faza: float) -> Array[Vector2]:
	var wysokosc_planszy = Ustawienia.dolna_granica - Ustawienia.gorna_granica
	var srodek_planszy = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
	var wysokosc_otworu = WYSOKOSC_OTWORU_BRAMKI
	if wariant_bramki == "podwojne_przejscie":
		wysokosc_otworu = WYSOKOSC_PODWOJNEGO_OTWORU
	elif wariant_bramki == "pulsujace_przejscie":
		wysokosc_otworu = lerpf(112.0, 184.0, 0.5 + 0.5 * sin(faza * 1.3))
	wysokosc_otworu = minf(wysokosc_otworu, wysokosc_planszy * 0.35)
	var liczba_otworow = 2 if wariant_bramki == "podwojne_przejscie" else 1
	var rozstaw = ODSTEP_PODWOJNYCH_OTWOROW if liczba_otworow == 2 else 0.0
	var calkowita_wysokosc = wysokosc_otworu + rozstaw
	var amplituda = maxf(0.0, (wysokosc_planszy - calkowita_wysokosc) * 0.5 - 8.0)
	var czestotliwosc = 1.25 if liczba_otworow == 2 else 1.0
	var srodek_ruchu = srodek_planszy + sin(faza * czestotliwosc) * amplituda
	var otwory: Array[Vector2] = []
	for i in range(liczba_otworow):
		var przesuniecie = (float(i) - float(liczba_otworow - 1) * 0.5) * rozstaw
		var srodek_otworu = srodek_ruchu + przesuniecie
		var polowa = wysokosc_otworu * 0.5
		otwory.append(Vector2(srodek_otworu - polowa, srodek_otworu + polowa))
	return otwory


func _zamkniete_segmenty_bramki() -> Array[Rect2]:
	var segmenty: Array[Rect2] = []
	var lewa = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5 - SZEROKOSC_BRAMKI * 0.5
	var y = Ustawienia.gorna_granica
	for otwor in _otwory_bramki(bramka_faza):
		if otwor.x > y:
			segmenty.append(Rect2(Vector2(lewa, y), Vector2(SZEROKOSC_BRAMKI, otwor.x - y)))
		y = otwor.y
	if Ustawienia.dolna_granica > y:
		segmenty.append(Rect2(Vector2(lewa, y), Vector2(SZEROKOSC_BRAMKI, Ustawienia.dolna_granica - y)))
	return segmenty


func _usun_bramke() -> void:
	if is_instance_valid(bramka_cialo):
		bramka_cialo.queue_free()
	bramka_cialo = null
	bramka_kolizje.clear()
	bramka_ksztalty.clear()
	bramka_postep = 0.0
	bramka_czas_aktywna = 0.0
	bramka_kolizje_wlaczone = false
	bramka_wygaszanie = false
	bramka_czas_wygaszania = 0.0
	bramka_alfa_poczatkowa = 0.0
	bramka_czas_wygaszania_docelowy = CZAS_ZANIKANIA_BRAMKI
	if is_instance_valid(gra):
		gra.call("_odswiez_rysowanie")


func przyspieszenie_y(predkosc_pozioma: float) -> float:
	if stan == "aktywne" and (_czy_aktywne("wiatr_gora") or _czy_aktywne("wiatr_dol")):
		return kierunek_wiatru * PREDKOSC_ZAKRETU * absf(predkosc_pozioma)
	return 0.0


func przygotuj_pilke(pilka: CharacterBody2D, delta: float) -> float:
	if sciana_srodka_aktywna():
		_aktualizuj_sciane_srodka()
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


func _obsluz_strefe_przyspieszenia(pilka: CharacterBody2D) -> void:
	var jest_w_strefie = absf(pilka.position.x - _srodek_planszy_x()) <= SZEROKOSC_STREFY * 0.5
	var byla_w_strefie = bool(pilka.get_meta("w_strefie_przyspieszenia", false))
	if jest_w_strefie and not byla_w_strefie:
		pilka.call("przyspiesz", MNOZNIK_STREFY)
		pilka.call("pokaz_efekt_strefy_przyspieszenia")
	pilka.set_meta("w_strefie_przyspieszenia", jest_w_strefie)


func _srodek_planszy_x() -> float:
	return (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5


func sciana_srodka_aktywna() -> bool:
	return stan == "aktywne" and _czy_aktywne("sciana_srodka")


func _utworz_sciane_srodka() -> void:
	if is_instance_valid(sciana_srodka):
		_aktualizuj_sciane_srodka()
		return

	sciana_srodka = StaticBody2D.new()
	sciana_srodka.name = "ScianaSrodkaArena"
	sciana_srodka.collision_layer = 1
	sciana_srodka.collision_mask = 1
	add_child(sciana_srodka)

	var ksztalt_sciany_srodka = RectangleShape2D.new()
	var dlugosc_segmentu = 2.0 * PROMIEN_SCIANY_SRODKOWEJ * sin(PI / LICZBA_SEGMENTOW_SCIANY_SRODKOWEJ)
	ksztalt_sciany_srodka.size = Vector2(SZEROKOSC_SCIANY_SRODKOWEJ, dlugosc_segmentu + 3.0)
	for i in range(LICZBA_SEGMENTOW_SCIANY_SRODKOWEJ):
		var kat = TAU * float(i) / float(LICZBA_SEGMENTOW_SCIANY_SRODKOWEJ)
		var kolizja = CollisionShape2D.new()
		kolizja.shape = ksztalt_sciany_srodka
		kolizja.position = Vector2(cos(kat), sin(kat)) * PROMIEN_SCIANY_SRODKOWEJ
		kolizja.rotation = kat
		sciana_srodka.add_child(kolizja)
	_aktualizuj_sciane_srodka()
	if is_instance_valid(gra):
		gra.call("_odswiez_rysowanie")


func _aktualizuj_sciane_srodka() -> void:
	if not is_instance_valid(sciana_srodka):
		return
	var gora = Ustawienia.gorna_granica
	var dol = Ustawienia.dolna_granica
	var pozycja = Vector2(_srodek_planszy_x(), (gora + dol) * 0.5)
	if sciana_srodka.position != pozycja:
		sciana_srodka.position = pozycja


func _usun_sciane_srodka() -> void:
	if is_instance_valid(sciana_srodka):
		sciana_srodka.queue_free()
	sciana_srodka = null


func zatrzymaj() -> void:
	set_process(false)
	set_physics_process(false)
	if _czy_aktywne("waska_arena") and is_instance_valid(gra):
		gra.call("animuj_granice_areny", bazowa_gora, bazowy_dol, 0.5)
	if _czy_aktywne("wieksza_arena") and is_instance_valid(gra):
		gra.call("animuj_wymiary_areny", bazowa_lewa, bazowa_prawa, bazowa_gora, bazowy_dol, 0.5)
	if _czy_aktywne("strefa_przyspieszenia") and is_instance_valid(gra):
		gra.call("animuj_strefe_przyspieszenia", false, 0.3)
	if _czy_aktywne("krotsze_paletki") and is_instance_valid(gra):
		gra.call("animuj_wysokosc_paletek", 1.0, 0.3)
	if _czy_aktywne("duza_paletka") and is_instance_valid(gra):
		gra.call("animuj_wysokosc_paletek", 1.0, 0.3)
	if _czy_aktywne("duza_pilka") and is_instance_valid(gra):
		gra.call("animuj_rozmiar_pilki", 1.0, 0.3)
	if _czy_aktywne("sciana_srodka"):
		_usun_sciane_srodka()
	if _czy_aktywne("ruchoma_bramka"):
		_usun_bramke()
	if is_instance_valid(gra):
		gra.call("_odswiez_rysowanie")
	stan = "zatrzymane"
	aktywne_wydarzenie = ""
	drugie_wydarzenie = ""
