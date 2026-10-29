class_name BossRun
extends StaticBody2D

signal satelita_zniszczony

signal gotowy
signal pokonany
signal trafiono_gracza(pozycja: Vector2)

const ROZMIAR: Vector2 = Vector2(64.0, 144.0)
const PROMIEN_POCISKU: float = 9.0

const DIFFICULTY = TrudnoscRun.DIFFICULTY

class Trafienie extends RefCounted:
	var obrazenia: int
	var satelita: int
	var zewnetrzny_luk: bool

	func _init(ile: int, cel: int, luk: bool) -> void:
		obrazenia = ile
		satelita = cel
		zewnetrzny_luk = luk

var faza: BossDefinicja.FazaRdzenia
var sat_hp: Array[int] = []
var sat_kolizje: Array[CollisionShape2D] = []
var sat_blysk: Array[float] = []
var sat_cooldown: Array[float] = []
var sat_narodziny: Array[float] = []
var czas_wizualny: float = 0.0
var orbita: float = 0.0
var kierunek_orbity: float = 1.0
var czas_odwrocenia: float = 0.0
var czas_rdzenia: float = 0.0
var odsloniecie: float = 0.0
var nowe_odsloniecie: bool = false
var regeneracja: float = 0.0
var regeneruje: bool = false
var regen_indeks: int = 0
var sat_strzelec: int = 0
var indeks_fazy: int = 0
var numer_pulsu: int = 0
var puls: bool = false
var osloniety_blysk: float = 0.0
var luka_pulsu: float = 0.0
var trudnosc: TrudnoscRun
var totalPoints: int = 0
var kolejnosc: Array[int] = []
var ostatni_atak: int = -1
var atak: BossDefinicja.Atak
var ostrzezenie: float = 0.0
var seria_pozostalo: int = 0
var czas_serii: float = 0.0
var cel_ataku: Vector2
var start_ataku: Vector2
var zaplanowane_starty: Array[Vector2] = []
var zaplanowane_kierunki: Array[Vector2] = []

var definicja: BossDefinicja
var bossIndex: int = 0
var paletka: PaletkaBazowa
var pilka: Pilka
var hp: int
var maxHp: int
var intro: float = 1.2
var blysk: float = 0.0
var cooldown_trafienia: float = 0.0
var czas_ataku: float = 0.0
var kierunek: float = 1.0
var rozpad: float = 0.0
var pociski: Array[Vector2] = []
var predkosci_pociskow: Array[Vector2] = []
var trafienie_lokalne := Vector2.ZERO
var blysk_emitera: float = 0.0
var miejsca_blyskow: Array[Vector2] = []
var kierunki_blyskow: Array[Vector2] = []
var czasy_blyskow: Array[float] = []
var predkosci_satelitow: Array[Vector2] = []
var kolizja: CollisionShape2D


