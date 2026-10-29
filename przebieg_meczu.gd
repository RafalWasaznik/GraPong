class_name PrzebiegMeczu
extends Node

const SZEROKOSC_INFO_ENDLESS = 760.0
const CZCIONKA_ENDLESS = preload("res://assets/fonts/Oxanium.ttf")
const KOLOR_TURKUS_ENDLESS = Color("#55e7ff")
const KOLOR_FIOLET_ENDLESS = Color("#ad83ff")

var gra: GraPongAPI
var wynik_gracza = 0
var wynik_ai = 0
var czas_meczu = 0.0
var stat_odbicia_gracza = 0
var stat_odbicia_rywala = 0
var stat_mocne_odbicia_gracza = 0
var stat_mocne_odbicia_rywala = 0
var biezaca_wymiana = 0
var najdluzsza_wymiana = 0
var endless_odbicia = 0
var wybor_oczekuje: bool = false
var wybory_w_kolejce: int = 0
var indeks_progu_ulepszenia: int = 0
const DIFFICULTY = TrudnoscRun.DIFFICULTY

var czas_do_krysztalu: float = DIFFICULTY.SPAWN_BASE_MS / 1000.0
var interwal_krysztalow: float = DIFFICULTY.SPAWN_BASE_MS
var czas_krysztalow: float = 0.0
var zniszczenia_krysztalow: Array[float] = []
var wygasniecia_krysztalow: Array[float] = []
var krysztaly: Array[KrysztalRun] = []
var kolejka_wybuchow_krysztalow: Array[KrysztalRun] = []
var rozstrzyganie_wybuchow_krysztalow: bool = false
var boss: BossRun
var nagroda_bossa: bool = false
var boss_oczekuje: bool = false
var nagroda_bossa_otwarta: bool = false
var obrazenia_bossa: Array[BossRun.Trafienie] = []
var trafienia_pociskow: Array[Vector2] = []
var trafienia_dronow: Array[Vector2] = []
var strata_pilki_bossa: bool = false
var rozpad_bossa_zakonczony: bool = false
var run_state: RunState
var rejestr_ulepszen: Array[UlepszenieRun] = UlepszenieRun.katalog()
var wybor_ulepszenia: WyborUlepszenia
var endless_wysokosc_startowa = 120.0
var mecz_zakonczony = false
var endless_info: HBoxContainer
var endless_wartosci: Array[Label] = []
var endless_krysztaly: Label


func uruchom(gra_glowna: GraPongAPI) -> void:
	gra = gra_glowna
	if Ustawienia.tryb == "endless":
		var ksztalt_paletki = gra.lewa_paletka().kolizja.shape as RectangleShape2D
		if ksztalt_paletki != null:
			endless_wysokosc_startowa = ksztalt_paletki.size.y
		process_physics_priority = 100
		run_state = RunState.new()
		gra.lewa_paletka().collision_layer |= PociskDronaRun.WARSTWA_GRACZA
		gra.pilka().run_state = run_state
		gra.lewa_paletka().run_state = run_state
		wybor_ulepszenia = WyborUlepszenia.new()
		gra.add_child(wybor_ulepszenia)
		wybor_ulepszenia.wybrano.connect(_zastosuj_stan_endless)
		wybor_ulepszenia.dzwiek_wyboru.connect(gra.odtworz_dzwiek_bonusu)
		_zastosuj_stan_endless()


func _physics_process(delta: float) -> void:
	if run_state != null and not mecz_zakonczony:
		run_state.aktualizuj_czas(delta)
		_rozstrzygnij_zdarzenia_bossa()
		if run_state == null or mecz_zakonczony or run_state.boss_aktywny or get_tree().paused:
			return
		_kolejkuj_wybory_endless()
		_sprawdz_prog_bossa()
		if run_state.boss_aktywny:
			return
		czas_krysztalow += delta
		czas_do_krysztalu -= delta
		if czas_do_krysztalu <= 0.0:
			czas_do_krysztalu = interwal_krysztalow / 1000.0
			_spawn_krysztalu.call_deferred()


func _process(delta: float) -> void:
	if not mecz_zakonczony:
		czas_meczu += delta
		if Ustawienia.tryb == "endless" and is_instance_valid(endless_info):
			_odswiez_info_endless()


func zarejestruj_odbicie(strona: String, mocne: bool) -> void:
	if strona == "gracz":
		stat_odbicia_gracza += 1
		if mocne:
			stat_mocne_odbicia_gracza += 1
	else:
		stat_odbicia_rywala += 1
		if mocne:
			stat_mocne_odbicia_rywala += 1
	biezaca_wymiana += 1
	najdluzsza_wymiana = maxi(najdluzsza_wymiana, biezaca_wymiana)


