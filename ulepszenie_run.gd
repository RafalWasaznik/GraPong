class_name UlepszenieRun
extends RefCounted

enum Efekt { PALETKA, PILKA, ZYCIE, DASH, MAGNES, TARCZA, PRECYZJA, REGENERACJA, KLATWA, SPOWOLNIENIE, OBRAZENIA, KRUSZYCIEL, ROJ }
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
		Efekt.KLATWA:
			stan.curseSpeedMult = pow(1.15, stosy)
			stan.ballSpeedMult = stan.baseSlowMult * stan.curseSpeedMult
			stan.scoreMult = pow(1.5, stosy)
		Efekt.SPOWOLNIENIE:
			stan.slowMult = pow(0.7, stosy)
		Efekt.OBRAZENIA:
			stan.ballDamage = 1 + stosy
		Efekt.KRUSZYCIEL:
			stan.targetRewardMult = 1.0 + 0.25 * stosy
		Efekt.ROJ:
			stan.targetSpawnRateMult = 1.0 + 0.30 * stosy


func nazwa_rzadkosci() -> String:
	match rarity:
		Rzadkosc.RZADKIE: return "rzadkie"
		Rzadkosc.PRZEKLETE: return "klątwa"
	return "zwykłe"


func kolor_rzadkosci() -> Color:
	match rarity:
		Rzadkosc.RZADKIE: return Color("#ad83ff")
		Rzadkosc.PRZEKLETE: return Color("#ff5c8a")
	return Color("#55e7ff")


func describe(stosy: int) -> String:
	var podglad := RunState.new()
	var definicja := UlepszenieRun.new(id, nazwa, opis, rarity, maxi(maxStacks, stosy), efekt)
	for i in range(stosy):
		definicja.apply(podglad)
	podglad.rozpocznij_dash()
	match efekt:
		Efekt.PALETKA:
			return "Długość paletki +%s%%" % _liczba((podglad.paddleWidthMult - 1.0) * 100.0)
		Efekt.PILKA:
			return "Prędkość piłki -%s%%" % _liczba((1.0 - podglad.baseSlowMult) * 100.0)
		Efekt.ZYCIE:
			return "Limit żyć +%d; przyznane życia +%d" % [podglad.maxLives - RunState.new().maxLives, stosy]
		Efekt.DASH:
			return "Odnowienie zrywu -%s%%" % _liczba((1.0 - podglad.dashCooldownMult) * 100.0)
		Efekt.MAGNES:
			return "Magnes: zasięg %s px, siła %s" % [_liczba(podglad.magnetRadius), _liczba(podglad.magnetPull)]
		Efekt.TARCZA:
			return "Tarcza: %d odbić do odnowienia" % podglad.shieldRecharge if stosy > 0 else "Tarcza nieaktywna"
		Efekt.PRECYZJA:
			return "Premia za trafienie krawędzią: +%d pkt" % podglad.precisionBonus
		Efekt.REGENERACJA:
			return "Regeneracja: +1 życie co %d odbić (do limitu)" % podglad.regenInterval if stosy > 0 else "Regeneracja nieaktywna"
		Efekt.KLATWA:
			return "Koszt: +%s%% prędkości piłki; korzyść: wynik x%s" % [_liczba((podglad.curseSpeedMult - 1.0) * 100.0), _liczba(podglad.scoreMult)]
		Efekt.SPOWOLNIENIE:
			return "Zryw: piłka wolniejsza o %s%% przez %s s" % [_liczba((1.0 - podglad.slowMult) * 100.0), _liczba(podglad.slowRemaining)]
		Efekt.OBRAZENIA:
			return "Obrażenia piłki: %d" % podglad.ballDamage
		Efekt.KRUSZYCIEL:
			return "Punkty za kryształy +%s%%" % _liczba((podglad.targetRewardMult - 1.0) * 100.0)
		Efekt.ROJ:
			return "Częstotliwość kryształów +%s%%" % _liczba((podglad.targetSpawnRateMult - 1.0) * 100.0)
	return opis


func wartosc_opisu(stosy: int) -> String:
	match efekt:
		Efekt.PALETKA: return "+%s%% długości" % _liczba(10.0 * stosy)
		Efekt.PILKA: return "-%s%% prędkości" % _liczba(6.0 * stosy)
		Efekt.ZYCIE: return "+%d żyć / limitu" % stosy
		Efekt.DASH: return "-%s%% odnowienia" % _liczba((1.0 - pow(0.85, stosy)) * 100.0)
		Efekt.MAGNES: return "%s px / siła %s" % [_liczba(100.0 + 30.0 * stosy if stosy > 0 else 0.0), _liczba(0.6 * stosy)]
		Efekt.TARCZA: return "co 15 odbić" if stosy > 0 else "nieaktywna"
		Efekt.PRECYZJA: return "+%d pkt" % stosy
		Efekt.REGENERACJA: return "+1 życie / 25 odbić" if stosy > 0 else "nieaktywna"
		Efekt.KLATWA: return "wynik x%s / prędkość +%s%%" % [_liczba(pow(1.5, stosy)), _liczba((pow(1.15, stosy) - 1.0) * 100.0)]
		Efekt.SPOWOLNIENIE: return "-%s%% / 0,5 s" % _liczba((1.0 - pow(0.7, stosy)) * 100.0)
		Efekt.OBRAZENIA: return "%d obrażeń" % (1 + stosy)
		Efekt.KRUSZYCIEL: return "+%s%% punktów" % _liczba(25.0 * stosy)
		Efekt.ROJ: return "+%s%% kryształów" % _liczba(30.0 * stosy)
	return opis


