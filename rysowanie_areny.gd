class_name RysowanieAreny
extends Node2D

const TLO_MECZU = preload("res://tlo_meczu.gd")
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")
const KOLOR_RAMKI = Color("#46627e")
const KOLOR_KARTY_WYNIKU = Color("#0b1725")
const KOLOR_GRACZA = Color("#55d8f2")
const KOLOR_AI = Color("#ff647a")

var gra: GraPongAPI
var tlo_meczu: TloMeczu
var poprzedni_akcent: Color = Color.TRANSPARENT
var czas_hologramu: float = 0.0


func _czy_tryb_areny() -> bool:
	return Ustawienia.tryb == "arena" or (Ustawienia.tryb == "online" and Ustawienia.online_arena)


func _ready() -> void:
	gra = get_parent()
	tlo_meczu = TLO_MECZU.new()
	tlo_meczu.name = "TloMeczu"
	tlo_meczu.show_behind_parent = true
	add_child(tlo_meczu)



func _manager_areny() -> ArenaManagerAPI:
	return gra.menedzer_areny()


func _process(delta: float) -> void:
	czas_hologramu += delta
	queue_redraw()
	tlo_meczu.ustaw_obszar(Rect2(
		Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica),
		Vector2(Ustawienia.prawa_granica - Ustawienia.lewa_granica, Ustawienia.dolna_granica - Ustawienia.gorna_granica)
	), get_viewport_rect().size)
	var akcent := KOLOR_GRACZA
	if Ustawienia.tryb == "endless":
		akcent = Color("#ad83ff")
	elif _czy_tryb_areny():
		akcent = Color("#ffb454")
		var manager := _manager_areny()
		if manager != null and manager.strefa_przyspieszenia_aktywna():
			akcent = Color("#55e7ff")
		elif manager != null and manager.sciana_srodka_aktywna():
			akcent = Color("#fa789e")
	if akcent != poprzedni_akcent:
		poprzedni_akcent = akcent


func _draw():

	var plansza = Rect2(
		Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica),
		Vector2(
			Ustawienia.prawa_granica - Ustawienia.lewa_granica,
			Ustawienia.dolna_granica - Ustawienia.gorna_granica
		)
	)

	_rysuj_rame(plansza)
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
		draw_rect(karta_gracza, KOLOR_GRACZA, false, 2.0)
		if is_instance_valid(gra.efekty_wizualne):
			for strona in range(2 if Ustawienia.tryb != "endless" else 1):
				var impuls := gra.efekty_wizualne.impuls_wyniku[strona] / 0.35
				if impuls > 0.0:
					var karta: Rect2 = karta_gracza if strona == 0 else karta_ai
					var kolor := KOLOR_GRACZA if strona == 0 else KOLOR_AI
					draw_rect(karta.grow((1.0 - impuls) * 10.0), Color(kolor, impuls * Ustawienia.intensywnosc_efektow / 100.0 * 0.5), false, 2.0, true)
		if Ustawienia.tryb != "endless":
			draw_rect(karta_ai, KOLOR_KARTY_WYNIKU, true)
			draw_rect(karta_ai, KOLOR_AI, false, 2.0)
		if Ustawienia.tryb == "arena":
			var nazwa_gracza = "GRACZ 1" if Ustawienia.arena_dwoch_graczy else "GRACZ"
			var nazwa_przeciwnika = "GRACZ 2" if Ustawienia.arena_dwoch_graczy else "BOT"
			_rysuj_wynik_na_srodku(karta_gracza, str(gra.wynik_gracza), KOLOR_GRACZA, nazwa_gracza)
			_rysuj_wynik_na_srodku(karta_ai, str(gra.wynik_ai), KOLOR_AI, nazwa_przeciwnika)
		elif Ustawienia.tryb == "online":
			_rysuj_wynik_na_srodku(karta_gracza, str(gra.wynik_gracza), KOLOR_GRACZA, Siec.nazwa_gracza_1.to_upper())
			_rysuj_wynik_na_srodku(karta_ai, str(gra.wynik_ai), KOLOR_AI, Siec.nazwa_gracza_2.to_upper())