func ustaw_stan_zdalny(stan: StanMeczuOnline) -> void:
	wynik_gracza = stan.wynik_gracza
	wynik_ai = stan.wynik_ai
	czas_meczu = stan.czas_meczu
	stat_odbicia_gracza = stan.stat_odbicia_gracza
	stat_odbicia_rywala = stan.stat_odbicia_rywala
	stat_mocne_odbicia_gracza = stan.stat_mocne_odbicia_gracza
	stat_mocne_odbicia_rywala = stan.stat_mocne_odbicia_rywala
	biezaca_wymiana = stan.biezaca_wymiana
	najdluzsza_wymiana = stan.najdluzsza_wymiana


func _on_punkt(strona: String) -> void:
	if mecz_zakonczony:
		return
	if run_state != null:
		kolejkuj_strate_pilki_bossa()
		return
	gra.zresetuj_rozpad_punktu()
	gra.lewa_paletka().reset_po_punkcie()
	gra.prawa_paletka().reset_po_punkcie()

	gra.odtworz_dzwiek_punktu()
	biezaca_wymiana = 0
	if strona == "lewa":
		wynik_ai += 1
	else:
		wynik_gracza += 1

	gra.ustaw_wyniki(wynik_gracza, wynik_ai)
	if Ustawienia.tryb != "online":
		(gra.bonusy()).wyczysc_po_punkcie()
	var arena_manager := gra.menedzer_areny()
	if arena_manager != null:
		arena_manager.po_zdobyciu_punktu()
	gra.odswiez_rysowanie()

	var pilka_glowna := gra.pilka()
	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka != pilka_glowna:
			pilka.queue_free()

	var z_botem = Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy)
	if Ustawienia.tryb == "online" and Siec.warunek_meczu == "czas":
		gra.lewa_paletka().set_physics_process(true)
		gra.prawa_paletka().set_physics_process(true)
		pilka_glowna.set_physics_process(true)
		pilka_glowna.reset()
	elif Ustawienia.tryb == "online" and wynik_gracza >= Siec.limit_punktow_meczu:
		zakoncz_mecz("Wygrywa %s!" % Siec.nazwa_gracza_1)
	elif Ustawienia.tryb == "online" and wynik_ai >= Siec.limit_punktow_meczu:
		zakoncz_mecz("Wygrywa %s!" % Siec.nazwa_gracza_2)
	elif wynik_gracza >= Ustawienia.limit_punktow:
		zakoncz_mecz("Wygrałeś!" if z_botem else "Wygrywa gracz 1!")
	elif wynik_ai >= Ustawienia.limit_punktow:
		zakoncz_mecz("Przegrałeś!" if z_botem else "Wygrywa gracz 2!")
	else:
		gra.lewa_paletka().set_physics_process(true)
		gra.prawa_paletka().set_physics_process(true)
		pilka_glowna.set_physics_process(true)
		pilka_glowna.reset()


func zarejestruj_odbicie_endless(idealne: bool) -> void:
	if Ustawienia.tryb != "endless" or mecz_zakonczony or run_state == null:
		return
	run_state.zarejestruj_odbicie(idealne)
	if not run_state.boss_aktywny:
		_kolejkuj_wybory_endless()
		_sprawdz_prog_bossa()
	endless_odbicia = run_state.hits
	wynik_gracza = floori(run_state.score)
	wynik_ai = run_state.lives
	gra.ustaw_wyniki(wynik_gracza, run_state.lives)
	_kolejkuj_wybory_endless()
	_odswiez_info_endless()


func _sprawdz_prog_bossa() -> void:
	if run_state.boss_aktywny or nagroda_bossa or floori(run_state.score) < run_state.nextBossScore:
		return
	run_state.boss_aktywny = true
	boss_oczekuje = true
	for krysztal in krysztaly:
		if is_instance_valid(krysztal):
			run_state.dodaj_punkty(krysztal.nagroda_bazowa() * run_state.targetRewardMult * krysztal.rozlicz_przed_bossem())
	krysztaly.clear()
	_wyczysc_pociski_dronow()
	gra.pilka().set_physics_process(false)


func _kolejkuj_wybory_endless() -> void:
	if run_state.boss_aktywny or nagroda_bossa:
		return
	while floori(run_state.score) >= _prog_ulepszenia(indeks_progu_ulepszenia):
		wybory_w_kolejce += 1
		indeks_progu_ulepszenia += 1
	if wybory_w_kolejce > 0 and not wybor_oczekuje and not run_state.wybor_aktywny and not get_tree().paused:
		wybor_oczekuje = true
		_pokaz_wybor_endless.call_deferred()


