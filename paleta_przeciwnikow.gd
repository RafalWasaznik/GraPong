class_name PaletaPrzeciwnikow
extends RefCounted

var korpus: Color
var pancerz: Color
var swiatlo: Color
var rdzen: Color
var zagrozenie: Color
var krysztal: Color
var pekniecie: Color
var pancerz_ciezki: Color

static var _palety: Array[PaletaPrzeciwnikow] = []


func _init(motyw: int = 0) -> void:
	var kolory: PackedColorArray
	match motyw:
		1:
			kolory = PackedColorArray([Color("#30351b"), Color("#697535"), Color("#d8f36a"), Color("#fff4a1"), Color("#ffb83f"), Color("#badd4b"), Color("#ffe087"), Color("#a6b773")])
		2:
			kolory = PackedColorArray([Color("#402324"), Color("#8b4741"), Color("#ff7760"), Color("#fff0cf"), Color("#ff4c35"), Color("#ff9c75"), Color("#ffce9f"), Color("#c9977d")])
		3:
			kolory = PackedColorArray([Color("#382137"), Color("#7b3d70"), Color("#f47bd2"), Color("#ffd1ed"), Color("#ff597f"), Color("#dc71ca"), Color("#ffacd5"), Color("#ba86ad")])
		_:
			kolory = PackedColorArray([Color("#3d2c1b"), Color("#866239"), Color("#ffc267"), Color("#fff0b3"), Color("#ff853e"), Color("#f2b84b"), Color("#ffdf8e"), Color("#c7a878")])
	korpus = kolory[0]
	pancerz = kolory[1]
	swiatlo = kolory[2]
	rdzen = kolory[3]
	zagrozenie = kolory[4]
	krysztal = kolory[5]
	pekniecie = kolory[6]
	pancerz_ciezki = kolory[7]


static func pobierz(_wezel: Node) -> PaletaPrzeciwnikow:
	if _palety.is_empty():
		for motyw in range(4):
			_palety.append(PaletaPrzeciwnikow.new(motyw))
	return _palety[clampi(Ustawienia.motyw_przeciwnikow, 0, 3)]
