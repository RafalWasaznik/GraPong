class_name ArenaKatalog
extends RefCounted

const DEFINICJE_MODYFIKATOROW = {
	"wiatr_gora": {
		"nazwa": "Podmuch w górę",
		"opis": "Piłka skręca ku górze.",
		"czas": 5.5,
		"niezgodne": ["wiatr_dol"]
	},
	"wiatr_dol": {
		"nazwa": "Podmuch w dół",
		"opis": "Piłka skręca ku dołowi.",
		"czas": 5.5,
		"niezgodne": ["wiatr_gora"]
	},
	"przyspieszenie": {
		"nazwa": "Przyspieszenie",
		"opis": "Piłka przyspiesza podczas wymiany.",
		"czas": 5.5,
		"niezgodne": []
	},
	"przyciaganie_srodka": {
		"nazwa": "Przyciąganie do środka",
		"opis": "Piłka ciągnie ku środkowi.",
		"czas": 5.5,
		"niezgodne": []
	},
	"sciana_srodka": {
		"nazwa": "Ściana na środku",
		"opis": "Okrąg pośrodku odbija piłkę.",
		"czas": 5.5,
		"niezgodne": ["ruchoma_bramka"]
	},
	"waska_arena": {
		"nazwa": "Mała arena",
		"opis": "Zwęża planszę w pionie.",
		"czas": 5.5,
		"niezgodne": ["wieksza_arena"]
	},
	"strefa_przyspieszenia": {
		"nazwa": "Strefa przyspieszenia",
		"opis": "Środek planszy przyspiesza piłkę.",
		"czas": 5.5,
		"niezgodne": []
	},
	"krotsze_paletki": {
		"nazwa": "Krótsze paletki",
		"opis": "Obie paletki są niższe.",
		"czas": 8.0,
		"niezgodne": ["duza_paletka"]
	},
	"duza_paletka": {
		"nazwa": "Duża paletka",
		"opis": "Obie paletki są wyższe.",
		"czas": 5.5,
		"niezgodne": ["krotsze_paletki"]
	},
	"duza_pilka": {
		"nazwa": "Duża piłka",
		"opis": "Piłka zwiększa swój rozmiar.",
		"czas": 5.5,
		"niezgodne": []
	},
	"mocne_sciany": {
		"nazwa": "Mocne odbicie od ściany",
		"opis": "Krawędzie mocniej rozpędzają piłkę.",
		"czas": 5.5,
		"niezgodne": []
	},
	"wieksza_arena": {
		"nazwa": "Większa arena",
		"opis": "Poszerza planszę w obu osiach.",
		"czas": 5.5,
		"niezgodne": ["waska_arena"]
	},
	"ruchoma_bramka": {
		"nazwa": "Ruchoma ściana",
		"opis": "Ruchoma ściana zmienia położenie otworu.",
		"czas": 9.0,
		"niezgodne": ["sciana_srodka"]
	}
}

static func definicja(nazwa: String) -> Dictionary:
	return DEFINICJE_MODYFIKATOROW.get(nazwa, {})


static func nazwa(nazwa_wydarzenia: String) -> String:
	return str(definicja(nazwa_wydarzenia).get("nazwa", ""))


static func opis(nazwa_wydarzenia: String) -> String:
	return str(definicja(nazwa_wydarzenia).get("opis", ""))


static func para_kompatybilna(pierwsze: String, drugie: String) -> bool:
	var niezgodne_pierwsze: Array = definicja(pierwsze).get("niezgodne", [])
	var niezgodne_drugie: Array = definicja(drugie).get("niezgodne", [])
	return drugie not in niezgodne_pierwsze and pierwsze not in niezgodne_drugie