func _prog_ulepszenia(indeks: int) -> int:
	if indeks < RunState.UPGRADE_POINT_THRESHOLDS.size():
		return RunState.UPGRADE_POINT_THRESHOLDS[indeks]
	return RunState.UPGRADE_POINT_THRESHOLDS[-1] + (indeks - RunState.UPGRADE_POINT_THRESHOLDS.size() + 1) * RunState.UPGRADE_EVERY_POINTS


func _pokaz_wybor_endless() -> void:
	wybor_oczekuje = false
	if mecz_zakonczony or run_state == null or (run_state.boss_aktywny and not boss_oczekuje and not nagroda_bossa) or run_state.wybor_aktywny or get_tree().paused or (wybory_w_kolejce <= 0 and not nagroda_bossa):
		return
	var oferty := UlepszenieRun.losuj(run_state, rejestr_ulepszen, nagroda_bossa)
	if not oferty.is_empty():
		if nagroda_bossa:
			nagroda_bossa_otwarta = true
		else:
			wybory_w_kolejce -= 1
		wybor_ulepszenia.pokaz(run_state, oferty)
	else:
		wybory_w_kolejce = 0
		if nagroda_bossa:
			nagroda_bossa_otwarta = true


func _dostosuj_spawn(trudnosc: TrudnoscRun) -> void:
	for historia in [zniszczenia_krysztalow, wygasniecia_krysztalow]:
		while not historia.is_empty() and historia[0] < czas_krysztalow - DIFFICULTY.RATE_WINDOW:
			historia.pop_front()
	var bazowy := clampf(DIFFICULTY.SPAWN_BASE_MS / (run_state.targetSpawnRateMult * trudnosc.target_spawn_rate_mult), DIFFICULTY.SPAWN_MIN_MS, DIFFICULTY.SPAWN_MAX_MS)
	var okno := minf(DIFFICULTY.RATE_WINDOW, czas_krysztalow)
	var tempo := float(zniszczenia_krysztalow.size()) / maxf(1.0, okno)
	var zdolnosc := maxf(DIFFICULTY.CAPACITY_FLOOR, float(run_state.ballDamage) / trudnosc.crystal_hp)
	var cel := bazowy / zdolnosc
	if tempo > 0.0:
		cel = lerpf(cel, 1000.0 / tempo, DIFFICULTY.ADAPT_SMOOTH)
	if tempo > 1000.0 / interwal_krysztalow:
		cel = minf(cel, interwal_krysztalow * (1.0 - DIFFICULTY.ADAPT_STEP))
	if not wygasniecia_krysztalow.is_empty():
		cel = maxf(cel, interwal_krysztalow * (1.0 + DIFFICULTY.ADAPT_STEP))
	cel = clampf(cel, DIFFICULTY.SPAWN_MIN_MS, DIFFICULTY.SPAWN_MAX_MS)
	interwal_krysztalow = clampf(lerpf(interwal_krysztalow, cel, DIFFICULTY.ADAPT_SMOOTH), interwal_krysztalow * (1.0 - DIFFICULTY.ADAPT_STEP), interwal_krysztalow * (1.0 + DIFFICULTY.ADAPT_STEP))
	interwal_krysztalow = clampf(interwal_krysztalow, DIFFICULTY.SPAWN_MIN_MS, DIFFICULTY.SPAWN_MAX_MS)


func _krysztal_wygasl() -> void:
	wygasniecia_krysztalow.append(czas_krysztalow)


