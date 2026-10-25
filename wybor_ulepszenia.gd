class_name WyborUlepszenia
extends CanvasLayer

signal wybrano
signal dzwiek_wyboru

var stan: RunState
var oferty: Array[UlepszenieRun] = []
var tlo: ColorRect
var kolumna: VBoxContainer
var tytul: Label
var przyciski: Array[Button] = []
var wybor_w_toku: bool = false
var przewijanie: ScrollContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	tlo = ColorRect.new()
	tlo.color = Color("#07111bea")
	tlo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tlo)
	var srodek := CenterContainer.new()
	srodek.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tlo.add_child(srodek)
	przewijanie = ScrollContainer.new()
	przewijanie.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	przewijanie.follow_focus = true
	srodek.add_child(przewijanie)
	get_viewport().size_changed.connect(_dopasuj_wybor)
	_dopasuj_wybor()
	kolumna = VBoxContainer.new()
	kolumna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolumna.add_theme_constant_override("separation", 18)
	przewijanie.add_child(kolumna)
	tytul = Label.new()
	tytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tytul.add_theme_font_size_override("font_size", 26)
	tytul.add_theme_color_override("font_color", Color("#55e7ff"))
	kolumna.add_child(tytul)
	hide()


func pokaz(nowy_stan: RunState, nowe_oferty: Array[UlepszenieRun]) -> void:
	stan = nowy_stan
	oferty = nowe_oferty
	if oferty.is_empty():
		return
	stan.wybor_aktywny = true
	wybor_w_toku = false
	tlo.show()
	for przycisk in przyciski:
		przycisk.queue_free()
	przyciski.clear()
	tytul.text = "WYBIERZ ULEPSZENIE - %d ODBIĆ" % stan.hits
	for i in range(oferty.size()):
		var oferta := oferty[i]
		var przycisk := Button.new()
		var stosy := stan.liczba_stosow(oferta.id)
		var akcent := oferta.kolor_rzadkosci()
		przycisk.custom_minimum_size.y = 126.0
		for nazwa_stylu in ["normal", "hover", "pressed", "focus", "disabled"]:
			var styl := StylMenu.styl_bloku()
			if nazwa_stylu == "hover" or nazwa_stylu == "focus":
				styl.bg_color = Color(akcent, 0.13)
			przycisk.add_theme_stylebox_override(nazwa_stylu, styl)
		var tresc := VBoxContainer.new()
		tresc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tresc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tresc.offset_left = 18.0
		tresc.offset_right = -18.0
		tresc.offset_top = 12.0
		tresc.offset_bottom = -12.0
		tresc.alignment = BoxContainer.ALIGNMENT_CENTER
		tresc.add_theme_constant_override("separation", 6)
		przycisk.add_child(tresc)
		var naglowek := HBoxContainer.new()
		naglowek.mouse_filter = Control.MOUSE_FILTER_IGNORE
		naglowek.alignment = BoxContainer.ALIGNMENT_CENTER
		naglowek.add_theme_constant_override("separation", 12)
		tresc.add_child(naglowek)
		_dodaj_tekst(naglowek, "%d. %s" % [i + 1, oferta.nazwa], Color("#e6f2ff"), 19)
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var styl_chipa := StylMenu.styl_bloku()
		styl_chipa.bg_color = Color(akcent, 0.12)
		styl_chipa.content_margin_top = 2.0
		styl_chipa.content_margin_bottom = 2.0
		styl_chipa.content_margin_left = 8.0
		styl_chipa.content_margin_right = 8.0
		chip.add_theme_stylebox_override("panel", styl_chipa)
		naglowek.add_child(chip)
		_dodaj_tekst(chip, oferta.nazwa_rzadkosci(), akcent, 12)
		_dodaj_tekst(tresc, "Poziom %d → %d   %s" % [stosy, stosy + 1, "●".repeat(stosy) + "◉" + "○".repeat(maxi(0, oferta.maxStacks - stosy - 1))], Color("#9fb3ca"), 13)
		if oferta.rarity == UlepszenieRun.Rzadkosc.PRZEKLETE:
			var zmiany := HBoxContainer.new()
			zmiany.mouse_filter = Control.MOUSE_FILTER_IGNORE
			zmiany.alignment = BoxContainer.ALIGNMENT_CENTER
			zmiany.add_theme_constant_override("separation", 24)
			tresc.add_child(zmiany)
			_dodaj_tekst(zmiany, "Wynik x%s → x%s" % [UlepszenieRun._liczba(pow(1.5, stosy)), UlepszenieRun._liczba(pow(1.5, stosy + 1))], Color("#78e5bc"), 15)
			_dodaj_tekst(zmiany, "Prędkość +%s%% → +%s%%" % [UlepszenieRun._liczba((pow(1.15, stosy) - 1.0) * 100.0), UlepszenieRun._liczba((pow(1.15, stosy + 1) - 1.0) * 100.0)], Color("#ff7793"), 15)
		else:
			_dodaj_tekst(tresc, "%s → %s" % [oferta.wartosc_opisu(stosy), oferta.wartosc_opisu(stosy + 1)], Color("#b9cde2"), 15)
		przycisk.pressed.connect(_wybierz.bind(i))
		kolumna.add_child(przycisk)
		przyciski.append(przycisk)
	show()
	get_tree().paused = true
	przewijanie.scroll_vertical = 0
	przyciski[0].grab_focus()


func _dopasuj_wybor() -> void:
	var wymiar := get_viewport().get_visible_rect().size
	przewijanie.custom_minimum_size = Vector2(minf(820.0, wymiar.x - 40.0), minf(540.0, wymiar.y - 40.0))


func _input(event: InputEvent) -> void:
	if not visible or stan == null or not stan.wybor_aktywny:
		return
	if wybor_w_toku:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo and not wybor_w_toku:
			var indeks: int = -1
			match event.physical_keycode:
				KEY_1, KEY_KP_1: indeks = 0
				KEY_2, KEY_KP_2: indeks = 1
				KEY_3, KEY_KP_3: indeks = 2
			if indeks >= 0 and indeks < oferty.size():
				_wybierz(indeks)


func _wybierz(indeks: int) -> void:
	if wybor_w_toku or not stan.wybor_aktywny:
		return
	wybor_w_toku = true
	oferty[indeks].apply(stan)
	dzwiek_wyboru.emit()
	wybrano.emit()
	get_viewport().set_input_as_handled()
	await get_tree().process_frame
	hide()
	stan.wybor_aktywny = false
	get_tree().paused = false


func _dodaj_tekst(rodzic: Control, tekst: String, kolor: Color, rozmiar: int) -> void:
	var etykieta := Label.new()
	etykieta.text = tekst
	etykieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta.add_theme_font_override("font", preload("res://assets/fonts/Oxanium.ttf"))
	etykieta.add_theme_font_size_override("font_size", rozmiar)
	etykieta.add_theme_color_override("font_color", kolor)
	rodzic.add_child(etykieta)
