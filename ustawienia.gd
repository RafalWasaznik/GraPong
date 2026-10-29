extends Node

signal grafika_tla_zmieniona
signal motyw_tla_zmieniony(wybor: int)
signal paleta_przeciwnikow_zmieniona

const MOTYWY_TLA: PackedStringArray = ["Losowo", "Cyberpunk", "Kosmos", "Synthwave", "Digital Matrix"]
const JAKOSCI_TLA: PackedStringArray = ["Wyłączone", "Ograniczone", "Pełne"]

const PLIK_USTAWIEN = "user://ustawienia.cfg"

var tryb = "bot"
var arena_dwoch_graczy = false
var online_arena = false
var trudnosc = "sredni"
var charakter_bota = "defensywny"
var limit_punktow = 5
var trudnosc_klasyczna = "sredni"
var limit_punktow_klasyczny = 5
var trudnosc_areny = "sredni"
var limit_punktow_areny = 5
var rozmiar_planszy = "standardowa"
var rekord_endless = 0

var glosnosc_ogolna = 80.0
var glosnosc_muzyki = 80.0
var glosnosc_efektow = 80.0
var pelny_ekran = true
var kursor_neonowy = true
var intensywnosc_efektow: float = 70.0
var motyw_tla: int = 0
var motyw_przeciwnikow: int = 0
var ziarno_tla: int = 0
var jakosc_tla: int = 2

var tekstura_kursora_neon: Texture2D
var tekstura_kursora_tekst: Texture2D

const KLAWISZE_DOMYSLNE = {
	"lewy_gora": KEY_W,
	"lewy_dol": KEY_S,
	"dash_gracza_1": KEY_SPACE,
	"prawy_gora": KEY_UP,
	"prawy_dol": KEY_DOWN,
	"dash_gracza_2": KEY_ENTER,
	"pauza": KEY_ESCAPE
}

var klawisze = KLAWISZE_DOMYSLNE.duplicate()
var czeka_na_klawisz = false

var lewa_granica = 32.0
var prawa_granica = 1120.0
var gorna_granica = 100.0
var dolna_granica = 620.0


func _ready() -> void:
	tekstura_kursora_neon = load("res://assets/kursor_neon.svg")
	tekstura_kursora_tekst = load("res://assets/kursor_tekst.svg")
	var plik := ConfigFile.new()
	if plik.load(PLIK_USTAWIEN) == OK:
		kursor_neonowy = bool(plik.get_value("interfejs", "kursor_neonowy", true))
		intensywnosc_efektow = clampf(float(plik.get_value("ekran", "intensywnosc_efektow", 70.0)), 0.0, 100.0)
		motyw_tla = clampi(int(plik.get_value("ekran", "motyw_tla", 0)), 0, 4)
		ziarno_tla = clampi(int(plik.get_value("ekran", "ziarno_tla", 0)), 0, 2147483646)
		jakosc_tla = clampi(int(plik.get_value("ekran", "jakosc_tla", 2)), 0, 2)
	_zastosuj_kursor()


func _zastosuj_kursor() -> void:
	var strzalka: Texture2D = tekstura_kursora_neon if kursor_neonowy else null
	var tekst: Texture2D = tekstura_kursora_tekst if kursor_neonowy else null
	Input.set_custom_mouse_cursor(strzalka, Input.CURSOR_ARROW, Vector2(4, 3))
	Input.set_custom_mouse_cursor(strzalka, Input.CURSOR_POINTING_HAND, Vector2(4, 3))
	Input.set_custom_mouse_cursor(tekst, Input.CURSOR_IBEAM, Vector2(16, 16))


func _exit_tree() -> void:
	for ksztalt in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_IBEAM]:
		Input.set_custom_mouse_cursor(null, ksztalt)
	tekstura_kursora_neon = null
	tekstura_kursora_tekst = null


func ustaw_kursor_neonowy(wartosc: bool) -> void:
	kursor_neonowy = wartosc
	_zastosuj_kursor()
	zapisz()


func ustaw_intensywnosc_efektow(wartosc: float) -> void:
	intensywnosc_efektow = clampf(wartosc, 0.0, 100.0)
	grafika_tla_zmieniona.emit()
	zapisz()


func ustaw_motyw_tla(wartosc: int) -> void:
	motyw_tla = clampi(wartosc, 0, 4)
	motyw_tla_zmieniony.emit(motyw_tla)
	grafika_tla_zmieniona.emit()
	zapisz()


func ustaw_ziarno_tla(wartosc: int) -> void:
	ziarno_tla = clampi(wartosc, 0, 2147483646)
	zapisz()


func ustaw_motyw_przeciwnikow(wartosc: int) -> void:
	var nowy := clampi(wartosc, 0, 3)
	if motyw_przeciwnikow == nowy:
		return
	motyw_przeciwnikow = nowy
	paleta_przeciwnikow_zmieniona.emit()


func ustaw_jakosc_tla(wartosc: int) -> void:
	jakosc_tla = clampi(wartosc, 0, 2)
	grafika_tla_zmieniona.emit()
	zapisz()


func ustaw_geometrie_planszy():
	match rozmiar_planszy:
		"mala":
			lewa_granica = 256.0
			prawa_granica = 896.0
			gorna_granica = 164.0
			dolna_granica = 484.0

		"duza":
			lewa_granica = 32.0
			prawa_granica = 1120.0
			gorna_granica = 72.0
			dolna_granica = 576.0

		_:
			rozmiar_planszy = "standardowa"
			lewa_granica = 150.0
			prawa_granica = 1002.0
			gorna_granica = 110.0
			dolna_granica = 538.0