func _spawn_krysztalu() -> void:
	if run_state == null or mecz_zakonczony or run_state.boss_aktywny or get_tree().paused:
		return
	for i in range(krysztaly.size() - 1, -1, -1):
		if not is_instance_valid(krysztaly[i]) or krysztaly[i].is_queued_for_deletion() or krysztaly[i].rozpad:
			krysztaly.remove_at(i)
	var trudnosc := TrudnoscRun.getDifficulty(floori(run_state.score), run_state.bossIndex)
	_dostosuj_spawn(trudnosc)
	czas_do_krysztalu = interwal_krysztalow / 1000.0
	if krysztaly.size() >= trudnosc.crystal_limit:
		return
	var promien := KrysztalRun.PROMIEN
	var minimum := Vector2(gra.lewa_paletka().position.x + DIFFICULTY.FIELD_LEFT_MARGIN + promien, Ustawienia.gorna_granica + DIFFICULTY.FIELD_TOP_MARGIN + promien)
	var maksimum := Vector2(Ustawienia.prawa_granica - DIFFICULTY.FIELD_RIGHT_MARGIN - promien, Ustawienia.dolna_granica - DIFFICULTY.FIELD_BOTTOM_MARGIN - promien)
	if maksimum.x <= minimum.x or maksimum.y <= minimum.y:
		return
	var warianty: Array[KrysztalRun.Wariant] = []
	var offsety: Array[Vector2] = []
	var uklad: int = trudnosc.layouts.pick_random()
	var odstep := DIFFICULTY.LAYOUT_SPACING
	match uklad:
		1:
			warianty = [KrysztalRun.CRYSTAL_VARIANTS[1], KrysztalRun.losuj_wariant(trudnosc)]
			offsety = [Vector2.ZERO, Vector2(0.0, odstep)]
		2:
			warianty = [KrysztalRun.losuj_wariant(trudnosc), KrysztalRun.CRYSTAL_VARIANTS[2], KrysztalRun.CRYSTAL_VARIANTS[1]]
			offsety = [Vector2.ZERO, Vector2(odstep, odstep), Vector2(0.0, odstep * 2.0)]
		3:
			warianty = [KrysztalRun.CRYSTAL_VARIANTS[3], KrysztalRun.CRYSTAL_VARIANTS[2]]
			offsety = [Vector2.ZERO, Vector2(odstep, 0.0)]
		_:
			warianty = [KrysztalRun.losuj_wariant(trudnosc)]
			offsety = [Vector2.ZERO]
	var wolne_miejsca := trudnosc.crystal_limit - krysztaly.size()
	warianty.resize(mini(warianty.size(), wolne_miejsca))
	for proba in range(DIFFICULTY.SPAWN_ATTEMPTS):
		var kotwica := Vector2(randf_range(minimum.x, maksimum.x), randf_range(minimum.y, maksimum.y))
		var poczatki: Array[Vector2] = []
		var konce: Array[Vector2] = []
		var obszary: Array[Rect2] = []
		var wolne := true
		for i in range(warianty.size()):
			var miejsce := kotwica + offsety[i]
			var polowa_toru := Vector2.DOWN * warianty[i].params.track_length * 0.5
			var poczatek := miejsce - polowa_toru
			var koniec := miejsce + polowa_toru
			if poczatek.x < minimum.x or koniec.x > maksimum.x or poczatek.y < minimum.y or koniec.y > maksimum.y:
				wolne = false
			var obszar := Rect2(poczatek, koniec - poczatek).abs().grow(promien + DIFFICULTY.TRACK_PADDING)
			for krysztal in krysztaly:
				if obszar.intersects(krysztal.obszar_toru()):
					wolne = false
			for zajety in obszary:
				if obszar.intersects(zajety):
					wolne = false
			var pilka := gra.pilka()
			if pilka.intro_aktywne and Geometry2D.get_closest_point_to_segment(pilka.srodek_intro, poczatek, koniec).distance_to(pilka.srodek_intro) < Pilka.PROMIEN_OKREGU + promien + DIFFICULTY.TRACK_PADDING:
				wolne = false
			if Geometry2D.get_closest_point_to_segment(pilka.position, poczatek, koniec).distance_to(pilka.position) < promien + pilka.promien_aktualny() + DIFFICULTY.BALL_MARGIN:
				wolne = false
			poczatki.append(poczatek)
			konce.append(koniec)
			obszary.append(obszar)
		if not wolne:
			continue
		for i in range(warianty.size()):
			var nowy: KrysztalRun
			if DronRun.czy_zastapic(_liczba_dronow()):
				var dron := DronRun.new()
				dron.paletka = gra.lewa_paletka()
				dron.wystrzelono.connect(_podlacz_pocisk_drona)
				nowy = dron
				var srodek := poczatki[i].lerp(konce[i], 0.5)
				nowy.skonfiguruj(KrysztalRun.CRYSTAL_VARIANTS[0], run_state, srodek, srodek)
			else:
				nowy = KrysztalRun.new()
				nowy.skonfiguruj(warianty[i], run_state, poczatki[i], konce[i])
			nowy.zniszczony.connect(_zniszczono_krysztal.bind(nowy))
			nowy.wygasl_nietkniety.connect(_krysztal_wygasl)
			nowy.pancerz_pekl.connect(gra.odtworz_dzwiek_modyfikatora)
			gra.add_child(nowy)
			krysztaly.append(nowy)
		return


