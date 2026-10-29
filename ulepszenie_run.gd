class_name UlepszenieRun
extends RefCounted

enum Efekt { PALETKA, PILKA, ZYCIE, DASH, MAGNES, TARCZA, PRECYZJA, REGENERACJA, SPOWOLNIENIE, OBRAZENIA, KRUSZYCIEL, ROJ, WIEKSZA_PILKA }
enum Rzadkosc { ZWYKLE, NIEPOSPOLITE, RZADKIE, EPICKIE, LEGENDARNE }

const WAGI_RZADKOSCI: Array[int] = [44, 28, 15, 7, 6]

var id: StringName
var nazwa: String
var opis: String
var rarity: Rzadkosc
var maxStacks: int
var efekt: Efekt


func _init(identyfikator: StringName, tytul: String, opis_pl: String, rzadkosc: Rzadkosc, limit: int, dzialanie: Efekt) -> void:
	id = identyfikator
	nazwa = tytul
	opis = opis_pl
	rarity = rzadkosc
	maxStacks = limit
	efekt = dzialanie


func apply(stan: RunState) -> void:
	if stan.liczba_stosow(id) >= maxStacks:
		return
	stan.ownedStacks.append(id)
	var stosy := stan.liczba_stosow(id)
	match efekt:
		Efekt.PALETKA:
			stan.paddleWidthMult = 1.0 + 0.10 * stosy
		Efekt.PILKA:
			stan.ballSpeedMult = 1.0 - 0.06 * stosy
		Efekt.ZYCIE:
			stan.maxLives += 1
			stan.lives = mini(stan.lives + 1, stan.maxLives)
		Efekt.DASH:
			stan.dashCooldownMult = pow(0.85, stosy)
		Efekt.MAGNES:
			stan.magnetRadius = 100.0 + 30.0 * stosy
			stan.magnetPull = 0.6 * stosy
		Efekt.TARCZA:
			stan.shieldRecharge = 15
			if stosy == 1:
				stan.shieldHits = stan.shieldRecharge
		Efekt.PRECYZJA:
			stan.precisionBonus = stosy
		Efekt.REGENERACJA:
			stan.regenInterval = 25
		Efekt.SPOWOLNIENIE:
			stan.slowMult = pow(0.7, stosy)
		Efekt.OBRAZENIA:
			stan.ballDamage = 1 + stosy
		Efekt.KRUSZYCIEL:
			stan.targetRewardMult = 1.0 + 0.25 * stosy
		Efekt.ROJ:
			stan.targetSpawnRateMult = 1.0 + 0.30 * stosy
		Efekt.WIEKSZA_PILKA:
			stan.ballSizeMult = 1.0 + 0.15 * stosy


func nazwa_rzadkosci() -> String:
	match rarity:
		Rzadkosc.NIEPOSPOLITE: return "niepospolite"
		Rzadkosc.RZADKIE: return "rzadkie"
		Rzadkosc.EPICKIE: return "epickie"
		Rzadkosc.LEGENDARNE: return "legendarne"
	return "zwykłe"


func kolor_rzadkosci() -> Color:
	match rarity:
		Rzadkosc.NIEPOSPOLITE: return Color("#69cf8d")
		Rzadkosc.RZADKIE: return Color("#65adff")
		Rzadkosc.EPICKIE: return Color("#ad83ff")
		Rzadkosc.LEGENDARNE: return Color("#edc568")
	return Color("#a7b0be")


func describe(stosy: int) -> String:
	return wartosc_opisu(stosy)


func wartosc_opisu(stosy: int) -> String:
	match efekt:
		Efekt.PALETKA: return "Długość paletki: +%s%%" % _liczba(10.0 * stosy)
		Efekt.PILKA: return "Prędkość piłki: -%s%%" % _liczba(6.0 * stosy)
		Efekt.ZYCIE: return "Życia: +%d | Limit żyć: +%d" % [stosy, stosy]
		Efekt.DASH: return "Odnowienie dasha: -%s%%" % _liczba((1.0 - pow(0.85, stosy)) * 100.0)
		Efekt.MAGNES: return "Przyciąganie do paletki: %s px | Siła: %s" % [_liczba(100.0 + 30.0 * stosy if stosy > 0 else 0.0), _liczba(0.6 * stosy)]
		Efekt.TARCZA: return "Ratuje piłkę | Odnowienie: 15 pkt" if stosy > 0 else "Nieaktywna"
		Efekt.PRECYZJA: return "Trafienie krawędzią: +%d pkt" % stosy
		Efekt.REGENERACJA: return "+1 życie co 25 pkt (do limitu)" if stosy > 0 else "Nieaktywna"
		Efekt.SPOWOLNIENIE: return "Po dashu: prędkość piłki -%s%% przez 0,5 s" % _liczba((1.0 - pow(0.7, stosy)) * 100.0)
		Efekt.OBRAZENIA: return "Obrażenia piłki: %d" % (1 + stosy)
		Efekt.KRUSZYCIEL: return "Punkty za kryształy: +%s%%" % _liczba(25.0 * stosy)
		Efekt.ROJ: return "Częstotliwość kryształów: +%s%%" % _liczba(30.0 * stosy)
		Efekt.WIEKSZA_PILKA: return "Średnica piłki: +%s%%" % _liczba(15.0 * stosy)
	return opis