func wczytaj():
	var plik = ConfigFile.new()
	var blad = plik.load(PLIK_USTAWIEN)

	if blad != OK:
		klawisze = KLAWISZE_DOMYSLNE.duplicate()
		_zastosuj_klawisze()
		ustaw_geometrie_planszy()
		_zastosuj_tryb_okna()
		return

	for akcja in KLAWISZE_DOMYSLNE:
		klawisze[akcja] = int(plik.get_value("sterowanie", akcja, KLAWISZE_DOMYSLNE[akcja]))
	_zastosuj_klawisze()

	trudnosc = plik.get_value("gra", "trudnosc", trudnosc)
	limit_punktow = plik.get_value("gra", "limit_punktow", limit_punktow)
	trudnosc_klasyczna = plik.get_value("gra", "trudnosc_klasyczna", trudnosc)
	limit_punktow_klasyczny = plik.get_value("gra", "limit_punktow_klasyczny", limit_punktow)
	trudnosc_areny = plik.get_value("gra", "trudnosc_areny", trudnosc)
	limit_punktow_areny = plik.get_value("gra", "limit_punktow_areny", limit_punktow)
	rozmiar_planszy = plik.get_value("gra", "rozmiar_planszy", rozmiar_planszy)
	rekord_endless = plik.get_value("endless", "rekord", rekord_endless)

	glosnosc_ogolna = plik.get_value("audio", "ogolna", glosnosc_ogolna)
	glosnosc_muzyki = plik.get_value("audio", "muzyka", glosnosc_muzyki)
	glosnosc_efektow = plik.get_value("audio", "efekty", glosnosc_efektow)
	pelny_ekran = plik.get_value("ekran", "pelny_ekran", pelny_ekran)
	intensywnosc_efektow = clampf(float(plik.get_value("ekran", "intensywnosc_efektow", 70.0)), 0.0, 100.0)
	motyw_tla = clampi(int(plik.get_value("ekran", "motyw_tla", 0)), 0, 4)
	ziarno_tla = clampi(int(plik.get_value("ekran", "ziarno_tla", 0)), 0, 2147483646)
	jakosc_tla = clampi(int(plik.get_value("ekran", "jakosc_tla", 2)), 0, 2)
	kursor_neonowy = plik.get_value("interfejs", "kursor_neonowy", kursor_neonowy)
	_zastosuj_kursor()

	ustaw_geometrie_planszy()
	_zastosuj_tryb_okna()


func zapisz():
	var plik = ConfigFile.new()

	plik.set_value("gra", "trudnosc", trudnosc)
	plik.set_value("gra", "limit_punktow", limit_punktow)
	plik.set_value("gra", "trudnosc_klasyczna", trudnosc_klasyczna)
	plik.set_value("gra", "limit_punktow_klasyczny", limit_punktow_klasyczny)
	plik.set_value("gra", "trudnosc_areny", trudnosc_areny)
	plik.set_value("gra", "limit_punktow_areny", limit_punktow_areny)
	plik.set_value("gra", "rozmiar_planszy", rozmiar_planszy)
	plik.set_value("endless", "rekord", rekord_endless)

	plik.set_value("audio", "ogolna", glosnosc_ogolna)
	plik.set_value("audio", "muzyka", glosnosc_muzyki)
	plik.set_value("audio", "efekty", glosnosc_efektow)
	plik.set_value("ekran", "pelny_ekran", pelny_ekran)
	plik.set_value("ekran", "intensywnosc_efektow", intensywnosc_efektow)
	plik.set_value("ekran", "motyw_tla", motyw_tla)
	plik.set_value("ekran", "ziarno_tla", ziarno_tla)
	plik.set_value("ekran", "jakosc_tla", jakosc_tla)
	plik.set_value("interfejs", "kursor_neonowy", kursor_neonowy)
	for akcja in KLAWISZE_DOMYSLNE:
		plik.set_value("sterowanie", akcja, int(klawisze[akcja]))

	plik.save(PLIK_USTAWIEN)


func _zastosuj_tryb_okna() -> void:
	var tryb_okna = DisplayServer.WINDOW_MODE_FULLSCREEN if pelny_ekran else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(tryb_okna)


func ustaw_tryb_okna(wartosc: bool) -> void:
	pelny_ekran = wartosc
	_zastosuj_tryb_okna()
	zapisz()


func _zastosuj_klawisze() -> void:
	for akcja in KLAWISZE_DOMYSLNE:
		if not InputMap.has_action(akcja):
			InputMap.add_action(akcja)
		InputMap.action_erase_events(akcja)
		var zdarzenie = InputEventKey.new()
		zdarzenie.physical_keycode = int(klawisze[akcja])
		InputMap.action_add_event(akcja, zdarzenie)


func ustaw_klawisz(akcja: String, kod_fizyczny: int) -> String:
	if not KLAWISZE_DOMYSLNE.has(akcja) or kod_fizyczny == KEY_NONE:
		return ""

	var zamieniona_akcja = ""
	var poprzedni_kod = int(klawisze[akcja])
	for inna_akcja in KLAWISZE_DOMYSLNE:
		if inna_akcja != akcja and int(klawisze[inna_akcja]) == kod_fizyczny:
			klawisze[inna_akcja] = poprzedni_kod
			zamieniona_akcja = str(inna_akcja)
			break

	klawisze[akcja] = kod_fizyczny
	_zastosuj_klawisze()
	zapisz()
	return zamieniona_akcja


func przywroc_klawisze() -> void:
	klawisze = KLAWISZE_DOMYSLNE.duplicate()
	_zastosuj_klawisze()
	zapisz()


func tekst_klawisza(akcja: String) -> String:
	var zdarzenie = InputEventKey.new()
	zdarzenie.physical_keycode = int(klawisze.get(akcja, KEY_NONE))
	return zdarzenie.as_text_physical_keycode()
