class_name PrzebiegMeczu
extends Node

const SZEROKOSC_INFO_ENDLESS = 440.0
const CZCIONKA_ENDLESS = preload("res://assets/fonts/Oxanium.ttf")
const KOLOR_TURKUS_ENDLESS = Color("#55e7ff")
const KOLOR_FIOLET_ENDLESS = Color("#ad83ff")
const KOLOR_REKORD_ENDLESS = Color("#ffc76a")

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
var endless_przyspieszenia_oczekujace = 0
var endless_rekord_pobity = false
var endless_wysokosc_startowa = 120.0
var endless_wysokosc_aktualna = 120.0
var mecz_zakonczony = false
var endless_info: HBoxContainer
var endless_wartosci: Array[Label] = []
var endless_powiadomienie: Label
var animacja_powiadomienia: Tween


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
		_uruchom_odlozone_przyspieszenia_endless()
		if Ustawienia.tryb == "endless" and is_instance_valid(endless_info):
			_odswiez_info_endless()


func _uruchom_odlozone_przyspieszenia_endless() -> void:
	if Ustawienia.tryb != "endless" or endless_przyspieszenia_oczekujace <= 0:
		return
	var pilka := gra.pilka()
	if pilka.czas_rundy < Pilka.CZAS_STARTOWEJ_PREDKOSCI_ENDLESS:
		return
	while endless_przyspieszenia_oczekujace > 0:
		pilka.przyspiesz(1.08)
		endless_przyspieszenia_oczekujace -= 1


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
	if endless_odbicia % 10 == 0:
		_pokaz_powiadomienie("%d ODBIĆ" % endless_odbicia, KOLOR_TURKUS_ENDLESS, false)
	if endless_odbicia % 5 == 0:
		if (gra.pilka()).czas_rundy < Pilka.CZAS_STARTOWEJ_PREDKOSCI_ENDLESS:
			endless_przyspieszenia_oczekujace += 1
		else:
			(gra.pilka()).przyspiesz(1.08)
	if endless_odbicia % 12 == 0:
		_zmniejsz_paletke_endless()
	if not endless_rekord_pobity and wynik_gracza > Ustawienia.rekord_endless:
		endless_rekord_pobity = true
		_pokaz_powiadomienie("NOWY REKORD OSOBISTY!", KOLOR_REKORD_ENDLESS, true)
		gra.odtworz_dzwiek_rekordu()
	elif endless_odbicia % 10 == 0:
		gra.odtworz_dzwiek_kamienia_milowego()
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


func _pokaz_powiadomienie(tekst: String, kolor: Color, rekord: bool) -> void:
	if endless_powiadomienie == null:
		return
	if is_instance_valid(animacja_powiadomienia):
		animacja_powiadomienia.kill()
	endless_powiadomienie.text = tekst
	endless_powiadomienie.add_theme_color_override("font_color", kolor)
	endless_powiadomienie.add_theme_font_size_override("font_size", 30 if rekord else 25)
	endless_powiadomienie.scale = Vector2(0.92, 0.92) if rekord else Vector2.ONE
	endless_powiadomienie.modulate.a = 0.0
	endless_powiadomienie.show()
	animacja_powiadomienia = create_tween()
	animacja_powiadomienia.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacja_powiadomienia.tween_property(endless_powiadomienie, "modulate:a", 1.0, 0.16)
	if rekord:
		animacja_powiadomienia.parallel().tween_property(endless_powiadomienie, "scale", Vector2.ONE, 0.24)
	animacja_powiadomienia.tween_interval(1.25)
	animacja_powiadomienia.tween_property(endless_powiadomienie, "modulate:a", 0.0, 0.35)
	animacja_powiadomienia.tween_callback(_ukryj_powiadomienie_endless)


func _ukryj_powiadomienie_endless() -> void:
	if is_instance_valid(endless_powiadomienie):
		endless_powiadomienie.hide()