static func _liczba(wartosc: float) -> String:
	return String.num(wartosc, 2).replace(".", ",")


static func katalog() -> Array[UlepszenieRun]:
	return [
		UlepszenieRun.new(&"paletka", "Szersza paletka", "+10% długości paletki", Rzadkosc.ZWYKLE, 5, Efekt.PALETKA),
		UlepszenieRun.new(&"pilka", "Wolniejsza piłka", "-6% prędkości piłki", Rzadkosc.NIEPOSPOLITE, 3, Efekt.PILKA),
		UlepszenieRun.new(&"wieksza_pilka", "Większa piłka", "Średnica piłki: +15%", Rzadkosc.ZWYKLE, 3, Efekt.WIEKSZA_PILKA),
		UlepszenieRun.new(&"zycie", "Dodatkowe życie", "Życia: +1 | Limit żyć: +1", Rzadkosc.EPICKIE, 3, Efekt.ZYCIE),
		UlepszenieRun.new(&"dash", "Szybszy dash", "Odnowienie dasha: -15%", Rzadkosc.ZWYKLE, 3, Efekt.DASH),
		UlepszenieRun.new(&"magnes", "Magnes", "Przyciąga piłkę do paletki", Rzadkosc.NIEPOSPOLITE, 3, Efekt.MAGNES),
		UlepszenieRun.new(&"tarcza", "Tarcza ściany", "Ratuje piłkę | Odnowienie: 15 pkt", Rzadkosc.EPICKIE, 2, Efekt.TARCZA),
		UlepszenieRun.new(&"precyzja", "Precyzja", "Trafienie krawędzią: +1 pkt", Rzadkosc.NIEPOSPOLITE, 3, Efekt.PRECYZJA),
		UlepszenieRun.new(&"regeneracja", "Regeneracja", "+1 życie co 25 pkt (do limitu)", Rzadkosc.LEGENDARNE, 1, Efekt.REGENERACJA),
		UlepszenieRun.new(&"spowolnienie", "Spowolnienie na dash", "Po dashu: prędkość piłki -30% przez 0,5 s", Rzadkosc.RZADKIE, 2, Efekt.SPOWOLNIENIE),
		UlepszenieRun.new(&"obrazenia", "Mocniejsze uderzenie", "Obrażenia piłki: +1", Rzadkosc.RZADKIE, 5, Efekt.OBRAZENIA),
		UlepszenieRun.new(&"kruszyciel", "Kruszyciel", "Punkty za kryształy: +25%", Rzadkosc.RZADKIE, 3, Efekt.KRUSZYCIEL),
		UlepszenieRun.new(&"roj", "Rój kryształów", "Częstotliwość kryształów: +30%", Rzadkosc.RZADKIE, 2, Efekt.ROJ)
	]


static func losuj(stan: RunState, rejestr: Array[UlepszenieRun], nagroda_bossa: bool = false) -> Array[UlepszenieRun]:
	var dostepne: Array[UlepszenieRun] = []
	var wynik: Array[UlepszenieRun] = []
	for ulepszenie in rejestr:
		if stan.liczba_stosow(ulepszenie.id) < ulepszenie.maxStacks:
			dostepne.append(ulepszenie)
	if nagroda_bossa:
		var rzadkie: Array[UlepszenieRun] = []
		for ulepszenie in dostepne:
			if ulepszenie.rarity >= Rzadkosc.RZADKIE:
				rzadkie.append(ulepszenie)
		if not rzadkie.is_empty():
			wynik.append(_losuj_z_puli(rzadkie))
	while wynik.size() < 3 and not dostepne.is_empty():
		if not wynik.is_empty():
			var ostatnie_id := wynik[-1].id
			for i in range(dostepne.size() - 1, -1, -1):
				if dostepne[i].id == ostatnie_id:
					dostepne.remove_at(i)
		if not dostepne.is_empty():
			wynik.append(_losuj_z_puli(dostepne))
	return wynik


static func _losuj_z_puli(dostepne: Array[UlepszenieRun]) -> UlepszenieRun:
	var obecne: Array[bool] = [false, false, false, false, false]
	for ulepszenie in dostepne:
		obecne[ulepszenie.rarity] = true
	var suma: int = 0
	for rzadkosc in range(WAGI_RZADKOSCI.size()):
		if obecne[rzadkosc]:
			suma += WAGI_RZADKOSCI[rzadkosc]
	if suma == 0:
		return null
	var los := randi_range(1, suma)
	var kategoria: int = 0
	for rzadkosc in range(WAGI_RZADKOSCI.size()):
		if not obecne[rzadkosc]:
			continue
		los -= WAGI_RZADKOSCI[rzadkosc]
		if los <= 0:
			kategoria = rzadkosc
			break
	var pula: Array[UlepszenieRun] = []
	for ulepszenie in dostepne:
		if ulepszenie.rarity == kategoria:
			pula.append(ulepszenie)
	return pula[randi_range(0, pula.size() - 1)]