func _rysuj_rame(plansza: Rect2) -> void:
	var sila := Ustawienia.intensywnosc_efektow / 100.0
	var kolor := poprzedni_akcent
	draw_rect(plansza.grow(5.0), Color("#080e18"), false, 10.0)
	draw_rect(plansza.grow(7.0), Color(KOLOR_RAMKI, 0.65), false, 1.5, true)
	draw_rect(plansza.grow(3.0), Color(kolor, 0.12 * sila), false, 6.0, true)
	draw_rect(plansza, KOLOR_RAMKI.lerp(kolor, 0.38), false, 2.0, true)
	for i in range(4):
		var naroznik := Vector2(plansza.position.x if i % 2 == 0 else plansza.end.x, plansza.position.y if i < 2 else plansza.end.y)
		var kierunek := Vector2(1.0 if i % 2 == 0 else -1.0, 1.0 if i < 2 else -1.0)
		for os in [Vector2(kierunek.x, 0.0), Vector2(0.0, kierunek.y)]:
			draw_line(naroznik, naroznik + os * 30.0, Color(kolor, 0.10 * sila), 8.0, true)
			draw_line(naroznik, naroznik + os * 30.0, Color(kolor, 0.7), 2.0, true)
	if sila > 0.0:
		for i in range(4):
			var poziomo := i < 2
			var poczatek := Vector2(plansza.position.x, plansza.position.y if i == 0 else plansza.end.y) if poziomo else Vector2(plansza.position.x if i == 2 else plansza.end.x, plansza.position.y)
			var kierunek := Vector2.RIGHT if poziomo else Vector2.DOWN
			var dlugosc := plansza.size.x if poziomo else plansza.size.y
			var pozycja := fposmod(czas_hologramu * 28.0 + i * 153.0, dlugosc + 70.0) - 35.0
			for j in range(7):
				var od := clampf(pozycja + j * 5.0, 0.0, dlugosc)
				var do := clampf(pozycja + (j + 1) * 5.0, 0.0, dlugosc)
				draw_line(poczatek + kierunek * od, poczatek + kierunek * do, Color(kolor, sin(float(j + 1) / 8.0 * PI) * 0.32 * sila), 2.5, true)
	if is_instance_valid(gra.efekty_wizualne):
		for kontakt in gra.efekty_wizualne.kontakty_ramy:
			var miejsce := to_local(kontakt.miejsce)
			var styczna := kontakt.normalna.orthogonal()
			var alfa := pow(1.0 - kontakt.czas / 0.3, 2.0) * sila
			for j in range(7):
				var od := float(j - 3) * 7.0
				var a := miejsce + styczna * (od - 3.5)
				var b := miejsce + styczna * (od + 3.5)
				a = a.clamp(plansza.position, plansza.end)
				b = b.clamp(plansza.position, plansza.end)
				var jasnosc := alfa * (1.0 - absf(float(j - 3)) / 4.0)
				draw_line(a, b, Color(kolor, jasnosc * 0.22), 8.0, true)
				draw_line(a, b, Color(kolor.lerp(Color.WHITE, 0.5), jasnosc), 2.5, true)


func _rysuj_znaczniki_srodka(srodek: Vector2, gora: float, dol: float) -> void:
	var sila := Ustawienia.intensywnosc_efektow / 100.0
	var kolor := KOLOR_RAMKI.lerp(poprzedni_akcent, 0.45)
	var impuls_punktu := 0.0
	if is_instance_valid(gra.efekty_wizualne):
		impuls_punktu = maxf(gra.efekty_wizualne.impuls_wyniku.x, gra.efekty_wizualne.impuls_wyniku.y) / 0.35 * sila
	var pozycja_impulsu := gora + fposmod(czas_hologramu * 48.0, dol - gora + 100.0) - 50.0
	for zakres in [Vector2(gora, srodek.y - 68.0), Vector2(srodek.y + 68.0, dol)]:
		var y: float = zakres.x
		while y < zakres.y:
			var koniec := minf(y + 11.0, zakres.y)
			var impuls := exp(-pow((y - pozycja_impulsu) / 35.0, 2.0)) * sila
			var alfa := 0.45 + impuls * 0.25 + impuls_punktu * 0.25
			draw_line(Vector2(srodek.x, y), Vector2(srodek.x, koniec), Color(poprzedni_akcent, (0.035 + impuls * 0.06 + impuls_punktu * 0.08) * sila), 6.0, true)
			draw_line(Vector2(srodek.x, y), Vector2(srodek.x, koniec), Color(kolor.lerp(poprzedni_akcent, impuls), alfa), 1.8, true)
			y += 23.0
	var puls := (0.5 + 0.5 * sin(czas_hologramu * 1.25)) * sila
	var detale := 40 if Ustawienia.jakosc_tla == 0 else 72
	draw_arc(srodek, 58.0, 0.0, TAU, detale, Color(kolor, 0.20 + puls * 0.03), 1.2, true)
	draw_circle(srodek, 7.0, Color(poprzedni_akcent, (0.025 + puls * 0.015) * sila))
	draw_circle(srodek, 2.5, Color(kolor.lerp(poprzedni_akcent, 0.35), 0.4 + puls * 0.08))


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
