class_name PrzebiegMeczu
extends Node

const PREDKOSC_BAZOWA_ENDLESS = 560.0

var gra: GraPongAPI
var wynik_gracza = 0
var wynik_ai = 0
var czas_meczu = 0.0
var stat_odbicia_gracza = 0
var stat_odbicia_rywala = 0
var stat_mocne_odbicia_gracza = 0
var stat_mocne_odbicia_rywala = 0
var biezaca_wymiana = 0
var najdluzsza_wymiana = 0
var endless_odbicia = 0
var endless_wysokosc_startowa = 120.0
var endless_wysokosc_aktualna = 120.0
var mecz_zakonczony = false
var endless_info: Label


func uruchom(gra_glowna: GraPongAPI) -> void:
	gra = gra_glowna
	if Ustawienia.tryb == "endless":
		var ksztalt_paletki = gra.lewa_paletka().kolizja.shape as RectangleShape2D
		if ksztalt_paletki != null:
			endless_wysokosc_startowa = ksztalt_paletki.size.y
			endless_wysokosc_aktualna = ksztalt_paletki.size.y


func _process(delta: float) -> void:
	if not mecz_zakonczony:
		czas_meczu += delta


func zarejestruj_odbicie(strona: String, mocne: bool) -> void:
	if strona == "gracz":
		stat_odbicia_gracza += 1
		if mocne:
			stat_mocne_odbicia_gracza += 1
	else:
		stat_odbicia_rywala += 1
		if mocne:
			stat_mocne_odbicia_rywala += 1
	biezaca_wymiana += 1
	najdluzsza_wymiana = maxi(najdluzsza_wymiana, biezaca_wymiana)


func ustaw_stan_zdalny(stan: StanMeczuOnline) -> void:
	wynik_gracza = stan.wynik_gracza
	wynik_ai = stan.wynik_ai
	czas_meczu = stan.czas_meczu
	stat_odbicia_gracza = stan.stat_odbicia_gracza
	stat_odbicia_rywala = stan.stat_odbicia_rywala
	stat_mocne_odbicia_gracza = stan.stat_mocne_odbicia_gracza
	stat_mocne_odbicia_rywala = stan.stat_mocne_odbicia_rywala
	biezaca_wymiana = stan.biezaca_wymiana
	najdluzsza_wymiana = stan.najdluzsza_wymiana


func _on_punkt(strona: String) -> void:
	if mecz_zakonczony:
		return
	gra.zresetuj_rozpad_punktu()
	if Ustawienia.tryb == "endless":
		_zakoncz_endless()
		return

	gra.odtworz_dzwiek_punktu()
	biezaca_wymiana = 0
	if strona == "lewa":
		wynik_ai += 1
	else:
		wynik_gracza += 1

	gra.ustaw_wyniki(wynik_gracza, wynik_ai)
	if Ustawienia.tryb != "online":
		(gra.bonusy()).wyczysc_po_punkcie()
	var arena_manager := gra.menedzer_areny()
	if arena_manager != null:
		arena_manager.po_zdobyciu_punktu()
	gra.odswiez_rysowanie()

	var pilka_glowna := gra.pilka()
	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka != pilka_glowna:
			pilka.queue_free()

	var z_botem = Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy)
	if Ustawienia.tryb == "online" and Siec.warunek_meczu == "czas":
		gra.lewa_paletka().set_physics_process(true)
		gra.prawa_paletka().set_physics_process(true)
		pilka_glowna.set_physics_process(true)
		pilka_glowna.reset()
	elif Ustawienia.tryb == "online" and wynik_gracza >= Siec.limit_punktow_meczu:
		zakoncz_mecz("Wygrywa %s!" % Siec.nazwa_gracza_1)
	elif Ustawienia.tryb == "online" and wynik_ai >= Siec.limit_punktow_meczu:
		zakoncz_mecz("Wygrywa %s!" % Siec.nazwa_gracza_2)
	elif wynik_gracza >= Ustawienia.limit_punktow:
		zakoncz_mecz("Wygrałeś!" if z_botem else "Wygrywa gracz 1!")
	elif wynik_ai >= Ustawienia.limit_punktow:
		zakoncz_mecz("Przegrałeś!" if z_botem else "Wygrywa gracz 2!")
	else:
		gra.lewa_paletka().set_physics_process(true)
		gra.prawa_paletka().set_physics_process(true)
		pilka_glowna.set_physics_process(true)
		pilka_glowna.reset()


