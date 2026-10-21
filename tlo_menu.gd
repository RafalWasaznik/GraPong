class_name TloMenu
extends Control

const KOLOR_TLA = Color("#050914")
const KOLOR_TURKUS = Color("#55e7ff")
const KOLOR_FIOLET = Color("#ad83ff")
const KOLOR_ROZ = Color("#ff5fb7")
const KOLOR_PILKI = Color("#ffd166")
const KOLOR_BLYSKU = Color("#fff0a8")
const MAKS_PRZESZKOD = 15

var pilka = Vector2.ZERO
var predkosc = Vector2(460.0, 260.0)
var slady: Array[Vector2] = []
var lewa_y = 0.0
var prawa_y = 0.0
var gotowy = false
var przeszkody: Array[Dictionary] = []
var poprzednie_miejsca: Array[Vector2] = []
var czas_do_przeszkody = 1.4
var przyciemnienie = 0.0
var docelowe_przyciemnienie = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func ustaw_przyciemnienie(aktywne: bool) -> void:
	docelowe_przyciemnienie = 0.0 if not aktywne else 0.42


func _process(delta: float) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if not gotowy:
		var boisko = _prostokat_boisko()
		pilka = boisko.get_center()
		lewa_y = pilka.y
		prawa_y = pilka.y
		gotowy = true
	przyciemnienie = move_toward(przyciemnienie, docelowe_przyciemnienie, delta * 1.8)
	_symuluj(delta)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), KOLOR_TLA, true)
	draw_circle(Vector2(size.x * 0.12, size.y * 0.18), size.y * 0.42, Color("#183047", 0.12))
	draw_circle(Vector2(size.x * 0.88, size.y * 0.82), size.y * 0.48, Color("#241c3b", 0.10))
	if przyciemnienie > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.03, 0.055, przyciemnienie), true)
	var boisko = _prostokat_boisko()
	var paletka_w = clampf(boisko.size.x * 0.012, 12.0, 20.0)
	var paletka_h = clampf(boisko.size.y * 0.22, 66.0, 116.0)
	var lewa = Rect2(Vector2(boisko.position.x + 14.0, lewa_y - paletka_h * 0.5), Vector2(paletka_w, paletka_h))
	var prawa = Rect2(Vector2(boisko.end.x - 14.0 - paletka_w, prawa_y - paletka_h * 0.5), Vector2(paletka_w, paletka_h))
	draw_rect(lewa.grow(8.0), Color(KOLOR_TURKUS, 0.2), true)
	draw_rect(lewa, Color("#40dff5"), true)
	draw_rect(lewa, Color("#c7faff"), false, 2.0)
	draw_rect(prawa.grow(8.0), Color(KOLOR_ROZ, 0.22), true)
	draw_rect(prawa, Color("#ff4fa3"), true)
	draw_rect(prawa, Color("#ffe0f1"), false, 2.0)
	for i in range(slady.size()):
		var udzial = float(i + 1) / float(slady.size() + 1)
		draw_circle(slady[i], lerpf(2.0, 7.0, udzial), Color(KOLOR_PILKI, udzial * 0.55))
	for przeszkoda in przeszkody:
		var miejsce: Vector2 = boisko.position + Vector2(przeszkoda["miejsce"].x * boisko.size.x, przeszkoda["miejsce"].y * boisko.size.y)
		var blysk: float = przeszkoda["blysk"]
		var zycie_pozostale: float = float(przeszkoda["zycie"]) - float(przeszkoda["wiek"])
		var pojawienie: float = float(przeszkoda["pojawienie"]) * clampf(zycie_pozostale / 0.8, 0.0, 1.0)
		var kolor = KOLOR_BLYSKU if blysk > 0.0 else KOLOR_FIOLET
		draw_circle(miejsce, 17.0 * pojawienie + blysk * 8.0, Color(kolor, (0.12 + blysk * 0.3) * pojawienie))
		draw_circle(miejsce, 10.0 * pojawienie, Color("#17152a", pojawienie))
		draw_circle(miejsce, 8.0 * pojawienie, Color(kolor, (0.72 + blysk * 0.28) * pojawienie), false, 2.0)
		draw_circle(miejsce, 3.5 * pojawienie, Color.WHITE if blysk > 0.0 else Color(kolor, 0.9 * pojawienie))
	draw_circle(pilka, 20.0, Color("#ff9f43", 0.34))
	draw_circle(pilka, 11.0, KOLOR_PILKI)
	draw_circle(pilka, 5.5, Color.WHITE)


func _prostokat_boisko() -> Rect2:
	var margines_x = size.x * 0.045
	var margines_y = size.y * 0.08
	return Rect2(Vector2(margines_x, margines_y), Vector2(maxf(size.x - margines_x * 2.0, 1.0), maxf(size.y - margines_y * 2.0, 1.0)))