func _ready() -> void:
	process_physics_priority = -10
	Ustawienia.paleta_przeciwnikow_zmieniona.connect(queue_redraw)
	trudnosc = TrudnoscRun.getDifficulty(totalPoints, bossIndex)
	maxHp = trudnosc.boss_max_hp
	hp = maxHp
	collision_layer = 1
	collision_mask = 0
	kolizja = CollisionShape2D.new()
	var ksztalt := RectangleShape2D.new()
	ksztalt.size = ROZMIAR
	kolizja.shape = ksztalt
	add_child(kolizja)
	if definicja.id == &"rdzen":
		_przygotuj_rdzen()
	czas_ataku = trudnosc.cooldown_ms / 1000.0
	position = Vector2(Ustawienia.prawa_granica - (DIFFICULTY.ORBIT_RADIUS + 44.0 if faza != null else 90.0), (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5)


func przygotuj_trafienie(obrazenia: int, ksztalt: Object, normalna: Vector2) -> Trafienie:
	trafienie_lokalne = to_local(pilka.global_position) if is_instance_valid(pilka) else normalna * 28.0
	var indeks := sat_kolizje.find(ksztalt)
	var luk := indeks >= 0 and normalna.dot(sat_kolizje[indeks].position.normalized()) > 0.15
	return Trafienie.new(obrazenia, indeks, luk)


func trafienie(kontakt: Trafienie) -> void:
	var obrazenia := kontakt.obrazenia
	if faza != null:
		if intro > 0.0 or hp <= 0:
			return
		if kontakt.satelita >= 0:
			_traf_satellite(kontakt)
			return
		if _zywe_satelity() > 0 or regeneruje:
			osloniety_blysk = 0.16
			return
	if intro > 0.0 or hp <= 0 or cooldown_trafienia > 0.0:
		return
	hp = maxi(0, hp - obrazenia)
	blysk = 0.16
	cooldown_trafienia = 0.10
	if hp == 0:
		kolizja.set_deferred("disabled", true)
		for sat in sat_kolizje:
			sat.set_deferred("disabled", true)
		pociski.clear()
		predkosci_pociskow.clear()
		pilka.set_physics_process(false)
		pilka.set_process(false)
	queue_redraw()


func predkosc_powierzchni(ksztalt: Object) -> Vector2:
	var indeks := sat_kolizje.find(ksztalt)
	return constant_linear_velocity + (predkosci_satelitow[indeks] if indeks >= 0 and indeks < predkosci_satelitow.size() else Vector2.ZERO)


func _physics_process(delta: float) -> void:
	constant_linear_velocity = Vector2.ZERO
	predkosci_satelitow.clear()
	var pozycja_przed := global_position
	var sat_przed: Array[Vector2] = []
	for sat in sat_kolizje:
		sat_przed.append(sat.position)
	czas_wizualny += delta
	blysk_emitera = maxf(0.0, blysk_emitera - delta)
	for i in range(czasy_blyskow.size() - 1, -1, -1):
		czasy_blyskow[i] -= delta
		if czasy_blyskow[i] <= 0.0:
			czasy_blyskow.remove_at(i)
			miejsca_blyskow.remove_at(i)
			kierunki_blyskow.remove_at(i)
	queue_redraw()
	if intro > 0.0:
		intro = maxf(0.0, intro - delta)
		if intro == 0.0:
			gotowy.emit()
		return
	if hp <= 0:
		rozpad += delta
		if rozpad >= 0.5:
			set_physics_process(false)
			pokonany.emit()
			queue_free()
		return
	if faza != null:
		_aktualizuj_rdzen(delta)
	blysk = maxf(0.0, blysk - delta)
	cooldown_trafienia = maxf(0.0, cooldown_trafienia - delta)
	var minimum: float = Ustawienia.gorna_granica + 90.0
	var maksimum := maxf(minimum, Ustawienia.dolna_granica - ROZMIAR.y * 0.5 - 12.0)
	position.x = Ustawienia.prawa_granica - (DIFFICULTY.ORBIT_RADIUS + 44.0 if faza != null else 90.0)
	if faza == null and ostrzezenie <= 0.0 and seria_pozostalo == 0:
		position.y += kierunek * definicja.speed * delta
	if position.y <= minimum or position.y >= maksimum:
		position.y = clampf(position.y, minimum, maksimum)
		kierunek *= -1.0
	constant_linear_velocity = (global_position - pozycja_przed) / maxf(delta, 0.000001)
	for i in range(sat_kolizje.size()):
		predkosci_satelitow.append((sat_kolizje[i].position - sat_przed[i]) / maxf(delta, 0.000001))
	if ostrzezenie > 0.0:
		ostrzezenie = maxf(0.0, ostrzezenie - delta)
		if ostrzezenie == 0.0:
			_wystrzel_wzor()
	elif seria_pozostalo > 0:
		czas_serii -= delta
		if czas_serii <= 0.0:
			_dodaj_pocisk(start_ataku, (cel_ataku - start_ataku).normalized())
			seria_pozostalo -= 1
			czas_serii = DIFFICULTY.BURST_STEP_MS / 1000.0
	else:
		czas_ataku -= delta
		if czas_ataku <= 0.0:
			_zapowiedz_wzor()
	var ksztalt := paletka.kolizja.shape as RectangleShape2D
	var prostokat := Rect2(paletka.position - ksztalt.size * 0.5, ksztalt.size).grow(PROMIEN_POCISKU)
	for i in range(pociski.size() - 1, -1, -1):
		var start := pociski[i]
		pociski[i] += predkosci_pociskow[i] * delta
		var kontakt := prostokat.has_point(pociski[i]) or prostokat.has_point(start)
		var rogi := [prostokat.position, Vector2(prostokat.end.x, prostokat.position.y), prostokat.end, Vector2(prostokat.position.x, prostokat.end.y)]
		for j in range(4):
			kontakt = kontakt or Geometry2D.segment_intersects_segment(start, pociski[i], rogi[j], rogi[(j + 1) % 4]) != null
		if kontakt or pociski[i].x < Ustawienia.lewa_granica - 30.0 or pociski[i].x > Ustawienia.prawa_granica + 30.0 or pociski[i].y < Ustawienia.gorna_granica or pociski[i].y > Ustawienia.dolna_granica:
			var pozycja_kontaktu := pociski[i]
			pociski.remove_at(i)
			predkosci_pociskow.remove_at(i)
			if kontakt:
				trafiono_gracza.emit(pozycja_kontaktu)
				return


func odrocz_atak_po_stracie() -> void:
	pociski.clear()
	predkosci_pociskow.clear()
	ostrzezenie = 0.0
	seria_pozostalo = 0
	zaplanowane_starty.clear()
	zaplanowane_kierunki.clear()
	czas_ataku = maxf(RunState.INVULN_MS, trudnosc.cooldown_ms) / 1000.0
	queue_redraw()


func _zapowiedz_wzor() -> void:
	if faza != null:
		_zapowiedz_rdzen()
		return
	if kolejnosc.is_empty():
		kolejnosc.assign(trudnosc.patterns)
		kolejnosc.shuffle()
		if kolejnosc.size() > 1 and kolejnosc[-1] == ostatni_atak:
			var pierwszy := kolejnosc[0]
			kolejnosc[0] = kolejnosc[-1]
			kolejnosc[-1] = pierwszy
	ostatni_atak = kolejnosc.pop_back()
	atak = definicja.ataki[ostatni_atak]
	ostrzezenie = maxf(trudnosc.telegraph_ms, atak.telegraph_ms) / 1000.0
	start_ataku = position - Vector2(ROZMIAR.x * 0.5 + PROMIEN_POCISKU, 0.0)
	cel_ataku = paletka.position
	zaplanowane_starty.clear()
	zaplanowane_kierunki.clear()
	var kierunek_celu := (cel_ataku - start_ataku).normalized()
	match atak.wzor:
		BossDefinicja.Wzor.ROZRZUT:
			for kat in [-DIFFICULTY.SPREAD_ANGLE, DIFFICULTY.SPREAD_ANGLE]:
				zaplanowane_starty.append(start_ataku)
				zaplanowane_kierunki.append(kierunek_celu.rotated(kat))
		BossDefinicja.Wzor.SCIANA:
			var polowa_paletki := (paletka.kolizja.shape as RectangleShape2D).size.y * 0.5
			var luka := maxf(DIFFICULTY.WALL_GAP, polowa_paletki * 2.0 + PROMIEN_POCISKU * 4.0)
			var srodek_luki := clampf(cel_ataku.y, Ustawienia.gorna_granica + luka * 0.5, Ustawienia.dolna_granica - luka * 0.5)
			var y: float = Ustawienia.gorna_granica + PROMIEN_POCISKU
			while y < Ustawienia.dolna_granica - PROMIEN_POCISKU:
				if absf(y - srodek_luki) > luka * 0.5:
					zaplanowane_starty.append(Vector2(start_ataku.x, y))
					zaplanowane_kierunki.append(Vector2.LEFT)
				y += DIFFICULTY.WALL_SPACING
		_:
			zaplanowane_starty.append(start_ataku)
			zaplanowane_kierunki.append(kierunek_celu)


func _wystrzel_wzor() -> void:
	for i in range(zaplanowane_starty.size()):
		_dodaj_pocisk(zaplanowane_starty[i], zaplanowane_kierunki[i])
	if atak.wzor == BossDefinicja.Wzor.SERIA:
		seria_pozostalo = DIFFICULTY.BURST_COUNT - 1
		czas_serii = DIFFICULTY.BURST_STEP_MS / 1000.0
	czas_ataku = trudnosc.cooldown_ms / 1000.0


func _dodaj_pocisk(start: Vector2, kierunek_pocisku: Vector2) -> void:
	blysk_emitera = 0.15
	if czasy_blyskow.size() < 24:
		miejsca_blyskow.append(start)
		kierunki_blyskow.append(kierunek_pocisku)
		czasy_blyskow.append(0.15)
	var dystans := maxf(0.0, start.x - paletka.position.x)
	var predkosc := minf(trudnosc.projectile_speed, dystans / (DIFFICULTY.DODGE_TRAVEL_MIN_MS / 1000.0))
	if atak.wzor == BossDefinicja.Wzor.SCIANA:
		predkosc *= DIFFICULTY.WALL_SPEED_MULT
	elif puls:
		predkosc *= DIFFICULTY.PULSE_SPEED_MULT
	pociski.append(start)
	predkosci_pociskow.append(kierunek_pocisku * predkosc)


func _draw() -> void:
	var paleta := PaletaPrzeciwnikow.pobierz(self)
	var srodek_areny: float = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5
	var szerokosc_hp := minf(220.0, maxf(60.0, srodek_areny - Ustawienia.lewa_granica - 110.0))
	var polowa_hp := szerokosc_hp * 0.5
	var srodek := Vector2(Ustawienia.prawa_granica - polowa_hp - 4.0, Ustawienia.gorna_granica - 38.0) - position
	draw_rect(Rect2(srodek + Vector2(-polowa_hp - 4.0, 5), Vector2(szerokosc_hp + 8.0, 12)), Color(paleta.korpus, 0.92), true)
	draw_rect(Rect2(srodek + Vector2(-polowa_hp, 9), Vector2(szerokosc_hp, 4)), paleta.pancerz_ciezki, true)
	var postep_hp := float(hp) / float(maxHp)
	if postep_hp > 0.0:
		draw_rect(Rect2(srodek + Vector2(-polowa_hp, 9), Vector2(szerokosc_hp * postep_hp, 4)), paleta.pancerz, true)
		draw_rect(Rect2(srodek + Vector2(-polowa_hp, 9), Vector2(szerokosc_hp * postep_hp, 2)), paleta.rdzen.lerp(paleta.zagrozenie, 1.0 - postep_hp), true)
	for i in range(1, 10):
		var x := srodek.x - polowa_hp + szerokosc_hp * float(i) / 10.0
		draw_line(Vector2(x, srodek.y + 8.0), Vector2(x, srodek.y + 14.0), Color(paleta.korpus, 0.8), 1.0, true)
	if hp <= 0:
		_rysuj_rozpad()
		return
	if faza != null:
		_rysuj_rdzen(srodek)
	else:
		_rysuj_straznika()
	_rysuj_iskry_trafienia()
	_rysuj_pociski_i_ostrzezenie()


func etap_pancerza() -> int:
	var zdrowie := float(hp) / maxi(1, maxHp)
	return 0 if zdrowie > 0.75 else (1 if zdrowie > 0.5 else (2 if zdrowie > 0.25 else 3))


func _sila_wizualna() -> float:
	return clampf(Ustawienia.intensywnosc_efektow / 100.0, 0.0, 1.0)


func _energia_bossa() -> Color:
	return Color("#ffbd58") if faza == null else Color("#64e6e8")


func _ladunek_ataku() -> float:
	if ostrzezenie <= 0.0 or atak == null:
		return 0.0
	return clampf(1.0 - ostrzezenie / (maxf(trudnosc.telegraph_ms, atak.telegraph_ms) / 1000.0), 0.0, 1.0)


func _rysuj_plyte(punkty: PackedVector2Array, swiatlo: float, blysk_plyty: float = 0.0) -> void:
	var srodek := Vector2.ZERO
	for punkt in punkty:
		srodek += punkt
	srodek /= float(punkty.size())
	var obrys := punkty.duplicate()
	obrys.append(obrys[0])
	var metal := Color("#273848").lerp(Color("#526371"), swiatlo)
	draw_colored_polygon(punkty, Color("#0a111b"))
	var wnetrze := PackedVector2Array()
	for punkt in punkty:
		wnetrze.append(punkt.lerp(srodek, 0.16))
	draw_colored_polygon(wnetrze, metal.lerp(_energia_bossa(), blysk_plyty * 0.5 * _sila_wizualna()))
	draw_colored_polygon(PackedVector2Array([wnetrze[0],wnetrze[1],srodek]),Color("#647984",0.26))
	draw_colored_polygon(PackedVector2Array([wnetrze[wnetrze.size()-1],wnetrze[0],srodek]),Color("#050c15",0.3))
	draw_polyline(obrys, Color("#627684"), 1.0, true)
	var nit := punkty[1].lerp(srodek,0.3)
	draw_circle(nit,1.3,Color("#0a121a"))
	draw_circle(nit+Vector2(-0.3,-0.3),0.55,Color("#93a5ae"))
	draw_line(punkty[0], punkty[1], Color("#8b9ca6"), 1.2, true)


func _plyta_straznika(i: int, strona: float, odsuniecie: float = 0.0) -> PackedVector2Array:
	var y := -69.0 + float(i) * 47.0
	var wewnatrz := 11.0 + odsuniecie
	return PackedVector2Array([Vector2(strona * wewnatrz, y + 9.0), Vector2(strona * 25.0, y), Vector2(strona * 31.0, y + 9.0), Vector2(strona * 31.0, y + 37.0), Vector2(strona * 21.0, y + 44.0), Vector2(strona * wewnatrz, y + 33.0)])


func _rysuj_straznika() -> void:
	var sila := _sila_wizualna()
	var etap := etap_pancerza()
	var ladunek := _ladunek_ataku()
	var reakcja := clampf(blysk / 0.16, 0.0, 1.0) * sila
	var unoszenie := sin(czas_wizualny * 1.45) * 0.7 * sila
	draw_set_transform(Vector2(reakcja * 1.4, unoszenie), sin(czas_wizualny * 0.9) * 0.006 * sila)
	var szkielet := PackedVector2Array([Vector2(-23,-72), Vector2(23,-72), Vector2(31,-60), Vector2(31,59), Vector2(22,72), Vector2(-22,72), Vector2(-31,59), Vector2(-31,-60)])
	draw_colored_polygon(szkielet, Color("#0a121c"))
	draw_line(Vector2(-30,-59), Vector2(-30,59), Color("#465c6d"), 1.2, true)
	draw_line(Vector2(30,-59), Vector2(30,59), Color("#465c6d"), 1.2, true)
	for i in range(3):
		var y := -47.0 + float(i) * 47.0
		for strona in [-1.0, 1.0]:
			var zlamana: bool = (etap >= 2 and i == 0 and strona > 0.0) or (etap == 3 and i == 2 and strona < 0.0)
			var ruch := (0.6 + 0.5 * sin(czas_wizualny * 1.7 + i * 1.8 + strona)) * sila + ladunek * 2.4
			draw_line(Vector2(strona * 7.0,y - 9), Vector2(strona * 26.0,y + 3), Color("#76818a"), 3.0, true)
			draw_circle(Vector2(strona * 23.0,y + 1), 3.3, Color("#111d28"))
			draw_circle(Vector2(strona * 23.0,y + 1), 1.3, _energia_bossa().darkened(0.45))
			if not zlamana:
				var plyta := _plyta_straznika(i, strona, ruch)
				var lokalny := reakcja * clampf(1.0 - trafienie_lokalne.distance_to(Vector2(strona * 24,y)) / 55.0, 0.0, 1.0)
				_rysuj_plyte(plyta, 0.3 if strona < 0.0 else 0.05, lokalny)
				draw_line(Vector2(strona * (13.0+ruch),y-10), Vector2(strona * (13.0+ruch),y+8), Color(_energia_bossa(), 0.42 + ladunek * 0.45), 1.3, true)
				if etap > 0 and (i + int(strona)) % 2 != 0:
					_rysuj_pekniecie(Vector2(strona*22.0,y-10.0), Vector2(strona*3.0,1.0), etap)
			else:
				for j in range(3):
					draw_line(Vector2(strona*13,y-10+j*7), Vector2(strona*27,y-6+j*7), Color("#8c9ca7"), 1.5, true)
	_rysuj_plyte(PackedVector2Array([Vector2(-11,-69), Vector2(0,-72), Vector2(11,-69), Vector2(9,-36), Vector2(-9,-36)]), 0.25)
	_rysuj_plyte(PackedVector2Array([Vector2(-9,36), Vector2(9,36), Vector2(11,66), Vector2(0,72), Vector2(-11,66)]), 0.1)
	_rysuj_reaktor(Vector2.ZERO, 19.0, etap, ladunek)
	var odrzut := blysk_emitera / 0.15 * 2.5 * sila
	var emiter := PackedVector2Array([Vector2(-38+odrzut,-7),Vector2(-25,-11),Vector2(-20,-6),Vector2(-20,6),Vector2(-25,11),Vector2(-38+odrzut,7)])
	_rysuj_plyte(emiter, 0.1)
	draw_line(Vector2(-38+odrzut,-5),Vector2(-38+odrzut,5),Color(_energia_bossa(),0.65+ladunek*0.35),2.0,true)
	if ladunek > 0.0:
		draw_circle(Vector2(-39,0), 3.0 + ladunek * 3.0, Color(_energia_bossa(), 0.1 + ladunek * 0.4))
	draw_set_transform(Vector2.ZERO)


func _rysuj_pekniecie(punkt: Vector2, kierunek: Vector2, etap: int) -> void:
	var bok := kierunek.normalized().orthogonal()
	var os := kierunek.normalized()
	var pekniecie := PackedVector2Array([punkt, punkt+os*4.0+bok*2.0, punkt+os*8.0-bok, punkt+os*(11.0+etap*1.5)+bok*3.0])
	draw_polyline(pekniecie, Color("#080d15"), 3.2, true)
	draw_polyline(pekniecie, Color(_energia_bossa(), 0.65), 1.0, true)


func _rysuj_reaktor(srodek: Vector2, promien: float, etap: int, ladunek: float) -> void:
	var sila := _sila_wizualna()
	var tetno := (sin(czas_wizualny * (2.0 + etap * 1.3)) * 0.65 + sin(czas_wizualny * 7.1) * 0.35) * sila
	var energia := _energia_bossa().lerp(Color("#fff1c9"), ladunek * 0.6)
	draw_circle(srodek, promien, Color("#080f19"))
	draw_arc(srodek,promien,0,TAU,40,Color("#70808c"),2.0,true)
	for i in range(3):
		var kat := i * TAU / 3.0 + czas_wizualny * 0.4 * sila
		draw_arc(srodek,promien-3.0,kat,kat+0.8,12,Color(energia,0.7),1.7,true)
	var r := promien * (0.36 + etap * 0.045) + tetno * 0.7
	draw_circle(srodek, r + 5.0, Color(energia, (0.08 + ladunek * 0.15) * sila))
	draw_colored_polygon(PackedVector2Array([srodek+Vector2(0,-r),srodek+Vector2(r*0.8,-r*0.35),srodek+Vector2(r*0.8,r*0.4),srodek+Vector2(0,r),srodek+Vector2(-r*0.8,r*0.4),srodek+Vector2(-r*0.8,-r*0.35)]),energia)
	draw_line(srodek+Vector2(-2,-r*0.55),srodek+Vector2(-2,r*0.4),Color("#fff4d4"),1.5,true)
	if etap >= 2:
		_rysuj_pekniecie(srodek+Vector2(-promien*0.8,-4),Vector2(1,1),etap)


func _rysuj_iskry_trafienia() -> void:
	var sila := _sila_wizualna()
	var zycie := clampf(blysk / 0.16, 0.0, 1.0)
	var punkt := trafienie_lokalne
	if faza != null:
		for i in range(sat_blysk.size()):
			if sat_blysk[i] > 0.0:
				_rysuj_odpryski(sat_kolizje[i].position, clampf(sat_blysk[i]/0.16,0.0,1.0), sila)
	_rysuj_odpryski(punkt,zycie,sila)
	if etap_pancerza() == 3 and hp > 0:
		var iskra := pow(maxf(0.0, sin(czas_wizualny*5.3) * sin(czas_wizualny*8.1)), 5.0)
		_rysuj_odpryski(Vector2(-16,12),iskra,sila*0.55)
	for i in range(czasy_blyskow.size()):
		var alfa := czasy_blyskow[i] / 0.15 * sila
		var miejsce := miejsca_blyskow[i] - position
		draw_circle(miejsce,5.0+alfa*4.0,Color(_energia_bossa(),alfa*0.65))
		draw_line(miejsce,miejsce+kierunki_blyskow[i]*13.0,Color("#fff5d4",alfa),2.5,true)


func _rysuj_odpryski(punkt: Vector2, zycie: float, sila: float) -> void:
	if zycie <= 0.0 or sila <= 0.0:
		return
	for i in range(5):
		var os := Vector2.RIGHT.rotated(i*2.4+0.4)
		var p := punkt + os*(3.0+(1.0-zycie)*22.0)
		draw_line(p,p+os*4.0,Color(_energia_bossa(),zycie*sila),1.5,true)
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([p,p+os*4.0,p+os.orthogonal()*2.0]),Color("#a3b5bd",zycie*sila))


