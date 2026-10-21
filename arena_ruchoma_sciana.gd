class_name RuchomaScianaArena
extends Node

const SZEROKOSC = 20.0
const WYSOKOSC_OTWORU = 156.0
const PREDKOSC_RUCHU = 1.35
const CZAS_POJAWIENIA = 0.7
const CZAS_ZANIKANIA = 0.28
const WYSOKOSC_PODWOJNEGO_OTWORU = 104.0
const ODSTEP_PODWOJNYCH_OTWOROW = 166.0

var gra: GraPongAPI
var wariant = ""
var zdalna = false
var cialo: AnimatableBody2D
var kolizje: Array[CollisionShape2D] = []
var ksztalty: Array[RectangleShape2D] = []
var faza = 0.0
var postep = 0.0
var czas_aktywna = 0.0
var kolizje_wlaczone = false
var wygaszanie = false
var czas_wygaszania = 0.0
var alfa_poczatkowa = 0.0
var czas_wygaszania_docelowy = CZAS_ZANIKANIA


func uruchom(gra_glowna: GraPongAPI, tryb_zdalny: bool) -> void:
	gra = gra_glowna
	zdalna = tryb_zdalny


func istnieje() -> bool:
	return is_instance_valid(cialo)


func ustaw_stan_zdalny(dane: StanArenyOnline) -> void:
	if not zdalna:
		return
	wariant = dane.wariant_bramki
	if dane.bramka:
		if not istnieje():
			_utworz()
		faza = dane.bramka_faza
		czas_aktywna = dane.bramka_czas
		postep = dane.bramka_postep
		wygaszanie = dane.bramka_wygaszanie
		czas_wygaszania = dane.bramka_czas_wygaszania
		alfa_poczatkowa = dane.bramka_alfa_poczatkowa
		czas_wygaszania_docelowy = dane.bramka_czas_docelowy
		kolizje_wlaczone = wygaszanie or postep >= 0.35
		_ustaw_pozycje()
	elif istnieje():
		_usun()


func zapisz_stan_sieciowy(stan_sieciowy: StanArenyOnline) -> void:
	stan_sieciowy.bramka = istnieje()
	stan_sieciowy.bramka_faza = faza
	stan_sieciowy.bramka_czas = czas_aktywna
	stan_sieciowy.bramka_postep = postep
	stan_sieciowy.bramka_wygaszanie = wygaszanie
	stan_sieciowy.bramka_czas_wygaszania = czas_wygaszania
	stan_sieciowy.bramka_alfa_poczatkowa = alfa_poczatkowa
	stan_sieciowy.bramka_czas_docelowy = czas_wygaszania_docelowy


func aktywuj(nowy_wariant: String) -> void:
	if zdalna:
		return
	wariant = nowy_wariant
	_utworz()


func aktualizuj(delta: float, aktywny_wydarzeniem: bool) -> void:
	if not istnieje():
		return
	if zdalna:
		faza += delta * PREDKOSC_RUCHU
		if wygaszanie:
			czas_wygaszania += delta
			postep = alfa_poczatkowa * clampf(1.0 - czas_wygaszania / czas_wygaszania_docelowy, 0.0, 1.0)
			if postep <= 0.0:
				_usun()
				return
		else:
			czas_aktywna += delta
			postep = clampf(czas_aktywna / CZAS_POJAWIENIA, 0.0, 1.0)
		_ustaw_pozycje()
		_odswiez_rysowanie()
		return
	if wygaszanie:
		czas_wygaszania += delta
		faza += delta * PREDKOSC_RUCHU
		postep = alfa_poczatkowa * clampf(1.0 - czas_wygaszania / czas_wygaszania_docelowy, 0.0, 1.0)
		if postep <= 0.0:
			_usun()
			return
		_ustaw_pozycje()
		_odswiez_rysowanie()
		return
	if not aktywny_wydarzeniem:
		return
	faza += delta * PREDKOSC_RUCHU
	czas_aktywna += delta
	postep = clampf(czas_aktywna / CZAS_POJAWIENIA, 0.0, 1.0)
	if not kolizje_wlaczone and postep >= 0.35:
		kolizje_wlaczone = true
	_ustaw_pozycje()
	_odswiez_rysowanie()


func wygasz(czas: float = CZAS_ZANIKANIA) -> void:
	if not istnieje() or wygaszanie:
		return
	wygaszanie = true
	czas_wygaszania = 0.0
	alfa_poczatkowa = postep
	czas_wygaszania_docelowy = maxf(czas, 0.01)


func aktywna() -> bool:
	return istnieje() and (wygaszanie or postep > 0.0)


func segmenty() -> Array[Rect2]:
	if not aktywna():
		var puste_segmenty: Array[Rect2] = []
		return puste_segmenty
	return _zamkniete_segmenty()


func przezroczystosc() -> float:
	return postep


func zatrzymaj() -> void:
	_usun()