func _zniszczono_krysztal(zrodlo: KrysztalRun) -> void:
	if run_state == null or mecz_zakonczony or run_state.boss_aktywny:
		return
	zniszczenia_krysztalow.append(czas_krysztalow)
	run_state.dodaj_punkty(zrodlo.nagroda_bazowa() * run_state.targetRewardMult)
	if zrodlo.wybuch_zniszczenia:
		kolejka_wybuchow_krysztalow.append(zrodlo)
	if rozstrzyganie_wybuchow_krysztalow:
		return
	rozstrzyganie_wybuchow_krysztalow = true
	for krok in range(KrysztalRun.MAX_CHAIN_STEPS):
		if kolejka_wybuchow_krysztalow.is_empty():
			break
		var fala: Array[KrysztalRun] = kolejka_wybuchow_krysztalow.duplicate()
		kolejka_wybuchow_krysztalow.clear()
		for wybuch in fala:
			for krysztal in krysztaly:
				if not is_instance_valid(krysztal) or krysztal.rozpad or krysztal.is_queued_for_deletion():
					continue
				if wybuch.position.distance_to(krysztal.position) <= wybuch.wariant.params.burst_radius:
					krysztal.trafienie(1, false)
	kolejka_wybuchow_krysztalow.clear()
	rozstrzyganie_wybuchow_krysztalow = false
	wynik_gracza = floori(run_state.score)
	gra.ustaw_wyniki(wynik_gracza, run_state.lives)
	_kolejkuj_wybory_endless()
	_odswiez_info_endless()


func _liczba_dronow() -> int:
	var liczba := 0
	for cel in krysztaly:
		if is_instance_valid(cel) and cel is DronRun and not cel.rozpad and not cel.is_queued_for_deletion():
			liczba += 1
	return liczba


func _podlacz_pocisk_drona(pocisk: PociskDronaRun) -> void:
	pocisk.trafiono_gracza.connect(_pocisk_drona_trafil)


func _pocisk_drona_trafil(pozycja: Vector2) -> void:
	if run_state != null and not mecz_zakonczony and not run_state.boss_aktywny:
		trafienia_dronow.append(pozycja)


func _wyczysc_pociski_dronow() -> void:
	trafienia_dronow.clear()
	for pocisk in get_tree().get_nodes_in_group("pociski_dronow"):
		pocisk.queue_free()


func _wyczysc_krysztaly() -> void:
	_wyczysc_pociski_dronow()
	kolejka_wybuchow_krysztalow.clear()
	for krysztal in krysztaly:
		if is_instance_valid(krysztal):
			krysztal.queue_free()
	krysztaly.clear()


func _rozpocznij_bossa() -> void:
	if run_state == null or mecz_zakonczony:
		return
	boss_oczekuje = false
	_wyczysc_zdarzenia_bossa()
	var definicje := BossDefinicja.katalog()
	boss = BossRun.new()
	boss.definicja = definicje[run_state.bossIndex % definicje.size()]
	run_state.punkty_zamrozone = true
	boss.bossIndex = run_state.bossIndex
	boss.totalPoints = floori(run_state.score)
	boss.paletka = gra.lewa_paletka()
	boss.pilka = gra.pilka()
	boss.satelita_zniszczony.connect(_satelita_zniszczony)
	boss.gotowy.connect(_boss_gotowy)
	boss.pokonany.connect(_pokonano_bossa)
	boss.trafiono_gracza.connect(_pocisk_bossa_trafil)
	gra.add_child(boss)
	gra.zresetuj_rozpad_punktu()
	gra.lewa_paletka().set_physics_process(true)
	gra.pilka().set_physics_process(false)


func _satelita_zniszczony() -> void:
	if run_state == null or mecz_zakonczony:
		return
	run_state.dodaj_punkty(DIFFICULTY.SAT_SCORE)
	wynik_gracza = floori(run_state.score)
	gra.ustaw_wyniki(wynik_gracza, run_state.lives)


func _boss_gotowy() -> void:
	if run_state == null or mecz_zakonczony:
		return
	gra.pilka().set_physics_process(true)
	gra.pilka().intro_czas = 0.0


func kolejkuj_trafienie_bossa(cel: BossRun, obrazenia: int, ksztalt: Object = null, normalna: Vector2 = Vector2.ZERO) -> void:
	if run_state != null and run_state.boss_aktywny and cel == boss and not nagroda_bossa and not mecz_zakonczony:
		obrazenia_bossa.append(cel.przygotuj_trafienie(obrazenia, ksztalt, normalna))


func kolejkuj_strate_pilki_bossa() -> void:
	if run_state != null and not nagroda_bossa and not mecz_zakonczony:
		strata_pilki_bossa = true


func _pocisk_bossa_trafil(pozycja: Vector2) -> void:
	if run_state != null and run_state.boss_aktywny and not nagroda_bossa and not mecz_zakonczony:
		trafienia_pociskow.append(pozycja)


func _pokonano_bossa() -> void:
	rozpad_bossa_zakonczony = true