func _rysuj_rozpad() -> void:
	var t := clampf(rozpad / 0.5, 0.0, 1.0)
	var sila := _sila_wizualna()
	var energia := _energia_bossa()
	var odrywanie := clampf((t-0.16)/0.65,0.0,1.0)
	var zanikanie := 1.0-clampf((t-0.6)/0.4,0.0,1.0)
	if t < 0.28:
		if faza == null:
			_rysuj_straznika()
		else:
			_rysuj_reaktor(Vector2.ZERO,28.0,3,1.0)
	for i in range(6):
		var kat := float(i)*TAU/6.0
		var os := Vector2.RIGHT.rotated(kat)
		var poczatek := Vector2((1.0 if i%2==0 else -1.0)*22.0,-47.0+floorf(float(i)/2.0)*47.0) if faza == null else os*24.0
		var p := poczatek + os*odrywanie*54.0*sila
		draw_set_transform(p,odrywanie*1.4*(1.0 if i%2==0 else -1.0))
		var plyta := PackedVector2Array([Vector2(-10,-14),Vector2(6,-17),Vector2(11,-6),Vector2(8,13),Vector2(-7,15)])
		if faza == null:
			plyta = _plyta_straznika(floori(float(i)/2.0),1.0 if i%2==0 else -1.0)
			for j in range(plyta.size()):
				plyta[j] -= poczatek
		draw_colored_polygon(plyta,Color("#354959",zanikanie))
		draw_polyline(PackedVector2Array([plyta[0],plyta[1],plyta[2]]),Color(energia,zanikanie*0.7),1.5,true)
	draw_set_transform(Vector2.ZERO)
	if faza != null:
		for sat in sat_kolizje:
			var p := sat.position*(1.0+odrywanie*0.25*sila)
			draw_arc(p,16.0,odrywanie,odrywanie+PI*1.5,20,Color("#9bb5c1",zanikanie),3.0,true)
	var blysk_rdzenia := sin(clampf((t-0.3)/0.5,0.0,1.0)*PI)
	draw_circle(Vector2.ZERO, 10.0+blysk_rdzenia*18.0*sila,Color(energia,zanikanie*(0.3+blysk_rdzenia*0.7)))
	draw_circle(Vector2.ZERO, 6.0+blysk_rdzenia*9.0,Color("#fff7e0",blysk_rdzenia*sila))
	if t > 0.55:
		var wybuch := (t-0.55)/0.45
		for i in range(18):
			var os := Vector2.RIGHT.rotated(i*2.4)
			var p := os*(12.0+wybuch*70.0)
			draw_line(p,p+os*(7.0*(1.0-wybuch)),Color(energia,(1.0-wybuch)*sila),1.8,true)


