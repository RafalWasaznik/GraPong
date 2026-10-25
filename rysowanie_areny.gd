class_name RysowanieAreny
extends Node2D

const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")
const KOLOR_TLA = Color("#080e18")
const KOLOR_PLANSZY = Color("#142235")
const KOLOR_RAMKI = Color("#46627e")
const KOLOR_KARTY_WYNIKU = Color("#0b1725")
const KOLOR_GRACZA = Color("#55d8f2")
const KOLOR_AI = Color("#ff647a")

var gra: GraPongAPI


func _czy_tryb_areny() -> bool:
	return Ustawienia.tryb == "arena" or (Ustawienia.tryb == "online" and Ustawienia.online_arena)


func _ready() -> void:
	gra = get_parent()


func _manager_areny() -> ArenaManagerAPI:
	return gra.menedzer_areny()


func _draw():
	var rozmiar_okna = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, rozmiar_okna), KOLOR_TLA, true)

	var plansza = Rect2(
		Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica),
		Vector2(
			Ustawienia.prawa_granica - Ustawienia.lewa_granica,
			Ustawienia.dolna_granica - Ustawienia.gorna_granica
		)
	)

	draw_rect(plansza, KOLOR_PLANSZY, true)
	draw_rect(plansza, KOLOR_RAMKI, false, 3.0)
	draw_rect(plansza.grow(-10.0), Color(0.24, 0.39, 0.54, 0.2), false, 1.0)
	_rysuj_gumowe_sciany()
	var manager_areny := _manager_areny()
	if _czy_tryb_areny() and manager_areny != null and manager_areny.wieksza_arena_aktywna():
		draw_rect(plansza, Color(0.65, 0.84, 1.0, 0.78), false, 3.0)

	var srodek_x = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) / 2.0
	var srodek_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) / 2.0
	if _czy_tryb_areny() and gra.postep_strefy() > 0.001:
		var szerokosc_strefy = 104.0 * gra.postep_strefy()
		var strefa = Rect2(
			Vector2(srodek_x - szerokosc_strefy * 0.5, Ustawienia.gorna_granica),
			Vector2(szerokosc_strefy, Ustawienia.dolna_granica - Ustawienia.gorna_granica)
		)
		draw_rect(strefa, Color(1.0, 0.73, 0.22, 0.13 * gra.postep_strefy()), true)
		var kolor_krawedzi = Color(1.0, 0.79, 0.34, 0.72 * gra.postep_strefy())
		draw_line(strefa.position, Vector2(strefa.position.x, strefa.end.y), kolor_krawedzi, 2.0)
		draw_line(Vector2(strefa.end.x, strefa.position.y), strefa.end, kolor_krawedzi, 2.0)
	if _czy_tryb_areny() and manager_areny != null and manager_areny.mocne_sciany_aktywne():
		var kolor_scian = Color(1.0, 0.78, 0.3, 0.8)
		draw_line(Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica), Vector2(Ustawienia.prawa_granica, Ustawienia.gorna_granica), kolor_scian, 4.0)
		draw_line(Vector2(Ustawienia.lewa_granica, Ustawienia.dolna_granica), Vector2(Ustawienia.prawa_granica, Ustawienia.dolna_granica), kolor_scian, 4.0)
	var sciana_srodka_aktywna = _czy_tryb_areny() and manager_areny != null and manager_areny.sciana_srodka_aktywna()
	_rysuj_znaczniki_srodka(
		Vector2(srodek_x, srodek_y),
		Ustawienia.gorna_granica + 20.0,
		Ustawienia.dolna_granica - 10.0
	)
	if sciana_srodka_aktywna:
		var srodek = Vector2(srodek_x, srodek_y)
		var alfa_sciany = manager_areny.przezroczystosc_sciany_srodka()
		draw_arc(srodek, 54.0, 0.0, TAU, 96, Color(1.0, 0.69, 0.3, 0.14 * alfa_sciany), 22.0 * alfa_sciany, true)
		draw_arc(srodek, 54.0, 0.0, TAU, 96, Color(1.0, 0.69, 0.3, alfa_sciany), 9.0 * alfa_sciany, true)
		draw_arc(srodek, 54.0, 0.0, TAU, 96, Color(1.0, 0.95, 0.85, alfa_sciany), 2.0 * alfa_sciany, true)
	_rysuj_bramke_areny()

	if not gra.mecz_zakonczony:
		var karta_gracza = gra.prostokat_karty_wyniku(0)
		var karta_ai = gra.prostokat_karty_wyniku(1)

		draw_rect(karta_gracza, KOLOR_KARTY_WYNIKU, true)
		draw_rect(karta_ai, KOLOR_KARTY_WYNIKU, true)
		draw_rect(karta_gracza, KOLOR_GRACZA, false, 2.0)
		draw_rect(karta_ai, Color("#a78bfa") if Ustawienia.tryb == "endless" else KOLOR_AI, false, 2.0)
		if Ustawienia.tryb == "arena":
			var nazwa_gracza = "GRACZ 1" if Ustawienia.arena_dwoch_graczy else "GRACZ"
			var nazwa_przeciwnika = "GRACZ 2" if Ustawienia.arena_dwoch_graczy else "BOT"
			_rysuj_wynik_na_srodku(karta_gracza, str(gra.wynik_gracza), KOLOR_GRACZA, nazwa_gracza)
			_rysuj_wynik_na_srodku(karta_ai, str(gra.wynik_ai), KOLOR_AI, nazwa_przeciwnika)
		elif Ustawienia.tryb == "online":
			_rysuj_wynik_na_srodku(karta_gracza, str(gra.wynik_gracza), KOLOR_GRACZA, Siec.nazwa_gracza_1.to_upper())
			_rysuj_wynik_na_srodku(karta_ai, str(gra.wynik_ai), KOLOR_AI, Siec.nazwa_gracza_2.to_upper())
		elif Ustawienia.tryb == "endless":
			_rysuj_nazwe_wyniku(karta_gracza, "WYNIK", KOLOR_GRACZA)
			_rysuj_nazwe_wyniku(karta_ai, "ŻYCIA", Color("#c4b5fd"))