func _utworz() -> void:
	_usun()
	cialo = AnimatableBody2D.new()
	cialo.name = "RuchomaBramka"
	cialo.collision_layer = 1
	cialo.collision_mask = 1
	cialo.sync_to_physics = true
	kolizje.clear()
	ksztalty.clear()
	kolizje_wlaczone = false
	postep = 0.0
	czas_aktywna = 0.0
	for i in range(3):
		var kolizja = CollisionShape2D.new()
		kolizja.name = "Segment%d" % i
		kolizja.disabled = true
		var ksztalt = RectangleShape2D.new()
		ksztalt.size = Vector2(SZEROKOSC, 1.0)
		kolizja.shape = ksztalt
		cialo.add_child(kolizja)
		kolizje.append(kolizja)
		ksztalty.append(ksztalt)
	gra.add_child(cialo)
	faza = 0.0
	if not zdalna:
		_dopasuj_faze_do_pilek()
	_ustaw_pozycje()
	_odswiez_rysowanie()


func _dopasuj_faze_do_pilek() -> void:
	var pilki = get_tree().get_nodes_in_group("pilki")
	if pilki.is_empty():
		return
	var najlepsza_faza = 0.0
	var najmniejszy_blad = INF
	for i in range(120):
		var testowana_faza = TAU * float(i) / 120.0
		var otwory = _otwory(testowana_faza)
		var suma_bledu = 0.0
		for pilka in pilki:
			var blad_pilki = INF
			for otwor in otwory:
				var odleglosc = maxf(maxf(otwor.x - pilka.global_position.y, pilka.global_position.y - otwor.y), 0.0)
				blad_pilki = minf(blad_pilki, odleglosc)
			suma_bledu += blad_pilki
		var czestotliwosc = 1.25 if wariant == "podwojne_przejscie" else 1.0
		var kara = (1.0 - absf(cos(testowana_faza * czestotliwosc))) * 18.0
		if suma_bledu + kara < najmniejszy_blad:
			najmniejszy_blad = suma_bledu + kara
			najlepsza_faza = testowana_faza
	faza = najlepsza_faza


func _ustaw_pozycje() -> void:
	if not istnieje():
		return
	var srodek_planszy = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
	cialo.position = Vector2((Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5, srodek_planszy)
	var zamkniete = _zamkniete_segmenty()
	for i in range(kolizje.size()):
		var kolizja = kolizje[i]
		if i < zamkniete.size():
			var segment = zamkniete[i]
			ksztalty[i].size = Vector2(SZEROKOSC, maxf(segment.size.y, 1.0))
			kolizja.position = segment.get_center() - cialo.position
			if kolizja.disabled == kolizje_wlaczone:
				kolizja.set_deferred("disabled", not kolizje_wlaczone)
		elif not kolizja.disabled:
			kolizja.set_deferred("disabled", true)


func _otwory(kat_fazy: float) -> Array[Vector2]:
	var wysokosc_planszy = Ustawienia.dolna_granica - Ustawienia.gorna_granica
	var srodek_planszy = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
	var wysokosc_otworu = WYSOKOSC_OTWORU
	if wariant == "podwojne_przejscie":
		wysokosc_otworu = WYSOKOSC_PODWOJNEGO_OTWORU
	elif wariant == "pulsujace_przejscie":
		wysokosc_otworu = lerpf(112.0, 184.0, 0.5 + 0.5 * sin(kat_fazy * 1.3))
	wysokosc_otworu = minf(wysokosc_otworu, wysokosc_planszy * 0.35)
	var liczba_otworow = 2 if wariant == "podwojne_przejscie" else 1
	var rozstaw = ODSTEP_PODWOJNYCH_OTWOROW if liczba_otworow == 2 else 0.0
	var calkowita_wysokosc = wysokosc_otworu + rozstaw
	var amplituda = maxf(0.0, (wysokosc_planszy - calkowita_wysokosc) * 0.5 - 8.0)
	var czestotliwosc = 1.25 if liczba_otworow == 2 else 1.0
	var srodek_ruchu = srodek_planszy + sin(kat_fazy * czestotliwosc) * amplituda
	var wynik: Array[Vector2] = []
	for i in range(liczba_otworow):
		var przesuniecie = (float(i) - float(liczba_otworow - 1) * 0.5) * rozstaw
		var srodek_otworu = srodek_ruchu + przesuniecie
		var polowa = wysokosc_otworu * 0.5
		wynik.append(Vector2(srodek_otworu - polowa, srodek_otworu + polowa))
	return wynik


func _zamkniete_segmenty() -> Array[Rect2]:
	var wynik: Array[Rect2] = []
	var lewa = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5 - SZEROKOSC * 0.5
	var y = Ustawienia.gorna_granica
	for otwor in _otwory(faza):
		if otwor.x > y:
			wynik.append(Rect2(Vector2(lewa, y), Vector2(SZEROKOSC, otwor.x - y)))
		y = otwor.y
	if Ustawienia.dolna_granica > y:
		wynik.append(Rect2(Vector2(lewa, y), Vector2(SZEROKOSC, Ustawienia.dolna_granica - y)))
	return wynik


func _usun() -> void:
	if is_instance_valid(cialo):
		cialo.queue_free()
	cialo = null
	kolizje.clear()
	ksztalty.clear()
	postep = 0.0
	czas_aktywna = 0.0
	kolizje_wlaczone = false
	wygaszanie = false
	czas_wygaszania = 0.0
	alfa_poczatkowa = 0.0
	czas_wygaszania_docelowy = CZAS_ZANIKANIA
	_odswiez_rysowanie()


func _odswiez_rysowanie() -> void:
	if is_instance_valid(gra):
		gra.odswiez_rysowanie()
