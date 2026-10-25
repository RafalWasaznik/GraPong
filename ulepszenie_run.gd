class_name UlepszenieRun
extends RefCounted

enum Efekt { PALETKA, PILKA, ZYCIE, DASH, MULTI, MAGNES, TARCZA, PRECYZJA, REGENERACJA, KLATWA, SPOWOLNIENIE }
enum Rzadkosc { ZWYKLE, RZADKIE, PRZEKLETE }

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
			stan.baseSlowMult = 1.0 - 0.06 * stosy
			stan.ballSpeedMult = stan.baseSlowMult * stan.curseSpeedMult
		Efekt.ZYCIE:
			stan.maxLives += 1
			stan.lives = mini(stan.lives + 1, stan.maxLives)
		Efekt.DASH:
			stan.dashCooldownMult = pow(0.85, stosy)
		Efekt.MULTI:
			stan.ballCount = 1 + stosy
		Efekt.MAGNES:
			stan.magnetRadius = 100.0 + 30.0 * stosy
			stan.magnetPull = 0.6 * stosy
		Efekt.TARCZA:
			stan.shieldRecharge = 20 - 5 * stosy
			if stosy == 1:
				stan.shieldHits = stan.shieldRecharge
		Efekt.PRECYZJA:
			stan.precisionBonus = stosy
		Efekt.REGENERACJA:
			stan.regenInterval = 25
		Efekt.KLATWA:
			stan.curseSpeedMult = pow(1.15, stosy)
			stan.ballSpeedMult = stan.baseSlowMult * stan.curseSpeedMult
			stan.scoreMult = pow(1.5, stosy)
		Efekt.SPOWOLNIENIE:
			stan.slowMult = pow(0.7, stosy)


static func katalog() -> Array[UlepszenieRun]:
	return [
		UlepszenieRun.new(&"paletka", "Szersza paletka", "+10% długości paletki", Rzadkosc.ZWYKLE, 5, Efekt.PALETKA),
		UlepszenieRun.new(&"pilka", "Wolniejsza piłka", "-6% prędkości piłki", Rzadkosc.ZWYKLE, 3, Efekt.PILKA),
		UlepszenieRun.new(&"zycie", "Dodatkowe życie", "+1 życie", Rzadkosc.RZADKIE, 3, Efekt.ZYCIE),
		UlepszenieRun.new(&"dash", "Szybszy dash", "-15% czasu odnowienia dasha na stos", Rzadkosc.ZWYKLE, 3, Efekt.DASH),
		UlepszenieRun.new(&"multi", "Multi-piłka", "+1 piłka na planszy", Rzadkosc.RZADKIE, 2, Efekt.MULTI),
		UlepszenieRun.new(&"magnes", "Magnes", "Lekko przyciąga piłki do paletki; stos zwiększa zasięg i siłę", Rzadkosc.ZWYKLE, 3, Efekt.MAGNES),
		UlepszenieRun.new(&"tarcza", "Tarcza ściany", "Odbija straconą piłkę; odnawia się co 15/10 odbić", Rzadkosc.ZWYKLE, 2, Efekt.TARCZA),
		UlepszenieRun.new(&"precyzja", "Precyzja", "+1 punkt za trafienie krawędzią paletki na stos", Rzadkosc.ZWYKLE, 3, Efekt.PRECYZJA),
		UlepszenieRun.new(&"regeneracja", "Regeneracja", "Co 25 odbić +1 życie do maksymalnej liczby", Rzadkosc.RZADKIE, 1, Efekt.REGENERACJA),
		UlepszenieRun.new(&"klatwa", "Klątwa szybkości", "+15% prędkości piłek i wynik ×1,5 na stos", Rzadkosc.PRZEKLETE, 2, Efekt.KLATWA),
		UlepszenieRun.new(&"spowolnienie", "Spowolnienie na dash", "Dash spowalnia piłki o 30% na stos przez 0,5 s", Rzadkosc.ZWYKLE, 2, Efekt.SPOWOLNIENIE)
	]


static func losuj(stan: RunState, rejestr: Array[UlepszenieRun]) -> Array[UlepszenieRun]:
	var dostepne: Array[UlepszenieRun] = []
	var wynik: Array[UlepszenieRun] = []
	for ulepszenie in rejestr:
		if stan.liczba_stosow(ulepszenie.id) < ulepszenie.maxStacks:
			dostepne.append(ulepszenie)
	while wynik.size() < 3 and not dostepne.is_empty():
		var suma: float = 0.0
		for ulepszenie in dostepne:
			suma += 1.0 if ulepszenie.rarity != Rzadkosc.ZWYKLE else 3.0
		var los: float = randf() * suma
		var indeks: int = dostepne.size() - 1
		for i in range(dostepne.size()):
			los -= 1.0 if dostepne[i].rarity != Rzadkosc.ZWYKLE else 3.0
			if los <= 0.0:
				indeks = i
				break
		wynik.append(dostepne[indeks])
		dostepne.remove_at(indeks)
	return wynik
