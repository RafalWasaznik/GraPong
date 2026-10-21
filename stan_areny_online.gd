class_name StanArenyOnline
extends RefCounted

const WERSJA_SCHEMATU := 1 # Zwiększaj przy każdej niezgodnej zmianie pól pakietu Areny.
# Jedno źródło prawdy dla pól JSON: nazwy muszą odpowiadać właściwościom DTO.
const SCHEMAT_POL := {
	"stan": TYPE_STRING,
	"czas": TYPE_FLOAT,
	"wydarzenie": TYPE_STRING,
	"drugie": TYPE_STRING,
	"wiatr": TYPE_FLOAT,
	"wariant_bramki": TYPE_STRING,
	"bramka": TYPE_BOOL,
	"bramka_faza": TYPE_FLOAT,
	"bramka_czas": TYPE_FLOAT,
	"bramka_postep": TYPE_FLOAT,
	"bramka_wygaszanie": TYPE_BOOL,
	"bramka_czas_wygaszania": TYPE_FLOAT,
	"bramka_alfa_poczatkowa": TYPE_FLOAT,
	"bramka_czas_docelowy": TYPE_FLOAT
}

var stan: String = "oczekiwanie"
var czas: float = 0.0
var wydarzenie: String = ""
var drugie: String = ""
var wiatr: float = 1.0
var wariant_bramki: String = ""
var bramka: bool = false
var bramka_faza: float = 0.0
var bramka_czas: float = 0.0
var bramka_postep: float = 0.0
var bramka_wygaszanie: bool = false
var bramka_czas_wygaszania: float = 0.0
var bramka_alfa_poczatkowa: float = 0.0
var bramka_czas_docelowy: float = 0.28


func do_danych() -> Dictionary:
	return {
		"wersja_schematu": WERSJA_SCHEMATU,
		"stan": stan,
		"czas": czas,
		"wydarzenie": wydarzenie,
		"drugie": drugie,
		"wiatr": wiatr,
		"wariant_bramki": wariant_bramki,
		"bramka": bramka,
		"bramka_faza": bramka_faza,
		"bramka_czas": bramka_czas,
		"bramka_postep": bramka_postep,
		"bramka_wygaszanie": bramka_wygaszanie,
		"bramka_czas_wygaszania": bramka_czas_wygaszania,
		"bramka_alfa_poczatkowa": bramka_alfa_poczatkowa,
		"bramka_czas_docelowy": bramka_czas_docelowy
	}


static func z_danych(dane: Variant) -> StanArenyOnline:
	if typeof(dane) != TYPE_DICTIONARY or dane.size() != SCHEMAT_POL.size() + 1:
		return null
	if typeof(dane.get("wersja_schematu")) != TYPE_INT or dane["wersja_schematu"] != WERSJA_SCHEMATU:
		return null
	for pole in dane:
		if pole != "wersja_schematu" and not SCHEMAT_POL.has(pole):
			return null
	for pole in SCHEMAT_POL:
		if not dane.has(pole):
			return null
		var typ_oczekiwany: int = SCHEMAT_POL[pole]
		var typ_rzeczywisty: int = typeof(dane[pole])
		if typ_oczekiwany == TYPE_FLOAT:
			if typ_rzeczywisty not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(dane[pole])):
				return null
		elif typ_rzeczywisty != typ_oczekiwany:
			return null
	var wynik := StanArenyOnline.new()
	wynik.stan = str(dane["stan"])
	wynik.czas = float(dane["czas"])
	wynik.wydarzenie = str(dane["wydarzenie"])
	wynik.drugie = str(dane["drugie"])
	wynik.wiatr = float(dane["wiatr"])
	wynik.wariant_bramki = str(dane["wariant_bramki"])
	wynik.bramka = bool(dane["bramka"])
	wynik.bramka_faza = float(dane["bramka_faza"])
	wynik.bramka_czas = float(dane["bramka_czas"])
	wynik.bramka_postep = float(dane["bramka_postep"])
	wynik.bramka_wygaszanie = bool(dane["bramka_wygaszanie"])
	wynik.bramka_czas_wygaszania = float(dane["bramka_czas_wygaszania"])
	wynik.bramka_alfa_poczatkowa = float(dane["bramka_alfa_poczatkowa"])
	wynik.bramka_czas_docelowy = float(dane["bramka_czas_docelowy"])
	if wynik.stan not in ["oczekiwanie", "ostrzezenie", "aktywne"]:
		return null
	if wynik.czas < 0.0 or wynik.bramka_czas < 0.0 or wynik.bramka_czas_wygaszania < 0.0:
		return null
	if absf(wynik.wiatr) != 1.0:
		return null
	if wynik.bramka_faza < 0.0 or wynik.bramka_postep < 0.0 or wynik.bramka_postep > 1.0:
		return null
	if wynik.bramka_alfa_poczatkowa < 0.0 or wynik.bramka_alfa_poczatkowa > 1.0:
		return null
	if wynik.bramka_czas_docelowy <= 0.0:
		return null
	return wynik
