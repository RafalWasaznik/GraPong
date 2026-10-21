class_name StanMeczuOnline
extends RefCounted

# Wersja 2 wprowadza jawny, wersjonowany obiekt stanu Areny zamiast tablicy pozycyjnej.
const WERSJA_SCHEMATU := 2

const POLA_CALOWITE := [
	"wynik_gracza", "wynik_ai", "runda_online", "stat_odbicia_gracza",
	"stat_odbicia_rywala", "stat_mocne_odbicia_gracza", "stat_mocne_odbicia_rywala",
	"biezaca_wymiana", "najdluzsza_wymiana", "odbicia_paletki", "odbicia_sciany"
]
const POLA_LICZBOWE := ["lewa_y", "prawa_y", "dash_lewy", "dash_prawy", "czas_meczu", "czas_pozostaly"]
const POLA_WYMAGANE := [
	"pilka", "lewa_y", "prawa_y", "dash_lewy", "dash_prawy", "wynik_gracza", "wynik_ai",
	"koniec", "runda_online", "czas_meczu", "stat_odbicia_gracza", "stat_odbicia_rywala",
	"stat_mocne_odbicia_gracza", "stat_mocne_odbicia_rywala", "biezaca_wymiana",
	"najdluzsza_wymiana", "komunikat_konca", "czas_pozostaly", "odbicia_paletki", "odbicia_sciany", "arena"
]
var pilka: Vector2
var lewa_y: float
var prawa_y: float
var dash_lewy: float
var dash_prawy: float
var wynik_gracza: int
var wynik_ai: int
var koniec: bool
var runda_online: int
var czas_meczu: float
var stat_odbicia_gracza: int
var stat_odbicia_rywala: int
var stat_mocne_odbicia_gracza: int
var stat_mocne_odbicia_rywala: int
var biezaca_wymiana: int
var najdluzsza_wymiana: int
var komunikat_konca: String
var czas_pozostaly: float
var odbicia_paletki: int
var odbicia_sciany: int
var arena: StanArenyOnline = StanArenyOnline.new()


static func z_pakietu(pakiet: Dictionary) -> StanMeczuOnline:
	if pakiet.get("wersja_schematu") != WERSJA_SCHEMATU or typeof(pakiet.get("wersja_schematu")) != TYPE_INT:
		return null
	if pakiet.size() != POLA_WYMAGANE.size() + 1:
		return null
	for pole in POLA_WYMAGANE:
		if not pakiet.has(pole):
			return null
	for pole in pakiet:
		if pole != "wersja_schematu" and pole not in POLA_WYMAGANE:
			return null
	if typeof(pakiet["pilka"]) != TYPE_ARRAY or pakiet["pilka"].size() != 2:
		return null
	for skladowa in pakiet["pilka"]:
		if typeof(skladowa) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(skladowa)):
			return null
	var pozycja_pilki := Vector2(float(pakiet["pilka"][0]), float(pakiet["pilka"][1]))
	if not pozycja_pilki.is_finite():
		return null
	if typeof(pakiet["koniec"]) != TYPE_BOOL or typeof(pakiet["komunikat_konca"]) != TYPE_STRING:
		return null
	if typeof(pakiet["arena"]) != TYPE_DICTIONARY:
		return null
	var arena := StanArenyOnline.z_danych(pakiet["arena"])
	if arena == null:
		return null
	for pole in POLA_CALOWITE:
		if typeof(pakiet[pole]) != TYPE_INT or int(pakiet[pole]) < 0:
			return null
	for pole in POLA_LICZBOWE:
		if typeof(pakiet[pole]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(pakiet[pole])):
			return null
	if float(pakiet["dash_lewy"]) < 0.0 or float(pakiet["dash_prawy"]) < 0.0:
		return null
	if float(pakiet["czas_meczu"]) < 0.0 or float(pakiet["czas_pozostaly"]) < 0.0:
		return null
	var stan := StanMeczuOnline.new()
	stan.pilka = pozycja_pilki
	stan.lewa_y = float(pakiet["lewa_y"])
	stan.prawa_y = float(pakiet["prawa_y"])
	stan.dash_lewy = float(pakiet["dash_lewy"])
	stan.dash_prawy = float(pakiet["dash_prawy"])
	stan.wynik_gracza = int(pakiet["wynik_gracza"])
	stan.wynik_ai = int(pakiet["wynik_ai"])
	stan.koniec = bool(pakiet["koniec"])
	stan.runda_online = int(pakiet["runda_online"])
	stan.czas_meczu = float(pakiet["czas_meczu"])
	stan.stat_odbicia_gracza = int(pakiet["stat_odbicia_gracza"])
	stan.stat_odbicia_rywala = int(pakiet["stat_odbicia_rywala"])
	stan.stat_mocne_odbicia_gracza = int(pakiet["stat_mocne_odbicia_gracza"])
	stan.stat_mocne_odbicia_rywala = int(pakiet["stat_mocne_odbicia_rywala"])
	stan.biezaca_wymiana = int(pakiet["biezaca_wymiana"])
	stan.najdluzsza_wymiana = int(pakiet["najdluzsza_wymiana"])
	stan.komunikat_konca = str(pakiet["komunikat_konca"])
	stan.czas_pozostaly = float(pakiet["czas_pozostaly"])
	stan.odbicia_paletki = int(pakiet["odbicia_paletki"])
	stan.odbicia_sciany = int(pakiet["odbicia_sciany"])
	stan.arena = arena
	return stan


func do_json() -> String:
	var pakiet := {
		"wersja_schematu": WERSJA_SCHEMATU,
		"pilka": [pilka.x, pilka.y],
		"lewa_y": lewa_y,
		"prawa_y": prawa_y,
		"dash_lewy": dash_lewy,
		"dash_prawy": dash_prawy,
		"wynik_gracza": wynik_gracza,
		"wynik_ai": wynik_ai,
		"koniec": koniec,
		"runda_online": runda_online,
		"czas_meczu": czas_meczu,
		"stat_odbicia_gracza": stat_odbicia_gracza,
		"stat_odbicia_rywala": stat_odbicia_rywala,
		"stat_mocne_odbicia_gracza": stat_mocne_odbicia_gracza,
		"stat_mocne_odbicia_rywala": stat_mocne_odbicia_rywala,
		"biezaca_wymiana": biezaca_wymiana,
		"najdluzsza_wymiana": najdluzsza_wymiana,
		"komunikat_konca": komunikat_konca,
		"czas_pozostaly": czas_pozostaly,
		"odbicia_paletki": odbicia_paletki,
		"odbicia_sciany": odbicia_sciany,
		"arena": arena.do_danych()
	}
	return JSON.stringify(pakiet)


static func z_jsonu(tekst: String) -> StanMeczuOnline:
	var dane: Variant = JSON.parse_string(tekst)
	if typeof(dane) != TYPE_DICTIONARY:
		return null
	return z_pakietu(dane)
