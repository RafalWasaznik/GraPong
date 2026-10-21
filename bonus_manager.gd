class_name BonusManager
extends Node

const BONUS_KULKI = preload("res://bonusy_kulki.tscn")

const MAKS_BONUSOW_NA_PLANSZY = 2
const ODLEGLOSC_MIEDZY_BONUSAMI = 64.0
const CZAS_DO_PIERWSZEJ_LOTERII = 1.0
const MIN_CZASU_PIERWSZEGO_BONUSU = 3.0
const MAKS_CZASU_PIERWSZEGO_BONUSU = 5.0
const MIN_ODSTEP_LOSOWANIA = 5.0
const MAKS_ODSTEP_LOSOWANIA = 8.0
const MARGINES_BOCZNY = 90.0
const MARGINES_GORNY_DOLNY = 40.0

var gra: GraPongAPI
var zegar: Timer
var runda_aktywna = false
var oczekiwanie_na_pierwsza_loterie = false


func uruchom(gra_glowna: GraPongAPI) -> void:
	gra = gra_glowna
	zegar = gra.zegar_bonusow()

	if zegar == null:
		push_error("BonusManager nie znalazł timera CzasBonusu.")
		return

	if not zegar.timeout.is_connected(_pojaw_bonus):
		zegar.timeout.connect(_pojaw_bonus)

	zegar.one_shot = true
	zegar.stop()
	runda_aktywna = false
	oczekiwanie_na_pierwsza_loterie = false


func runda_rozpoczeta() -> void:
	if zegar == null or not zegar.is_inside_tree():
		return
	runda_aktywna = true
	oczekiwanie_na_pierwsza_loterie = true
	# Odliczanie nie rusza podczas intro piłki ani przerwy po punkcie.
	zegar.start(CZAS_DO_PIERWSZEJ_LOTERII)


func zatrzymaj() -> void:
	runda_aktywna = false
	oczekiwanie_na_pierwsza_loterie = false
	if zegar != null:
		zegar.stop()


func wyczysc_po_punkcie() -> void:
	if gra == null:
		return
	runda_aktywna = false
	oczekiwanie_na_pierwsza_loterie = false

	for bonus in gra.get_tree().get_nodes_in_group("bonus"):
		bonus.queue_free()

	if zegar != null and zegar.is_inside_tree():
		zegar.stop()


func _pojaw_bonus() -> void:
	if gra == null or not runda_aktywna:
		return
	if oczekiwanie_na_pierwsza_loterie:
		oczekiwanie_na_pierwsza_loterie = false
		zegar.start(randf_range(MIN_CZASU_PIERWSZEGO_BONUSU, MAKS_CZASU_PIERWSZEGO_BONUSU))
		return

	var aktywne_bonusy = gra.get_tree().get_nodes_in_group("bonus")

	if aktywne_bonusy.size() < MAKS_BONUSOW_NA_PLANSZY:
		var bonus_dwoch_pilek = randf() >= 0.75
		var bonus := BONUS_KULKI.instantiate() as BonusKulki
		bonus.typ = BonusKulki.TypBonusu.DWIE_PILKI if bonus_dwoch_pilek else BonusKulki.TypBonusu.PRZYSPIESZENIE
		bonus.position = _losuj_pozycje_bonusu(aktywne_bonusy, bonus_dwoch_pilek)
		gra.add_child(bonus)

	if zegar != null and runda_aktywna:
		zegar.start(randf_range(MIN_ODSTEP_LOSOWANIA, MAKS_ODSTEP_LOSOWANIA))


func _losuj_pozycje_bonusu(aktywne_bonusy: Array, bonus_dwoch_pilek: bool) -> Vector2:
	var srodek_x = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) / 2.0
	var srodek_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) / 2.0
	var szerokosc_planszy = Ustawienia.prawa_granica - Ustawienia.lewa_granica
	var wysokosc_planszy = Ustawienia.dolna_granica - Ustawienia.gorna_granica

	var x_min = Ustawienia.lewa_granica + MARGINES_BOCZNY
	var x_max = Ustawienia.prawa_granica - MARGINES_BOCZNY
	var y_min = Ustawienia.gorna_granica + MARGINES_GORNY_DOLNY
	var y_max = Ustawienia.dolna_granica - MARGINES_GORNY_DOLNY

	if bonus_dwoch_pilek:
		var polowa_strefy_srodka_x = szerokosc_planszy * 0.16
		var polowa_strefy_srodka_y = wysokosc_planszy * 0.22
		x_min = srodek_x - polowa_strefy_srodka_x
		x_max = srodek_x + polowa_strefy_srodka_x
		y_min = srodek_y - polowa_strefy_srodka_y
		y_max = srodek_y + polowa_strefy_srodka_y

	var pozycja = Vector2(srodek_x, srodek_y)

	for proba in range(30):
		pozycja = Vector2(
			randf_range(x_min, x_max),
			randf_range(y_min, y_max)
		)

		var miejsce_wolne = true

		for bonus_istniejacy in aktywne_bonusy:
			if bonus_istniejacy.global_position.distance_to(pozycja) < ODLEGLOSC_MIEDZY_BONUSAMI:
				miejsce_wolne = false
				break

		if miejsce_wolne:
			return pozycja

	return pozycja
