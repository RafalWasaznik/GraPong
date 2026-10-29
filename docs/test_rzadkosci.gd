extends Node

var bledy: int = 0
var kontrole: int = 0
var rejestr := UlepszenieRun.katalog()
const ZDJECIA = "res://docs/rzadkosci"

func sprawdz(ok: bool, opis: String) -> void:
	kontrole += 1
	if not ok:
		bledy += 1
		push_error(opis)
	else:
		print("PASS: ", opis)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()

func poprawna(oferty: Array[UlepszenieRun], stan: RunState) -> bool:
	var ids: Array[StringName] = []
	for oferta in oferty:
		if ids.has(oferta.id) or stan.liczba_stosow(oferta.id) >= oferta.maxStacks:
			return false
		ids.append(oferta.id)
	return oferty.size() <= 3

func wypelnij(stan: RunState, ulepszenie: UlepszenieRun) -> void:
	for i in range(ulepszenie.maxStacks):
		ulepszenie.apply(stan)

func start() -> void:
	seed(30102026)
	var stan := RunState.new()
	var liczniki: Array[int] = [0, 0, 0, 0, 0]
	var po_id: Dictionary[StringName, int] = {}
	for u in rejestr:
		po_id[u.id] = 0
	for i in range(100000):
		var u := UlepszenieRun._losuj_z_puli(rejestr)
		liczniki[u.rarity] += 1
		po_id[u.id] += 1
	print("FULL_AVAILABILITY_100000: ", liczniki)
	print("PER_UPGRADE: ", po_id)
	for tier in range(5):
		sprawdz(absi(liczniki[tier] - 1000 * UlepszenieRun.WAGI_RZADKOSCI[tier]) < 700, "category %d within 0.7 percentage point" % tier)
	var jednostajne := true
	for u in rejestr:
		var liczba := 0
		for v in rejestr:
			if u.rarity == v.rarity:
				liczba += 1
		var oczekiwane := float(liczniki[u.rarity]) / liczba
		jednostajne = jednostajne and absf(po_id[u.id] - oczekiwane) < maxf(150.0, oczekiwane * 0.08)
	sprawdz(jednostajne, "uniform upgrade selection within each category")
	sprawdz(rejestr.size() == 13 and not po_id.has(&"klatwa"), "13 original upgrades, no curse")
	var oferty_ok := true
	var boss_ok := true
	for i in range(10000):
		var zwykle := UlepszenieRun.losuj(stan, rejestr)
		var boss := UlepszenieRun.losuj(stan, rejestr, true)
		oferty_ok = oferty_ok and zwykle.size() == 3 and poprawna(zwykle, stan)
		boss_ok = boss_ok and boss.size() == 3 and poprawna(boss, stan) and boss[0].rarity >= UlepszenieRun.Rzadkosc.RZADKIE
	sprawdz(oferty_ok, "10000 ordinary offers: three unique nonmaxed upgrades")
	sprawdz(boss_ok, "10000 boss offers: unique, capped, rare or better guarantee")
	var kombinacje_ok := true
	for maska in range(32):
		var czesciowy := RunState.new()
		var pozostalo := 0
		var lepsze := false
		for u in rejestr:
			if maska & (1 << u.rarity):
				wypelnij(czesciowy, u)
			else:
				pozostalo += 1
				lepsze = lepsze or u.rarity >= UlepszenieRun.Rzadkosc.RZADKIE
		for i in range(100):
			for boss in [false, true]:
				var oferty := UlepszenieRun.losuj(czesciowy, rejestr, boss)
				kombinacje_ok = kombinacje_ok and poprawna(oferty, czesciowy) and oferty.size() == mini(3, pozostalo)
				if boss and lepsze:
					kombinacje_ok = kombinacje_ok and oferty[0].rarity >= UlepszenieRun.Rzadkosc.RZADKIE
	sprawdz(kombinacje_ok, "6400 offers across all 32 exhausted-category combinations")
	var bez_zwyklych: Array[UlepszenieRun] = []
	for u in rejestr:
		if u.rarity != UlepszenieRun.Rzadkosc.ZWYKLE:
			bez_zwyklych.append(u)
	var renorm: Array[int] = [0, 0, 0, 0, 0]
	for i in range(100000):
		renorm[UlepszenieRun._losuj_z_puli(bez_zwyklych).rarity] += 1
	print("WITHOUT_COMMON_100000: ", renorm)
	var renorm_ok := renorm[0] == 0
	for tier in range(1, 5):
		renorm_ok = renorm_ok and absf(renorm[tier] - 100000.0 * UlepszenieRun.WAGI_RZADKOSCI[tier] / (100.0 - UlepszenieRun.WAGI_RZADKOSCI[UlepszenieRun.Rzadkosc.ZWYKLE])) < 700.0
	sprawdz(renorm_ok, "weights renormalize to remaining sum 52")
	var limity_ok := true
	for u in rejestr:
		wypelnij(stan, u)
		u.apply(stan)
		limity_ok = limity_ok and stan.liczba_stosow(u.id) == u.maxStacks
	sprawdz(limity_ok and UlepszenieRun.losuj(stan, rejestr, true).is_empty(), "all caps enforced; empty pool stays empty even for boss")
	sprawdz(is_equal_approx(stan.ballSpeedMult, 0.82) and is_equal_approx(stan.ballSizeMult, 1.45) and stan.maxLives == 6 and stan.ballDamage == 6 and stan.regenInterval == 25 and stan.shieldRecharge == 15, "preserved max-rank values")
	for pozostale in [1, 2]:
		var koniec := RunState.new()
		for i in range(rejestr.size() - pozostale):
			wypelnij(koniec, rejestr[i])
		var oferty := UlepszenieRun.losuj(koniec, rejestr, true)
		sprawdz(oferty.size() == pozostale and poprawna(oferty, koniec), "%d remaining upgrades produce %d valid cards" % [pozostale, pozostale])
	_zapis()
	await _interfejs(stan)
	print("RESULT: %d checks, %d failures" % [kontrole, bledy])
	get_tree().quit(bledy)