func _rysuj_pociski_i_ostrzezenie() -> void:
	var paleta := PaletaPrzeciwnikow.pobierz(self)
	if ostrzezenie > 0.0:
		var srodek_x: float = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5
		draw_circle(Vector2.ZERO, ROZMIAR.x, Color(paleta.zagrozenie, 0.07 * _sila_wizualna()))
		for i in range(zaplanowane_starty.size()):
			var start := zaplanowane_starty[i]
			var wektor := zaplanowane_kierunki[i]
			var dlugosc := maxf(0.0, (start.x - srodek_x) / maxf(0.01, -wektor.x))
			if faza != null:
				dlugosc = 2000.0
				if absf(wektor.x) > 0.001:
					var granica_x: float = Ustawienia.prawa_granica if wektor.x > 0.0 else Ustawienia.lewa_granica
					dlugosc = minf(dlugosc, maxf(0.0, (granica_x - start.x) / wektor.x))
				if absf(wektor.y) > 0.001:
					var granica_y: float = Ustawienia.dolna_granica if wektor.y > 0.0 else Ustawienia.gorna_granica
					dlugosc = minf(dlugosc, maxf(0.0, (granica_y - start.y) / wektor.y))
			draw_line(start - position, start + wektor * dlugosc - position, Color(paleta.zagrozenie, 0.38), 1.5, true)
	for pocisk in pociski:
		draw_circle(pocisk - position, PROMIEN_POCISKU + 5.0, Color(paleta.zagrozenie, 0.14))
		draw_circle(pocisk - position, PROMIEN_POCISKU, paleta.pancerz)
		draw_circle(pocisk - position, PROMIEN_POCISKU * 0.62, paleta.zagrozenie)
		draw_circle(pocisk - position + Vector2(-2.0, -2.0), 2.0, Color(paleta.swiatlo, 0.85))