func _rysuj_znaczniki_srodka(srodek: Vector2, gora: float, dol: float) -> void:
	var promien_okregu = 58.0
	var przerwa_okregu = 68.0
	var dlugosc_segmentu = 14.0
	var odstep_segmentow = 14.0
	var szerokosc_poswiaty = 7.0
	var kolor_poswiaty = Color(0.32, 0.89, 1.0, 0.045)
	var kolor_linii = Color(0.64, 0.77, 0.87, 0.48)

	for zakres in [Vector2(gora, srodek.y - przerwa_okregu), Vector2(srodek.y + przerwa_okregu, dol)]:
		var y = zakres.x
		while y < zakres.y:
			var koniec = minf(y + dlugosc_segmentu, zakres.y)
			draw_line(Vector2(srodek.x, y), Vector2(srodek.x, koniec), kolor_poswiaty, szerokosc_poswiaty, true)
			draw_line(Vector2(srodek.x, y), Vector2(srodek.x, koniec), kolor_linii, 2.2, true)
			draw_circle(Vector2(srodek.x, y), 1.1, kolor_linii)
			draw_circle(Vector2(srodek.x, koniec), 1.1, kolor_linii)
			y += dlugosc_segmentu + odstep_segmentow

	# Wielowarstwowe obręcze i delikatne akcenty zastępują płaski, domyślny okrąg.
	draw_arc(srodek, promien_okregu, 0.0, TAU, 128, Color(0.32, 0.89, 1.0, 0.035), 9.0, true)
	draw_arc(srodek, promien_okregu, 0.0, TAU, 128, Color(0.31, 0.52, 0.68, 0.30), 1.8, true)
	draw_arc(srodek, promien_okregu - 6.0, 0.0, TAU, 128, Color(0.31, 0.52, 0.68, 0.10), 1.0, true)
	draw_circle(srodek, 4.0, Color(0.32, 0.89, 1.0, 0.045))
	draw_circle(srodek, 1.7, Color(0.69, 0.86, 0.96, 0.34))


