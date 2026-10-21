class_name UstawieniaMeczuOnline
extends RefCounted

const WERSJA_SCHEMATU := 1
const MIN_LIMIT_PUNKTOW := 1
const MAX_LIMIT_PUNKTOW := 50
const MIN_LIMIT_CZASU := 60.0
const MAX_LIMIT_CZASU := 3600.0

var tryb: String = "klasyczny"
var nazwa_gracza_1: String = "Gracz 1"
var nazwa_gracza_2: String = "Gracz 2"
var warunek: String = "punkty"
var limit_punktow: int = 5
var limit_czasu: float = 180.0


func do_json() -> String:
	return JSON.stringify({
		"wersja_schematu": WERSJA_SCHEMATU,
		"tryb": tryb,
		"nazwa_gracza_1": nazwa_gracza_1,
		"nazwa_gracza_2": nazwa_gracza_2,
		"warunek": warunek,
		"limit_punktow": limit_punktow,
		"limit_czasu": limit_czasu
	})


static func z_jsonu(tekst: String) -> UstawieniaMeczuOnline:
	var dane: Variant = JSON.parse_string(tekst)
	if typeof(dane) != TYPE_DICTIONARY:
		return null
	var pola_wymagane := ["wersja_schematu", "tryb", "nazwa_gracza_1", "nazwa_gracza_2", "warunek", "limit_punktow", "limit_czasu"]
	if dane.size() != pola_wymagane.size():
		return null
	for pole in pola_wymagane:
		if not dane.has(pole):
			return null
	for pole in dane:
		if pole not in pola_wymagane:
			return null
	if typeof(dane["wersja_schematu"]) != TYPE_INT or dane["wersja_schematu"] != WERSJA_SCHEMATU:
		return null
	for pole in ["tryb", "nazwa_gracza_1", "nazwa_gracza_2", "warunek"]:
		if typeof(dane[pole]) != TYPE_STRING:
			return null
	if dane["tryb"] not in ["klasyczny", "arena"] or dane["warunek"] not in ["punkty", "czas"]:
		return null
	if dane["nazwa_gracza_1"].strip_edges().is_empty() or dane["nazwa_gracza_2"].strip_edges().is_empty():
		return null
	if dane["nazwa_gracza_1"].length() > 16 or dane["nazwa_gracza_2"].length() > 16:
		return null
	if typeof(dane["limit_punktow"]) != TYPE_INT:
		return null
	if typeof(dane["limit_czasu"]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(dane["limit_czasu"])):
		return null
	var punkty: int = dane["limit_punktow"]
	var czas := float(dane["limit_czasu"])
	if punkty < MIN_LIMIT_PUNKTOW or punkty > MAX_LIMIT_PUNKTOW:
		return null
	if czas < MIN_LIMIT_CZASU or czas > MAX_LIMIT_CZASU:
		return null
	var wynik := UstawieniaMeczuOnline.new()
	wynik.tryb = dane["tryb"]
	wynik.nazwa_gracza_1 = dane["nazwa_gracza_1"]
	wynik.nazwa_gracza_2 = dane["nazwa_gracza_2"]
	wynik.warunek = dane["warunek"]
	wynik.limit_punktow = punkty
	wynik.limit_czasu = czas
	return wynik