func _przygotuj_rdzen() -> void:
	faza = definicja.faza_rdzenia(bossIndex)
	var ksztalt := CircleShape2D.new()
	ksztalt.radius = 30.0
	kolizja.shape = ksztalt
	var liczba := maxi(faza.sat_count, DIFFICULTY.SAT_COUNT_LATE if bossIndex >= 3 else DIFFICULTY.SAT_COUNT)
	for i in range(liczba):
		var sat := CollisionShape2D.new()
		var okrag := CircleShape2D.new()
		okrag.radius = DIFFICULTY.SAT_RADIUS
		sat.shape = okrag
		add_child(sat)
		sat_kolizje.append(sat)
		sat_hp.append(mini(DIFFICULTY.SAT_HP, DIFFICULTY.SAT_HP_CAP))
		sat_blysk.append(0.0)
		sat_cooldown.append(0.0)
		sat_narodziny.append(0.0)
	_ustaw_orbite()


func _zywe_satelity() -> int:
	var liczba: int = 0
	for zdrowie in sat_hp:
		if zdrowie > 0:
			liczba += 1
	return liczba


func _traf_satellite(kontakt: Trafienie) -> void:
	var i := kontakt.satelita
	if not kontakt.zewnetrzny_luk or sat_hp[i] <= 0 or sat_cooldown[i] > 0.0:
		return
	sat_hp[i] = maxi(0, sat_hp[i] - kontakt.obrazenia)
	sat_cooldown[i] = 0.10
	sat_blysk[i] = 0.45 if sat_hp[i] == 0 else 0.16
	if sat_hp[i] == 0:
		sat_kolizje[i].set_deferred("disabled", true)
		if ostrzezenie > 0.0:
			_anuluj_zapowiedz_rdzenia()
		satelita_zniszczony.emit()
		if _zywe_satelity() == 0 and not regeneruje:
			_odslon_rdzen()