func zakoncz_po_czasie() -> void:
	if wynik_gracza > wynik_ai:
		zakoncz_mecz("Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_1)
	elif wynik_ai > wynik_gracza:
		zakoncz_mecz("Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_2)
	else:
		zakoncz_mecz("Koniec czasu — remis!")


func dodaj_info_endless() -> void:
	endless_info = HBoxContainer.new()
	endless_info.name = "InformacjaEndless"
	endless_info.custom_minimum_size = Vector2(SZEROKOSC_INFO_ENDLESS, 58.0)
	endless_info.add_theme_constant_override("separation", 10)
	endless_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endless_info.z_index = 10
	_dodaj_grupe_info_endless(endless_info, "IDEALNE ODBICIE", 150.0, KOLOR_TURKUS_ENDLESS)
	_dodaj_grupe_info_endless(endless_info, "PRĘDKOŚĆ PIŁKI", 150.0, Color("#b8c9dc"))
	_dodaj_grupe_info_endless(endless_info, "PALETKA", 120.0, KOLOR_FIOLET_ENDLESS)
	gra.add_child(endless_info)
	endless_powiadomienie = Label.new()
	endless_powiadomienie.name = "PowiadomienieEndless"
	endless_powiadomienie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endless_powiadomienie.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	endless_powiadomienie.add_theme_font_override("font", CZCIONKA_ENDLESS)
	endless_powiadomienie.add_theme_color_override("font_color", KOLOR_TURKUS_ENDLESS)
	endless_powiadomienie.add_theme_color_override("font_shadow_color", Color(KOLOR_TURKUS_ENDLESS, 0.5))
	endless_powiadomienie.add_theme_constant_override("shadow_offset_x", 0)
	endless_powiadomienie.add_theme_constant_override("shadow_offset_y", 0)
	endless_powiadomienie.add_theme_constant_override("shadow_outline_size", 12)
	endless_powiadomienie.position = Vector2(
		(Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5 - 280.0,
		Ustawienia.gorna_granica + 42.0
	)
	endless_powiadomienie.size = Vector2(560.0, 62.0)
	endless_powiadomienie.pivot_offset = endless_powiadomienie.size * 0.5
	endless_powiadomienie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endless_powiadomienie.z_index = 20
	gra.add_child(endless_powiadomienie)
	endless_powiadomienie.hide()
	get_viewport().size_changed.connect(_ustaw_pozycje_info_endless)
	_ustaw_pozycje_info_endless()
	_odswiez_info_endless()


func _dodaj_grupe_info_endless(uklad: HBoxContainer, tytul: String, szerokosc: float, akcent: Color, rozmiar_wartosci: int = 15) -> void:
	var karta := PanelContainer.new()
	karta.custom_minimum_size = Vector2(szerokosc, 58.0)
	karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color("#101f34d9")
	styl.border_color = Color(akcent, 0.45)
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(10)
	styl.content_margin_left = 6.0
	styl.content_margin_right = 6.0
	styl.content_margin_top = 4.0
	styl.content_margin_bottom = 4.0
	karta.add_theme_stylebox_override("panel", styl)
	uklad.add_child(karta)
	var kolumna := VBoxContainer.new()
	kolumna.alignment = BoxContainer.ALIGNMENT_CENTER
	kolumna.add_theme_constant_override("separation", 1)
	kolumna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	karta.add_child(kolumna)
	var etykieta := Label.new()
	etykieta.text = tytul
	etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta.add_theme_font_override("font", CZCIONKA_ENDLESS)
	etykieta.add_theme_font_size_override("font_size", 10)
	etykieta.add_theme_color_override("font_color", Color("#9fb3ca"))
	etykieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolumna.add_child(etykieta)
	var wartosc := Label.new()
	wartosc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wartosc.add_theme_font_override("font", CZCIONKA_ENDLESS)
	wartosc.add_theme_font_size_override("font_size", rozmiar_wartosci)
	wartosc.add_theme_color_override("font_color", akcent)
	wartosc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolumna.add_child(wartosc)
	endless_wartosci.append(wartosc)


func _ustaw_pozycje_info_endless() -> void:
	var wymiar = get_viewport().get_visible_rect().size
	var szerokosc_planszy = Ustawienia.prawa_granica - Ustawienia.lewa_granica
	var szerokosc = minf(SZEROKOSC_INFO_ENDLESS, maxf(0.0, szerokosc_planszy - 24.0))
	var prawa_krawedz = minf(Ustawienia.prawa_granica - 12.0, wymiar.x - 12.0)
	var x = prawa_krawedz - szerokosc
	var y = minf(Ustawienia.dolna_granica + 12.0, wymiar.y - 70.0)
	if is_instance_valid(endless_info):
		endless_info.position = Vector2(x, y)
		endless_info.size = Vector2(szerokosc, 58.0)
	if is_instance_valid(endless_powiadomienie):
		endless_powiadomienie.position = Vector2(
			(Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5 - 280.0,
			Ustawienia.gorna_granica + 42.0
		)


func _odswiez_info_endless() -> void:
	if endless_info == null:
		return
	var pilka := gra.pilka()
	var predkosc_razy = pilka.predkosc / Pilka.SPEED * pilka.mnoznik_ruchu_chwilowy()
	var procent_paletki := 100
	if endless_wysokosc_startowa > 0.0:
		procent_paletki = roundi(endless_wysokosc_aktualna / endless_wysokosc_startowa * 100.0)
	endless_wartosci[0].text = "+2 PKT"
	endless_wartosci[1].text = "×%.2f" % predkosc_razy
	endless_wartosci[2].text = "%d%%" % procent_paletki


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
	if is_instance_valid(endless_powiadomienie):
		endless_powiadomienie.hide()
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
	podsumowanie.nowy_rekord_endless = endless_rekord_pobity
	if Ustawienia.tryb == "endless":
		var pilka := gra.pilka()
		podsumowanie.mnoznik_predkosci_endless = pilka.predkosc / Pilka.SPEED * pilka.mnoznik_ruchu_chwilowy()
		if endless_wysokosc_startowa > 0.0:
			podsumowanie.rozmiar_paletki_endless = roundi(endless_wysokosc_aktualna / endless_wysokosc_startowa * 100.0)
	podsumowanie.najdluzsza_wymiana = najdluzsza_wymiana
	return podsumowanie