func _wyczysc_zdarzenia_bossa() -> void:
	obrazenia_bossa.clear()
	trafienia_pociskow.clear()
	trafienia_dronow.clear()
	strata_pilki_bossa = false
	rozpad_bossa_zakonczony = false


func _rozstrzygnij_zdarzenia_bossa() -> void:
	if run_state.wybor_aktywny or get_tree().paused:
		return
	if boss_oczekuje:
		if wybory_w_kolejce > 0:
			_pokaz_wybor_endless()
		else:
			_rozpocznij_bossa()
		return
	if nagroda_bossa:
		if nagroda_bossa_otwarta:
			nagroda_bossa = false
			nagroda_bossa_otwarta = false
			run_state.boss_aktywny = false
			run_state.punkty_zamrozone = false
			run_state.nextBossScore = (floori(run_state.score / RunState.BOSS_EVERY_POINTS) + 1) * RunState.BOSS_EVERY_POINTS
			_wyczysc_zdarzenia_bossa()
			_odnow_pilki_endless()
		else:
			_pokaz_wybor_endless()
		return
	if is_instance_valid(boss):
		for obrazenia in obrazenia_bossa:
			boss.trafienie(obrazenia)
	obrazenia_bossa.clear()
	var zwyciestwo := rozpad_bossa_zakonczony or (is_instance_valid(boss) and boss.hp <= 0)
	if zwyciestwo:
		trafienia_dronow.clear()
		trafienia_pociskow.clear()
		strata_pilki_bossa = false
		run_state.lives = maxi(1, run_state.lives)
		if not rozpad_bossa_zakonczony:
			return
		wybory_w_kolejce = 0
		while _prog_ulepszenia(indeks_progu_ulepszenia) <= floori(run_state.score):
			indeks_progu_ulepszenia += 1
		run_state.bossIndex += 1
		czas_do_krysztalu = DIFFICULTY.SPAWN_BASE_MS / 1000.0
		nagroda_bossa = true
		wybor_oczekuje = false
		_wyczysc_zdarzenia_bossa()
		gra.zresetuj_rozpad_punktu()
		gra.lewa_paletka().set_physics_process(true)
		_zastosuj_stan_endless()
		_pokaz_wybor_endless()
		return
	var strata_pilki := strata_pilki_bossa
	strata_pilki_bossa = false
	if strata_pilki and run_state.uzyj_tarczy():
		gra.pilka().odbij_tarcza()
		gra.odtworz_dzwiek_bonusu()
		strata_pilki = false
	var pocisk_trafil := not trafienia_pociskow.is_empty()
	if pocisk_trafil and run_state.dashIframeRemaining > 0.0:
		run_state.dodgeSparkPosition = trafienia_pociskow[0]
		run_state.dodgeSparkRemaining = 0.2
		pocisk_trafil = false
	trafienia_pociskow.clear()
	if run_state.invulnRemaining > 0.0:
		pocisk_trafil = false
		if strata_pilki:
			gra.pilka().reset_bezpieczny()
		strata_pilki = false
	var dron_trafil := not trafienia_dronow.is_empty()
	if dron_trafil and run_state.dashIframeRemaining > 0.0:
		run_state.dodgeSparkPosition = trafienia_dronow[0]
		run_state.dodgeSparkRemaining = 0.2
		dron_trafil = false
	trafienia_dronow.clear()
	if run_state.invulnRemaining > 0.0:
		dron_trafil = false
	if dron_trafil and run_state.uzyj_tarczy():
		gra.odtworz_dzwiek_bonusu()
		dron_trafil = false
	if not strata_pilki and not pocisk_trafil and not dron_trafil:
		return
	_wyczysc_pociski_dronow()
	gra.lewa_paletka().efekt_obrazen()
	run_state.lives -= 1
	run_state.invulnRemaining = RunState.INVULN_MS / 1000.0
	biezaca_wymiana = 0
	gra.odtworz_dzwiek_punktu()
	if is_instance_valid(boss):
		boss.odrocz_atak_po_stracie()
	if strata_pilki:
		gra.pilka().pokaz_rozpad_endless(run_state.lives <= 0)
	gra.zresetuj_rozpad_punktu()
	gra.lewa_paletka().reset_po_punkcie()
	gra.lewa_paletka().set_physics_process(true)
	if run_state.lives <= 0:
		_zastosuj_stan_endless()
		_wyczysc_zdarzenia_bossa()
		_zakoncz_endless()
	else:
		gra.pilka().reset_bezpieczny()
		_zastosuj_stan_endless()