func _odslon_rdzen() -> void:
	odsloniecie = DIFFICULTY.EXPOSE_MS / 1000.0
	nowe_odsloniecie = true
	_anuluj_zapowiedz_rdzenia()
	indeks_fazy = 0


func _anuluj_zapowiedz_rdzenia() -> void:
	ostrzezenie = 0.0
	seria_pozostalo = 0
	zaplanowane_starty.clear()
	zaplanowane_kierunki.clear()
	czas_ataku = trudnosc.cooldown_ms / 1000.0


func _ustaw_orbite() -> void:
	for i in range(sat_kolizje.size()):
		var promien := DIFFICULTY.ORBIT_INNER_RADIUS if faza.warstwy and i % 2 == 0 else DIFFICULTY.ORBIT_RADIUS
		var kat := orbita + TAU * float(i) / float(sat_kolizje.size())
		sat_kolizje[i].position = Vector2.RIGHT.rotated(kat) * promien


func _aktualizuj_rdzen(delta: float) -> void:
	czas_rdzenia += delta
	osloniety_blysk = maxf(0.0, osloniety_blysk - delta)
	for i in range(sat_hp.size()):
		sat_blysk[i] = maxf(0.0, sat_blysk[i] - delta)
		sat_cooldown[i] = maxf(0.0, sat_cooldown[i] - delta)
		sat_narodziny[i] = maxf(0.0, sat_narodziny[i] - delta)
	if ostrzezenie <= 0.0:
		position.y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5 + sin(czas_rdzenia * 0.3) * definicja.speed
		orbita += kierunek_orbity * DIFFICULTY.ORBIT_SPEED * delta
		_ustaw_orbite()
	if faza.odwrocenie_ms > 0.0:
		czas_odwrocenia += delta
		if czas_odwrocenia >= faza.odwrocenie_ms / 1000.0:
			czas_odwrocenia = 0.0
			kierunek_orbity *= -1.0
	if odsloniecie > 0.0:
		if nowe_odsloniecie:
			nowe_odsloniecie = false
		else:
			odsloniecie = maxf(0.0, odsloniecie - delta)
		if odsloniecie == 0.0:
			regeneruje = true
			regen_indeks = 0
			regeneracja = 0.0
			_anuluj_zapowiedz_rdzenia()
	elif regeneruje:
		regeneracja -= delta
		if regeneracja <= 0.0:
			sat_hp[regen_indeks] = mini(DIFFICULTY.SAT_HP, DIFFICULTY.SAT_HP_CAP)
			sat_kolizje[regen_indeks].set_deferred("disabled", false)
			sat_blysk[regen_indeks] = 0.16
			sat_narodziny[regen_indeks] = 0.6
			regen_indeks += 1
			regeneracja = DIFFICULTY.REGEN_SAT_MS / 1000.0
			if regen_indeks == sat_hp.size():
				regeneruje = false


