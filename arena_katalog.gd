class_name ArenaKatalog
extends RefCounted

static func wszystkie() -> Array[ArenaDefinicja]:
	return [
		_def("wiatr_gora", "Podmuch w górę", "Piłka skręca ku górze.", 5.5, ["wiatr_dol"]),
		_def("wiatr_dol", "Podmuch w dół", "Piłka skręca ku dołowi.", 5.5, ["wiatr_gora"]),
		_def("przyspieszenie", "Przyspieszenie", "Piłka przyspiesza podczas wymiany.", 5.5),
		_def("przyciaganie_srodka", "Przyciąganie do środka", "Piłka ciągnie ku środkowi.", 5.5),
		_def("sciana_srodka", "Ściana na środku", "Okrąg pośrodku odbija piłkę.", 5.5, ["ruchoma_bramka"]),
		_def("waska_arena", "Mała arena", "Zwęża planszę w pionie.", 5.5, ["wieksza_arena"]),
		_def("strefa_przyspieszenia", "Strefa przyspieszenia", "Środek planszy przyspiesza piłkę.", 5.5),
		_def("krotsze_paletki", "Krótsze paletki", "Obie paletki są niższe.", 8.0, ["duza_paletka"]),
		_def("duza_paletka", "Duża paletka", "Obie paletki są wyższe.", 5.5, ["krotsze_paletki"]),
		_def("duza_pilka", "Duża piłka", "Piłka zwiększa swój rozmiar.", 5.5),
		_def("mocne_sciany", "Mocne odbicie od ściany", "Krawędzie mocniej rozpędzają piłkę.", 5.5),
		_def("wieksza_arena", "Większa arena", "Poszerza planszę w obu osiach.", 5.5, ["waska_arena"]),
		_def("ruchoma_bramka", "Ruchoma ściana", "Ruchoma ściana zmienia położenie otworu.", 9.0, ["sciana_srodka"])
	]


static func definicja(id: String) -> ArenaDefinicja:
	for wpis in wszystkie():
		if wpis.id == id:
			return wpis
	return _def(id, "", "", 0.0)


static func nazwa(id: String) -> String:
	return definicja(id).nazwa


static func opis(id: String) -> String:
	return definicja(id).opis


static func para_kompatybilna(pierwsze: String, drugie: String) -> bool:
	return drugie not in definicja(pierwsze).niezgodne and pierwsze not in definicja(drugie).niezgodne


static func _def(id: String, nazwa: String, opis: String, czas: float, niezgodne: Array[String] = []) -> ArenaDefinicja:
	var wynik := ArenaDefinicja.new()
	wynik.id = id
	wynik.nazwa = nazwa
	wynik.opis = opis
	wynik.czas = czas
	wynik.niezgodne = niezgodne.duplicate()
	return wynik