func _symuluj(delta: float) -> void:
	var boisko = _prostokat_boisko()
	if przeszkody.size() < MAKS_PRZESZKOD:
		czas_do_przeszkody -= delta
		if czas_do_przeszkody <= 0.0:
			_dodaj_przeszkode(boisko)
			czas_do_przeszkody = 0.45
	for indeks in range(przeszkody.size() - 1, -1, -1):
		var przeszkoda = przeszkody[indeks]
		przeszkoda["blysk"] = maxf(float(przeszkoda["blysk"]) - delta, 0.0)
		przeszkoda["pojawienie"] = minf(float(przeszkoda["pojawienie"]) + delta * 2.5, 1.0)
		przeszkoda["wiek"] = float(przeszkoda["wiek"]) + delta
		if float(przeszkoda["wiek"]) >= float(przeszkoda["zycie"]):
			poprzednie_miejsca.append(przeszkoda["miejsce"])
			if poprzednie_miejsca.size() > 3:
				poprzednie_miejsca.pop_front()
			przeszkody.remove_at(indeks)
	var paletka_h = clampf(boisko.size.y * 0.22, 66.0, 116.0)
	var paletka_w = clampf(boisko.size.x * 0.012, 12.0, 20.0)
	var stara_pozycja = pilka
	var nowa_pozycja = pilka + predkosc * delta
	var gora = boisko.position.y + 12.0
	var dol = boisko.end.y - 12.0
	if nowa_pozycja.y < gora or nowa_pozycja.y > dol:
		predkosc.y *= -1.0
		nowa_pozycja.y = clampf(nowa_pozycja.y, gora, dol)
	var x_lewej = boisko.position.x + 14.0 + paletka_w
	var x_prawej = boisko.end.x - 14.0 - paletka_w
	if predkosc.x < 0.0 and nowa_pozycja.x - 6.0 <= x_lewej and absf(nowa_pozycja.y - lewa_y) <= paletka_h * 0.5 + 8.0:
		predkosc.x = absf(predkosc.x)
		predkosc.y += (nowa_pozycja.y - lewa_y) * 1.2
	elif predkosc.x > 0.0 and nowa_pozycja.x + 6.0 >= x_prawej and absf(nowa_pozycja.y - prawa_y) <= paletka_h * 0.5 + 8.0:
		predkosc.x = -absf(predkosc.x)
		predkosc.y += (nowa_pozycja.y - prawa_y) * 1.2
	if nowa_pozycja.x < boisko.position.x + 5.0 or nowa_pozycja.x > boisko.end.x - 5.0:
		predkosc.x *= -1.0
		nowa_pozycja.x = clampf(nowa_pozycja.x, boisko.position.x + 5.0, boisko.end.x - 5.0)
	for przeszkoda in przeszkody:
		var miejsce: Vector2 = boisko.position + Vector2(przeszkoda["miejsce"].x * boisko.size.x, przeszkoda["miejsce"].y * boisko.size.y)
		var roznica = nowa_pozycja - miejsce
		var odleglosc = roznica.length()
		if odleglosc < 18.0:
			var normalna = roznica / odleglosc if odleglosc > 0.01 else -predkosc.normalized()
			if predkosc.dot(normalna) < 0.0:
				predkosc = predkosc.bounce(normalna)
				nowa_pozycja = miejsce + normalna * 18.5
				przeszkoda["blysk"] = 0.45
	predkosc = predkosc.normalized() * 460.0
	if slady.is_empty() or pilka.distance_to(slady.back()) > 2.5:
		slady.append(stara_pozycja)
		if slady.size() > 16:
			slady.pop_front()
	pilka = nowa_pozycja
	var cel_lewej = pilka.y if predkosc.x < 0.0 else boisko.get_center().y
	var cel_prawej = pilka.y if predkosc.x > 0.0 else boisko.get_center().y
	lewa_y = move_toward(lewa_y, cel_lewej, 300.0 * delta)
	prawa_y = move_toward(prawa_y, cel_prawej, 300.0 * delta)
	lewa_y = clampf(lewa_y, boisko.position.y + paletka_h * 0.5, boisko.end.y - paletka_h * 0.5)
	prawa_y = clampf(prawa_y, boisko.position.y + paletka_h * 0.5, boisko.end.y - paletka_h * 0.5)


func _dodaj_przeszkode(boisko: Rect2) -> void:
	var znaleziono = false
	var miejsce = Vector2.ZERO
	for _proba in range(100):
		var kandydat = Vector2(randf_range(0.08, 0.92), randf_range(0.1, 0.9))
		var pozycja = boisko.position + Vector2(kandydat.x * boisko.size.x, kandydat.y * boisko.size.y)
		if pozycja.distance_to(pilka) < 70.0:
			continue
		var blisko = false
		for istniejaca in przeszkody:
			var inne: Vector2 = boisko.position + Vector2(istniejaca["miejsce"].x * boisko.size.x, istniejaca["miejsce"].y * boisko.size.y)
			if pozycja.distance_to(inne) < 42.0:
				blisko = true
				break
		if not blisko:
			for poprzednia in poprzednie_miejsca:
				var inne: Vector2 = boisko.position + Vector2(poprzednia.x * boisko.size.x, poprzednia.y * boisko.size.y)
				if pozycja.distance_to(inne) < 55.0:
					blisko = true
					break
		if not blisko:
			miejsce = kandydat
			znaleziono = true
			break
	if znaleziono:
		przeszkody.append({"miejsce": miejsce, "blysk": 0.0, "pojawienie": 0.0, "wiek": 0.0, "zycie": randf_range(7.0, 11.0)})