func _zapowiedz_rdzen() -> void:
	puls = _zywe_satelity() == 0 and not regeneruje
	var wzory: Array[BossDefinicja.Atak] = faza.odsloniety if puls else faza.osloniety
	atak = wzory[indeks_fazy % wzory.size()]
	indeks_fazy += 1
	ostrzezenie = maxf(trudnosc.telegraph_ms, atak.telegraph_ms) / 1000.0
	zaplanowane_starty.clear()
	zaplanowane_kierunki.clear()
	cel_ataku = paletka.position
	if puls:
		numer_pulsu += 1
		var luka := (cel_ataku - position).angle()
		if faza.przesuwana_luka:
			luka += sin(float(numer_pulsu) * 1.7) * 0.36
		luka_pulsu = luka
		for i in range(DIFFICULTY.PULSE_COUNT):
			var kat := TAU * float(i) / float(DIFFICULTY.PULSE_COUNT)
			if absf(angle_difference(kat, luka)) < DIFFICULTY.PULSE_GAP * 0.5:
				continue
			var wektor := Vector2.RIGHT.rotated(kat)
			zaplanowane_starty.append(position + wektor * 36.0)
			zaplanowane_kierunki.append(wektor)
	else:
		var pozostalo := 2 if atak.wzor == BossDefinicja.Wzor.SATELITY_PARA else 1
		for krok in range(sat_hp.size()):
			var i := (sat_strzelec + krok) % sat_hp.size()
			if sat_hp[i] <= 0:
				continue
			var start := position + sat_kolizje[i].position
			zaplanowane_starty.append(start)
			zaplanowane_kierunki.append((cel_ataku - start).normalized())
			pozostalo -= 1
			if pozostalo == 0:
				sat_strzelec = (i + 1) % sat_hp.size()
				break