func _zastosuj_stan_endless() -> void:
	if not is_equal_approx(gra.pilka().mnoznik_rozmiaru, run_state.ballSizeMult):
		gra.animuj_rozmiar_pilki(run_state.ballSizeMult, 0.3)
	gra.lewa_paletka().ustaw_wysokosc(endless_wysokosc_startowa * run_state.paddleWidthMult)
	gra.lewa_paletka()._ogranicz_pozycje_y()
	wynik_ai = run_state.lives
	wynik_gracza = floori(run_state.score)
	gra.ustaw_wyniki(wynik_gracza, run_state.lives)
	_odswiez_info_endless()


func _odnow_pilki_endless() -> void:
	if run_state == null or mecz_zakonczony:
		return
	gra.pilka().reset()


func _zakoncz_endless() -> void:
	zakoncz_mecz("Koniec rozgrywki")
	gra.pilka().run_state = null
	gra.lewa_paletka().run_state = null
	wybor_ulepszenia.stan = null
	wybor_ulepszenia.oferty.clear()
	run_state = null


func zakoncz_po_czasie() -> void:
	if wynik_gracza > wynik_ai:
		zakoncz_mecz("Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_1)
	elif wynik_ai > wynik_gracza:
		zakoncz_mecz("Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_2)
	else:
		zakoncz_mecz("Koniec czasu — remis!")


func dodaj_info_endless() -> void:
	endless_info = HBoxContainer.new()
	endless_info.name = "InformacjaEndless"
	endless_info.custom_minimum_size = Vector2(0.0, 58.0)
	endless_info.add_theme_constant_override("separation", 10)
	endless_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endless_info.z_index = 10
	_dodaj_grupe_info_endless(endless_info, "Życia", 90.0, Color("#b8c9dc"))
	_dodaj_grupe_info_endless(endless_info, "Ulepszenia", 90.0, KOLOR_FIOLET_ENDLESS)
	_dodaj_grupe_info_endless(endless_info, "Obrażenia", 90.0, KOLOR_TURKUS_ENDLESS)
	endless_krysztaly = Label.new()
	endless_krysztaly.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endless_krysztaly.add_theme_font_override("font", CZCIONKA_ENDLESS)
	endless_krysztaly.add_theme_font_size_override("font_size", 10)
	endless_wartosci[2].get_parent().add_child(endless_krysztaly)
	_dodaj_grupe_info_endless(endless_info, "Tarcza", 100.0, KOLOR_TURKUS_ENDLESS)
	_dodaj_grupe_info_endless(endless_info, "Regeneracja", 110.0, KOLOR_TURKUS_ENDLESS)
	endless_info.move_child(endless_wartosci[2].get_parent().get_parent(), 1)
	gra.add_child(endless_info)
	get_viewport().size_changed.connect(_ustaw_pozycje_info_endless)
	_ustaw_pozycje_info_endless()
	_odswiez_info_endless()


func _dodaj_grupe_info_endless(uklad: HBoxContainer, tytul: String, szerokosc: float, akcent: Color, rozmiar_wartosci: int = 15) -> void:
	var karta := PanelContainer.new()
	karta.custom_minimum_size = Vector2(szerokosc, 58.0)
	karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var styl := StylMenu.styl_bloku()
	styl.content_margin_left = 6.0
	styl.content_margin_right = 6.0
	styl.content_margin_top = 4.0
	styl.content_margin_bottom = 4.0
	karta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karta.add_theme_stylebox_override("panel", styl)
	uklad.add_child(karta)
	var kolumna := VBoxContainer.new()
	kolumna.alignment = BoxContainer.ALIGNMENT_CENTER
	kolumna.add_theme_constant_override("separation", 1)
	kolumna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	karta.add_child(kolumna)
	var etykieta := Label.new()
	etykieta.text = tytul
	etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta.add_theme_font_override("font", CZCIONKA_ENDLESS)
	etykieta.add_theme_font_size_override("font_size", 10)
	etykieta.add_theme_color_override("font_color", Color("#9fb3ca"))
	etykieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolumna.add_child(etykieta)
	var wartosc := Label.new()
	wartosc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wartosc.add_theme_font_override("font", CZCIONKA_ENDLESS)
	wartosc.add_theme_font_size_override("font_size", rozmiar_wartosci)
	wartosc.add_theme_color_override("font_color", akcent)
	wartosc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolumna.add_child(wartosc)
	kolumna.move_child(wartosc, 0)
	endless_wartosci.append(wartosc)


func _ustaw_pozycje_info_endless() -> void:
	var wymiar = get_viewport().get_visible_rect().size
	var lewa_krawedz = Ustawienia.lewa_granica + 120.0
	var prawa_krawedz = minf(Ustawienia.prawa_granica - 12.0, wymiar.x - 12.0)
	var szerokosc = minf(SZEROKOSC_INFO_ENDLESS, maxf(0.0, prawa_krawedz - lewa_krawedz))
	var x = prawa_krawedz - szerokosc
	var y = minf(Ustawienia.dolna_granica + 12.0, wymiar.y - 70.0)
	if is_instance_valid(endless_info):
		endless_info.position = Vector2(x, y)
		endless_info.size = Vector2(szerokosc, 58.0)


func _odswiez_info_endless() -> void:
	if endless_info == null or run_state == null:
		return
	endless_wartosci[0].text = "%d/%d" % [run_state.lives, run_state.maxLives]
	endless_wartosci[1].text = str(run_state.ownedStacks.size())
	endless_wartosci[2].text = str(run_state.ballDamage)
	(endless_wartosci[3].get_parent().get_parent() as Control).visible = run_state.shieldRecharge > 0
	endless_wartosci[3].text = "Gotowa" if run_state.shieldHits >= run_state.shieldRecharge else "%d/%d pkt" % [run_state.shieldHits, run_state.shieldRecharge]
	(endless_wartosci[4].get_parent().get_parent() as Control).visible = run_state.regenInterval > 0
	endless_wartosci[4].text = "%d/%d pkt" % [run_state.regenHits, run_state.regenInterval]
	var najsilniejszy: KrysztalRun
	for krysztal in krysztaly:
		if not is_instance_valid(krysztal) or krysztal.rozpad or krysztal.is_queued_for_deletion():
			continue
		if najsilniejszy == null or krysztal.hp > najsilniejszy.hp:
			najsilniejszy = krysztal
	endless_krysztaly.text = "%s - %d/%d" % ["Dron" if najsilniejszy is DronRun else najsilniejszy.wariant.nazwa, najsilniejszy.hp, najsilniejszy.max_hp] if najsilniejszy != null else ""
	endless_krysztaly.visible = najsilniejszy != null
	endless_krysztaly.mouse_filter = Control.MOUSE_FILTER_PASS
	endless_krysztaly.tooltip_text = "Wariant i HP najsilniejszego kryształu. Pękający: wybuch zadaje 1 obrażenie pobliskim kryształom. Opancerzony: pierwszy kontakt piłki rozbija pancerz. Wędrujący: porusza się po widocznym torze. Do 6 HP: segment = 1 HP. Powyżej 6 HP: segmenty pokazują pozostałą część zdrowia."


func zakoncz_mecz(tekst: String) -> void:
	if mecz_zakonczony:
		return
	mecz_zakonczony = true
	if run_state != null:
		_wyczysc_krysztaly()
		if is_instance_valid(boss):
			boss.set_physics_process(false)
			boss.queue_free()
	if Ustawienia.tryb == "online":
		gra.ustaw_tekst_konca_online(tekst)
	gra.pokaz_wyniki(false)
	(gra.ekran_konca_meczu()).pokaz(tekst, pobierz_podsumowanie())
	if is_instance_valid(endless_info):
		endless_info.hide()
	gra.ukryj_informacje_graczowi()
	gra.odswiez_rysowanie()
	(gra.bonusy()).zatrzymaj()
	var arena_manager := gra.menedzer_areny()
	if arena_manager != null:
		arena_manager.zatrzymaj()
	for pilka in get_tree().get_nodes_in_group("pilki"):
		pilka.set_physics_process(false)
		var pilka_meczu := pilka as Pilka
		if pilka_meczu != null:
			pilka_meczu.pilka_zniszczona = true
			pilka_meczu.queue_redraw()
	gra.lewa_paletka().set_physics_process(false)
	gra.prawa_paletka().set_physics_process(false)


func pobierz_podsumowanie() -> PodsumowanieMeczu:
	var podsumowanie := PodsumowanieMeczu.new()
	podsumowanie.tryb = Ustawienia.tryb
	podsumowanie.czas_meczu = czas_meczu
	podsumowanie.wynik_gracza = wynik_gracza
	podsumowanie.wynik_ai = wynik_ai
	podsumowanie.odbicia_lacznie = stat_odbicia_gracza + stat_odbicia_rywala
	podsumowanie.mocne_odbicia_lacznie = stat_mocne_odbicia_gracza + stat_mocne_odbicia_rywala
	if Ustawienia.tryb == "endless" and run_state != null:
		podsumowanie.ulepszenia_endless = run_state.ownedStacks.size()
		podsumowanie.mnoznik_predkosci_endless = run_state.ballSpeedMult * run_state.mnoznik_predkosci_za_czas()
		podsumowanie.rozmiar_paletki_endless = roundi(run_state.paddleWidthMult * 100.0)
	podsumowanie.najdluzsza_wymiana = najdluzsza_wymiana
	return podsumowanie