func _rysuj_gumowe_sciany() -> void:
	var dane_gumy: DaneGumowejSciany = gra.dane_gumowej_sciany()
	for strona in [-1, 1]:
		var x_bazowy = Ustawienia.lewa_granica if strona < 0 else Ustawienia.prawa_granica
		var kolor = KOLOR_GRACZA if strona < 0 else KOLOR_AI
		if dane_gumy.strona != strona or dane_gumy.ugiecie <= 0.1:
			draw_line(
				Vector2(x_bazowy, Ustawienia.gorna_granica),
				Vector2(x_bazowy, Ustawienia.dolna_granica),
				Color(kolor, 0.22),
				1.5,
				true
			)
			continue

		var punkty = PackedVector2Array()
		var y = Ustawienia.gorna_granica
		while y <= Ustawienia.dolna_granica:
			var odleglosc = (y - dane_gumy.y) / 66.0
			var profil = exp(-odleglosc * odleglosc)
			var x = x_bazowy + float(strona) * dane_gumy.ugiecie * profil
			punkty.append(Vector2(x, y))
			y += 10.0
		punkty.append(Vector2(
		x_bazowy + float(strona) * dane_gumy.ugiecie * exp(-pow((Ustawienia.dolna_granica - dane_gumy.y) / 66.0, 2.0)),
			Ustawienia.dolna_granica
		))
		draw_polyline(punkty, Color(kolor, 0.2), 8.0, true)
		draw_polyline(punkty, Color(kolor, 0.82), 2.5, true)


func _rysuj_bramke_areny() -> void:
	var manager_areny := _manager_areny()
	if not _czy_tryb_areny() or manager_areny == null:
		return
	if not manager_areny.bramka_aktywna():
		return

	var segmenty := manager_areny.dane_bramki()
	var alfa = manager_areny.przezroczystosc_bramki()
	var kolor_bramki = Color("#a78bfa")
	var kolor_wypelnienia = kolor_bramki
	kolor_wypelnienia.a = 0.88 * alfa
	var kolor_obramowania = Color(0.86, 0.79, 1.0, 0.95 * alfa)
	for segment in segmenty:
		draw_rect(segment, kolor_wypelnienia, true)
		draw_rect(segment, kolor_obramowania, false, 2.0)


func _rysuj_wynik_na_srodku(karta: Rect2, tekst: String, kolor: Color, nazwa: String) -> void:
	var font = FONT_ARCADE
	var proporcja = karta.size.y / 54.0
	var rozmiar_nazwy = maxi(9, roundi(12.0 * proporcja))
	var rozmiar_wyniku = maxi(28, roundi(36.0 * proporcja))
	var linia_nazwy = karta.position.y - 4.0
	var srodek_wyniku_y = karta.position.y + karta.size.y * 0.5
	var linia_wyniku = srodek_wyniku_y + (font.get_ascent(rozmiar_wyniku) - font.get_descent(rozmiar_wyniku)) * 0.5
	draw_string(
		font,
		Vector2(karta.position.x + 2.0, linia_nazwy),
		nazwa,
		HORIZONTAL_ALIGNMENT_CENTER,
		karta.size.x - 4.0,
		rozmiar_nazwy,
		Color(kolor, 0.78)
	)
	draw_string(
		font,
		Vector2(karta.position.x, linia_wyniku),
		tekst,
		HORIZONTAL_ALIGNMENT_CENTER,
		karta.size.x,
		rozmiar_wyniku,
		kolor
	)


func _rysuj_nazwe_wyniku(karta: Rect2, nazwa: String, kolor: Color) -> void:
	var font = FONT_ARCADE
	var rozmiar_czcionki = 19
	draw_string(
		font,
		Vector2(karta.position.x, karta.position.y - 5.0),
		nazwa,
		HORIZONTAL_ALIGNMENT_CENTER,
		karta.size.x,
		rozmiar_czcionki,
		kolor
	)