func _rysuj_rdzen(hud: Vector2) -> void:
	var paleta := PaletaPrzeciwnikow.pobierz(self)
	var osloniety := _zywe_satelity() > 0 or regeneruje
	var kolor := paleta.rdzen if osloniety else paleta.zagrozenie
	var ladunek := 0.0
	if ostrzezenie > 0.0 and atak != null:
		ladunek = clampf(1.0 - ostrzezenie / (maxf(trudnosc.telegraph_ms, atak.telegraph_ms) / 1000.0), 0.0, 1.0)
		kolor = kolor.lerp(paleta.zagrozenie, ladunek * 0.7)
	kolor = kolor.lerp(paleta.swiatlo, clampf(blysk / 0.16, 0.0, 1.0))
	var tetno := 0.5 + sin(czas_wizualny * (3.0 if osloniety else 6.0)) * 0.5 * _sila_wizualna()
	var etap := etap_pancerza()
	var sila := _sila_wizualna()
	for i in range(6):
		var kat := i * TAU / 6.0
		var os := Vector2.RIGHT.rotated(kat)
		var bok := os.orthogonal()
		var brak := (etap >= 2 and i == 1) or (etap == 3 and i == 4)
		if not brak:
			var wychylenie := sin(czas_wizualny*1.4+i)*0.7*sila + ladunek*1.5
			var plyta := PackedVector2Array([os*(21.0+wychylenie)-bok*6.0,os*29.0-bok*8.0,os*30.0+bok*6.0,os*22.0+bok*7.0])
			_rysuj_plyte(plyta,0.15,clampf(blysk/0.16,0.0,1.0))
			if etap > 0 and i % 2 == 0:
				_rysuj_pekniecie(os*24.0-bok*4.0,bok,etap)
		else:
			draw_line(os*16.0,os*29.0,Color("#718a9a"),2.5,true)
	_rysuj_reaktor(Vector2.ZERO,18.0,etap,ladunek)
	if osloniety:
		for i in range(6):
			var kat := czas_wizualny * 0.35 * sila + i * TAU / 6.0
			draw_arc(Vector2.ZERO, 40.0, kat, kat + 0.78, 12, Color(paleta.rdzen.lerp(paleta.pekniecie, clampf(osloniety_blysk / 0.16, 0.0, 1.0)), 0.65), 2.5, true)
	elif odsloniecie > 0.0:
		var pozostalo := odsloniecie / (DIFFICULTY.EXPOSE_MS / 1000.0)
		var alarm := 0.45 + tetno * 0.5 if odsloniecie <= 3.0 else 0.7
		draw_arc(Vector2.ZERO, 43.0, -PI * 0.5, -PI * 0.5 + TAU * pozostalo, 72, Color(paleta.zagrozenie, alarm), 3.0, true)
		if odsloniecie <= 3.0:
			draw_arc(Vector2.ZERO, 48.0, 0.0, TAU, 64, Color(paleta.rdzen, tetno * 0.35), 1.0, true)
	if puls and ostrzezenie > 0.0:
		draw_arc(Vector2.ZERO, 52.0, luka_pulsu - DIFFICULTY.PULSE_GAP * 0.5, luka_pulsu + DIFFICULTY.PULSE_GAP * 0.5, 20, paleta.swiatlo, 3.0, true)
	if intro > 0.0:
		draw_arc(Vector2.ZERO, 36.0 + intro * 32.0, -czas_wizualny * 2.0, TAU - czas_wizualny * 2.0, 64, Color(paleta.rdzen, (1.0 - intro / 1.2) * sila), 2.0, true)
	for i in range(sat_hp.size()):
		var lokalna := sat_kolizje[i].position
		var pip := hud + Vector2((float(i) - float(sat_hp.size() - 1) * 0.5) * 22.0, 28.0)
		draw_circle(pip, 5.0, Color(paleta.rdzen, 0.15))
		if sat_hp[i] > 0:
			draw_arc(pip, 5.0, -PI * 0.5, -PI * 0.5 + TAU * float(sat_hp[i]) / float(mini(DIFFICULTY.SAT_HP, DIFFICULTY.SAT_HP_CAP)), 24, kolor, 2.0, true)
			var os := lokalna.normalized()
			var bok := os.orthogonal()
			var oslona := PackedVector2Array([lokalna+os*17.0-bok*5.0,lokalna+os*9.0-bok*15.0,lokalna-os*11.0-bok*9.0,lokalna-os*16.0,lokalna-os*11.0+bok*9.0,lokalna+os*9.0+bok*15.0,lokalna+os*17.0+bok*5.0])
			_rysuj_plyte(oslona,0.15,clampf(sat_blysk[i]/0.16,0.0,1.0))
			if sat_hp[i] < mini(DIFFICULTY.SAT_HP, DIFFICULTY.SAT_HP_CAP):
				_rysuj_pekniecie(lokalna-bok*8.0,os,2)
			var laduj := 0.0
			if ostrzezenie > 0.0:
				for start in zaplanowane_starty:
					if start.distance_to(position+lokalna) < 2.0:
						laduj = ladunek
			draw_circle(lokalna,8.0,Color("#0b1521"))
			draw_circle(lokalna,3.5+laduj*2.5,Color("#73eff0").lerp(paleta.zagrozenie,laduj))

			var kat := lokalna.angle()
			draw_arc(lokalna, DIFFICULTY.SAT_RADIUS + 3.0, kat - PI * 0.5, kat + PI * 0.5, 24, paleta.rdzen, 2.0, true)
			var narodziny := maxf(sat_narodziny[i], intro * 0.5)
			if narodziny > 0.0:
				draw_arc(lokalna, DIFFICULTY.SAT_RADIUS + narodziny * 30.0, 0.0, TAU, 40, Color(paleta.swiatlo, (1.0 - narodziny / 0.65) * 0.7 * sila), 2.0, true)
		elif sat_blysk[i] > 0.0:
			for j in range(6):
				var wektor := Vector2.RIGHT.rotated(TAU * float(j) / 6.0)
				var dystans := 18.0 + (0.45 - sat_blysk[i]) * 90.0
				draw_line(lokalna + wektor * dystans, lokalna + wektor * (dystans + 9.0), Color(paleta.pekniecie, sat_blysk[i] / 0.45 * sila), 2.0, true)
		elif regeneruje and i == regen_indeks:
			var postep := clampf(1.0 - regeneracja / (DIFFICULTY.REGEN_SAT_MS / 1000.0), 0.0, 1.0)
			draw_arc(lokalna, DIFFICULTY.SAT_RADIUS, 0.0, TAU, 32, Color(paleta.rdzen, 0.16), 1.0, true)
			if postep > 0.0:
				draw_arc(lokalna, DIFFICULTY.SAT_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * postep, 32, Color(paleta.rdzen, 0.7), 2.0, true)