func zarejestruj_odbicie_endless(idealne: bool) -> void:
	if Ustawienia.tryb != "endless" or mecz_zakonczony:
		return
	endless_odbicia += 1
	wynik_gracza += (3 if idealne else 1)
	gra.ustaw_wyniki(wynik_gracza, Ustawienia.rekord_endless)
	if endless_odbicia % 5 == 0:
		(gra.pilka()).przyspiesz(1.08)
	if endless_odbicia % 12 == 0:
		_zmniejsz_paletke_endless()
	_odswiez_info_endless()


func _zmniejsz_paletke_endless() -> void:
	var etap = floori(float(endless_odbicia) / 12.0)
	var mnoznik = maxf(0.6, 1.0 - float(etap) * 0.08)
	endless_wysokosc_aktualna = endless_wysokosc_startowa * mnoznik
	var paletka := gra.lewa_paletka()
	paletka.ustaw_wysokosc.call_deferred(endless_wysokosc_aktualna)


func _zakoncz_endless() -> void:
	var nowy_rekord = wynik_gracza > Ustawienia.rekord_endless
	if nowy_rekord:
		Ustawienia.rekord_endless = wynik_gracza
		Ustawienia.zapisz()
	gra.ustaw_wyniki(wynik_gracza, Ustawienia.rekord_endless)
	zakoncz_mecz("Nowy rekord!" if nowy_rekord else "Koniec próby")


func zakoncz_po_czasie() -> void:
	if wynik_gracza > wynik_ai:
		zakoncz_mecz("Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_1)
	elif wynik_ai > wynik_gracza:
		zakoncz_mecz("Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_2)
	else:
		zakoncz_mecz("Koniec czasu — remis!")


func dodaj_info_endless() -> void:
	endless_info = Label.new()
	endless_info.name = "InformacjaEndless"
	endless_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endless_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	endless_info.add_theme_font_size_override("font_size", 14)
	endless_info.add_theme_color_override("font_color", Color("#a9bdd0"))
	endless_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endless_info.z_index = 10
	gra.add_child(endless_info)
	get_viewport().size_changed.connect(_ustaw_pozycje_info_endless)
	_ustaw_pozycje_info_endless()
	_odswiez_info_endless()


func _ustaw_pozycje_info_endless() -> void:
	if endless_info == null:
		return
	var wymiar = get_viewport().get_visible_rect().size
	endless_info.position = Vector2(24.0, minf(Ustawienia.dolna_granica + 18.0, wymiar.y - 42.0))
	endless_info.size = Vector2(wymiar.x - 48.0, 24.0)


func _odswiez_info_endless() -> void:
	if endless_info == null:
		return
	var pilka := gra.pilka()
	var predkosc_razy = pilka.predkosc / PREDKOSC_BAZOWA_ENDLESS
	var procent_paletki = 100
	if endless_wysokosc_startowa > 0.0:
		procent_paletki = roundi(endless_wysokosc_aktualna / endless_wysokosc_startowa * 100.0)
	endless_info.text = "Idealne trafienie: +2 pkt   ·   Prędkość ×%.2f   ·   Paletka %d%%   ·   Przyspieszenie co 5 odbić, skrócenie co 12" % [predkosc_razy, procent_paletki]


func zakoncz_mecz(tekst: String) -> void:
	if mecz_zakonczony:
		return
	mecz_zakonczony = true
	if Ustawienia.tryb == "online":
		gra.ustaw_tekst_konca_online(tekst)
	gra.pokaz_wyniki(false)
	(gra.ekran_konca_meczu()).pokaz(tekst, pobierz_podsumowanie())
	if is_instance_valid(endless_info):
		endless_info.hide()
	gra.ukryj_informacje_graczowi()
	gra.odswiez_rysowanie()
	(gra.bonusy()).zatrzymaj()
	var arena_manager := gra.menedzer_areny()
	if arena_manager != null:
		arena_manager.zatrzymaj()
	for pilka in get_tree().get_nodes_in_group("pilki"):
		pilka.set_physics_process(false)
	gra.lewa_paletka().set_physics_process(false)
	gra.prawa_paletka().set_physics_process(false)


func pobierz_podsumowanie() -> PodsumowanieMeczu:
	var podsumowanie := PodsumowanieMeczu.new()
	podsumowanie.tryb = Ustawienia.tryb
	podsumowanie.czas_meczu = czas_meczu
	podsumowanie.wynik_gracza = wynik_gracza
	podsumowanie.wynik_ai = wynik_ai
	podsumowanie.odbicia_lacznie = stat_odbicia_gracza + stat_odbicia_rywala
	podsumowanie.mocne_odbicia_lacznie = stat_mocne_odbicia_gracza + stat_mocne_odbicia_rywala
	podsumowanie.rekord_endless = Ustawienia.rekord_endless
	podsumowanie.najdluzsza_wymiana = najdluzsza_wymiana
	return podsumowanie