func _zapis() -> void:
	var sciezka := "res://docs/rzadkosci-stary-zapis.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("endless", "rekord", 1234)
	cfg.set_value("endless", "ownedStacks", ["klatwa", "paletka"])
	cfg.set_value("endless", "curseSpeedMult", 1.3225)
	cfg.set_value("endless", "scoreMult", 2.25)
	cfg.set_value("ekran", "pelny_ekran", false)
	sprawdz(cfg.save(sciezka) == OK, "isolated legacy settings fixture saved")
	var skrypt := GDScript.new()
	skrypt.source_code = FileAccess.get_file_as_string("res://ustawienia.gd").replace("user://ustawienia.cfg", sciezka)
	sprawdz(skrypt.reload() == OK, "real settings loader with isolated fixture path")
	var ustawienia: Node = skrypt.new()
	ustawienia.wczytaj()
	sprawdz(ustawienia.rekord_endless == 1234 and RunState.new().ownedStacks.is_empty(), "legacy record preserved; obsolete run/curse fields ignored")
	ustawienia.zapisz()
	var zapis := ConfigFile.new()
	zapis.load(sciezka)
	sprawdz(zapis.get_value("endless", "rekord") == 1234 and not zapis.has_section_key("endless", "ownedStacks") and not zapis.has_section_key("endless", "scoreMult"), "resave removes obsolete fields and preserves record")
	ustawienia.free()
	DirAccess.remove_absolute(sciezka)

func zdjecie(nazwa: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ZDJECIA + "/" + nazwa + ".png")

func _interfejs(pelny: RunState) -> void:
	Ustawienia.tryb = "endless"
	Ustawienia.pelny_ekran = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_window().size = Vector2i(1152, 648)
	var gra: GraPongAPI = load("res://scena_główna.tscn").instantiate()
	get_tree().root.add_child(gra)
	await get_tree().process_frame
	var mecz := gra.przebieg()
	mecz.set_physics_process(false)
	gra.pilka().set_physics_process(false)
	gra.lewa_paletka().set_physics_process(false)
	mecz.run_state = pelny
	mecz.nagroda_bossa = true
	pelny.boss_aktywny = true
	pelny.punkty_zamrozone = true
	mecz._pokaz_wybor_endless()
	mecz._rozstrzygnij_zdarzenia_bossa()
	sprawdz(not mecz.nagroda_bossa and not pelny.boss_aktywny and not pelny.punkty_zamrozone, "exhausted boss reward resumes game without blocking")
	gra.pilka().set_physics_process(false)
	DirAccess.make_dir_recursive_absolute(ZDJECIA)
	var wybor := mecz.wybor_ulepszenia
	var style_ok := true
	for zestaw in [[0, 1, 9], [6, 8, 3]]:
		var oferty: Array[UlepszenieRun] = []
		for indeks in zestaw:
			oferty.append(rejestr[indeks])
		wybor.pokaz(RunState.new(), oferty)
		await get_tree().create_timer(0.8).timeout
		for i in range(wybor.przyciski.size()):
			for nazwa in ["normal", "hover", "pressed", "focus", "disabled"]:
				var styl := wybor.przyciski[i].get_theme_stylebox(nazwa) as StyleBoxFlat
				style_ok = style_ok and styl.border_width_left >= 1 and styl.border_color.a >= 0.65
		await zdjecie("oferta_" + str(zestaw[0]))
		if not wybor.animacje_energii.is_empty():
			sprawdz(wybor.animacje_energii[0].is_running(), "legendary energy tween runs while paused")
			await get_tree().create_timer(1.0).timeout
			await zdjecie("legendarne_puls")
		wybor._wybierz(0)
		await get_tree().create_timer(0.5).timeout
		sprawdz(not wybor.visible and not get_tree().paused and wybor.animacje_energii.is_empty(), "selection applies and releases pause/energy animation")
	sprawdz(style_ok, "rarity border visible in every button state across five tiers")
	var pauza: CanvasLayer = gra.get_node("MenuPauzy")
	get_tree().paused = true
	pauza._pokaz_pauze()
	await get_tree().create_timer(0.5).timeout
	var grupy := 0
	for blok in pauza.efekty_lista.get_children():
		if blok is PanelContainer and blok.get_child(0) is VBoxContainer:
			grupy += 1
	sprawdz(grupy == 5, "pause lists all five rarity groups")
	await zdjecie("pauza_gora")
	pauza.efekty_przewijanie.scroll_vertical = 10000
	await get_tree().create_timer(0.1).timeout
	await zdjecie("pauza_dol")
	pauza._otworz_ustawienia()
	await get_tree().create_timer(0.4).timeout
	sprawdz(pauza.panel_ustawien.visible, "pause settings open")
	await zdjecie("ustawienia")
	pauza._wroc_do_pauzy()
	pauza._wroc_do_gry()
	var podsumowanie := mecz.pobierz_podsumowanie()
	sprawdz(podsumowanie.ulepszenia_endless == pelny.ownedStacks.size(), "end statistics count actual upgrade levels")
	gra.ekran_konca_meczu().pokaz("Koniec rozgrywki", podsumowanie)
	await get_tree().create_timer(0.4).timeout
	await zdjecie("koniec")
	gra.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