static func _liczba(wartosc: float) -> String:
	return String.num(wartosc, 2).replace(".", ",")


static func katalog() -> Array[UlepszenieRun]:
	return [
		UlepszenieRun.new(&"paletka", "Szersza paletka", "+10% długości paletki", Rzadkosc.ZWYKLE, 5, Efekt.PALETKA),
		UlepszenieRun.new(&"pilka", "Wolniejsza piłka", "-6% prędkości piłki", Rzadkosc.ZWYKLE, 3, Efekt.PILKA),
		UlepszenieRun.new(&"zycie", "Dodatkowe życie", "+1 życie", Rzadkosc.RZADKIE, 3, Efekt.ZYCIE),
		UlepszenieRun.new(&"dash", "Szybszy dash", "-15% czasu odnowienia dasha na stos", Rzadkosc.ZWYKLE, 3, Efekt.DASH),
		UlepszenieRun.new(&"magnes", "Magnes", "Lekko przyciąga piłkę do paletki; stos zwiększa zasięg i siłę", Rzadkosc.ZWYKLE, 3, Efekt.MAGNES),
		UlepszenieRun.new(&"tarcza", "Tarcza ściany", "Odbija straconą piłkę; odnawia się co 15 odbić", Rzadkosc.ZWYKLE, 2, Efekt.TARCZA),
		UlepszenieRun.new(&"precyzja", "Precyzja", "+1 punkt za trafienie krawędzią paletki na stos", Rzadkosc.ZWYKLE, 3, Efekt.PRECYZJA),
		UlepszenieRun.new(&"regeneracja", "Regeneracja", "Co 25 odbić +1 życie do maksymalnej liczby", Rzadkosc.RZADKIE, 1, Efekt.REGENERACJA),
		UlepszenieRun.new(&"klatwa", "Klątwa szybkości", "+15% prędkości piłki i wynik ×1,5 na stos", Rzadkosc.PRZEKLETE, 2, Efekt.KLATWA),
		UlepszenieRun.new(&"spowolnienie", "Spowolnienie na dash", "Dash spowalnia piłkę o 30% na stos przez 0,5 s", Rzadkosc.ZWYKLE, 2, Efekt.SPOWOLNIENIE),
		UlepszenieRun.new(&"obrazenia", "Mocniejsze uderzenie", "+1 do obrażeń piłki na stos", Rzadkosc.ZWYKLE, 5, Efekt.OBRAZENIA),
		UlepszenieRun.new(&"kruszyciel", "Kruszyciel", "+25% punktów za zniszczone kryształy na stos", Rzadkosc.ZWYKLE, 3, Efekt.KRUSZYCIEL),
		UlepszenieRun.new(&"roj", "Rój kryształów", "+30% częstotliwości pojawiania kryształów na stos", Rzadkosc.ZWYKLE, 2, Efekt.ROJ)
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
			if ulepszenie.rarity == Rzadkosc.RZADKIE:
				rzadkie.append(ulepszenie)
		if rzadkie.is_empty():
			for ulepszenie in rejestr:
				if ulepszenie.rarity == Rzadkosc.RZADKIE:
					var dodatkowe := UlepszenieRun.new(ulepszenie.id, ulepszenie.nazwa, ulepszenie.opis, ulepszenie.rarity, stan.liczba_stosow(ulepszenie.id) + 1, ulepszenie.efekt)
					rzadkie.append(dodatkowe)
					dostepne.append(dodatkowe)
		if not rzadkie.is_empty():
			var gwarantowane := rzadkie[randi_range(0, rzadkie.size() - 1)]
			wynik.append(gwarantowane)
			dostepne.erase(gwarantowane)
		if dostepne.size() < 2:
			for ulepszenie in rejestr:
				var obecne := false
				for oferta in dostepne + wynik:
					obecne = obecne or oferta.id == ulepszenie.id
				if not obecne:
					dostepne.append(UlepszenieRun.new(ulepszenie.id, ulepszenie.nazwa, ulepszenie.opis, ulepszenie.rarity, stan.liczba_stosow(ulepszenie.id) + 1, ulepszenie.efekt))
				if dostepne.size() >= 2:
					break
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
