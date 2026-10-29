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
var miejsca_kart: Array[Control] = []
var animacja_otwarcia: Tween
var animacja_zamkniecia: Tween
var generacja: int = 0
var animacje_energii: Array[Tween] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	tlo = ColorRect.new()
	tlo.color = Color("#07111bc7")
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
	var margines := MarginContainer.new()
	margines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margines.add_theme_constant_override("margin_left", 20)
	margines.add_theme_constant_override("margin_right", 20)
	margines.add_theme_constant_override("margin_top", 12)
	margines.add_theme_constant_override("margin_bottom", 16)
	przewijanie.add_child(margines)
	margines.add_child(kolumna)
	tytul = Label.new()
	tytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tytul.add_theme_font_size_override("font_size", 26)
	tytul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tytul.add_theme_color_override("font_color", Color("#55e7ff"))
	var miejsce_tytulu := Control.new()
	miejsce_tytulu.custom_minimum_size.y = 38.0
	kolumna.add_child(miejsce_tytulu)
	tytul.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	miejsce_tytulu.add_child(tytul)
	tytul.minimum_size_changed.connect(func(): miejsce_tytulu.custom_minimum_size.y = maxf(38.0, tytul.get_combined_minimum_size().y))
	hide()


func pokaz(nowy_stan: RunState, nowe_oferty: Array[UlepszenieRun]) -> void:
	if visible or wybor_w_toku or nowy_stan == null or nowe_oferty.is_empty():
		return
	stan = nowy_stan
	oferty = nowe_oferty
	stan.wybor_aktywny = true
	wybor_w_toku = false
	tlo.show()
	generacja += 1
	_zatrzymaj_energie()
	for miejsce in miejsca_kart:
		kolumna.remove_child(miejsce)
		miejsce.queue_free()
	miejsca_kart.clear()
	przyciski.clear()
	tytul.text = "WYBIERZ ULEPSZENIE - %d PKT" % floori(stan.score)
	for i in range(oferty.size()):
		var oferta := oferty[i]
		var przycisk := Button.new()
		var stosy := stan.liczba_stosow(oferta.id)
		var akcent := oferta.kolor_rzadkosci()
		przycisk.disabled = true
		var miejsce := Control.new()
		miejsce.custom_minimum_size.y = 126.0
		przycisk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for nazwa_stylu in ["normal", "hover", "pressed", "focus", "disabled"]:
			var styl := StylMenu.styl_bloku()
			styl.border_color = Color(akcent, 0.72)
			styl.set_border_width_all(2)
			if oferta.rarity >= UlepszenieRun.Rzadkosc.RZADKIE:
				styl.shadow_color = Color(akcent, 0.14)
				styl.shadow_size = 5 if oferta.rarity == UlepszenieRun.Rzadkosc.RZADKIE else 8
				styl.shadow_offset = Vector2.ZERO
			if nazwa_stylu == "hover" or nazwa_stylu == "focus":
				styl.bg_color = Color(akcent, 0.15)
				styl.border_color = akcent
			if nazwa_stylu == "focus":
				styl.draw_center = false
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
		styl_chipa.border_color = Color(akcent, 0.45)
		styl_chipa.bg_color = Color(akcent, 0.12)
		styl_chipa.content_margin_top = 2.0
		styl_chipa.content_margin_bottom = 2.0
		styl_chipa.content_margin_left = 8.0
		styl_chipa.content_margin_right = 8.0
		chip.add_theme_stylebox_override("panel", styl_chipa)
		naglowek.add_child(chip)
		_dodaj_tekst(chip, oferta.nazwa_rzadkosci(), akcent, 12)
		_dodaj_tekst(tresc, "Poziom %d → %d   %s" % [stosy, stosy + 1, "●".repeat(stosy) + "◉" + "○".repeat(maxi(0, oferta.maxStacks - stosy - 1))], Color("#9fb3ca"), 13)
		_dodaj_tekst(tresc, oferta.wartosc_opisu(stosy + 1), Color("#b9cde2"), 15)
		StylMenu.dodaj_animacje(przycisk, akcent)
		przycisk.pressed.connect(_wybierz.bind(i))
		kolumna.add_child(miejsce)
		miejsce.add_child(przycisk)
		if oferta.rarity == UlepszenieRun.Rzadkosc.LEGENDARNE:
			_dodaj_energie(przycisk, akcent)
		miejsca_kart.append(miejsce)
		przyciski.append(przycisk)
		tresc.minimum_size_changed.connect(func(): miejsce.custom_minimum_size.y = maxf(126.0, tresc.get_combined_minimum_size().y + 24.0))
	show()
	get_tree().paused = true
	przewijanie.scroll_vertical = 0
	tlo.modulate.a = 0.0
	tytul.modulate.a = 0.0
	for przycisk in przyciski:
		przycisk.modulate.a = 0.0
	_animuj_otwarcie(generacja)


func _dopasuj_wybor() -> void:
	var wymiar := get_viewport().get_visible_rect().size
	przewijanie.custom_minimum_size = Vector2(maxf(1.0, minf(820.0, wymiar.x - 40.0)), maxf(1.0, minf(540.0, wymiar.y - 40.0)))


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


func _animuj_otwarcie(numer: int) -> void:
	await get_tree().process_frame
	if numer != generacja or wybor_w_toku or not visible:
		return
	tytul.position.y = 12.0
	animacja_otwarcia = create_tween().set_parallel(true)
	animacja_otwarcia.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacja_otwarcia.tween_property(tlo, "modulate:a", 1.0, 0.22)
	animacja_otwarcia.tween_property(tytul, "modulate:a", 1.0, 0.25)
	animacja_otwarcia.tween_property(tytul, "position:y", 0.0, 0.25)
	for i in range(przyciski.size()):
		var przycisk := przyciski[i]
		przycisk.position.y = 22.0
		przycisk.pivot_offset = przycisk.size * 0.5
		przycisk.scale = Vector2.ONE * 0.95
		var opoznienie := 0.08 + i * 0.10
		animacja_otwarcia.tween_property(przycisk, "modulate:a", 1.0, 0.24).set_delay(opoznienie)
		animacja_otwarcia.tween_property(przycisk, "position:y", 0.0, 0.28).set_delay(opoznienie)
		animacja_otwarcia.tween_property(przycisk, "scale", Vector2.ONE, 0.28).set_delay(opoznienie)
	animacja_otwarcia.chain().tween_callback(_udostepnij_karty.bind(numer))


func _udostepnij_karty(numer: int) -> void:
	if numer != generacja or wybor_w_toku or not visible:
		return
	for przycisk in przyciski:
		przycisk.disabled = false


func _wybierz(indeks: int) -> void:
	if wybor_w_toku or stan == null or not stan.wybor_aktywny or indeks < 0 or indeks >= oferty.size():
		return
	wybor_w_toku = true
	if animacja_otwarcia != null and animacja_otwarcia.is_valid():
		animacja_otwarcia.kill()
	for przycisk in przyciski:
		przycisk.disabled = true
		if przycisk.has_meta("animacja_najechania"):
			var najechanie: Tween = przycisk.get_meta("animacja_najechania")
			if najechanie != null and najechanie.is_valid():
				najechanie.kill()
	tlo.modulate.a = 1.0
	var wybrany := przyciski[indeks]
	wybrany.modulate.a = 1.0
	animacja_zamkniecia = create_tween().set_parallel(true)
	animacja_zamkniecia.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animacja_zamkniecia.tween_property(wybrany, "scale", Vector2.ONE * 1.025, 0.10)
	for przycisk in przyciski:
		if przycisk != wybrany:
			animacja_zamkniecia.tween_property(przycisk, "modulate:a", 0.28, 0.10)
	animacja_zamkniecia.chain().tween_property(tlo, "modulate:a", 0.0, 0.12)
	dzwiek_wyboru.emit()
	get_viewport().set_input_as_handled()
	await animacja_zamkniecia.finished
	if stan == null or not is_inside_tree():
		return
	oferty[indeks].apply(stan)
	wybrano.emit()
	await get_tree().process_frame
	hide()
	_zatrzymaj_energie()
	stan.wybor_aktywny = false
	wybor_w_toku = false
	get_tree().paused = false


func _dodaj_tekst(rodzic: Control, tekst: String, kolor: Color, rozmiar: int) -> void:
	var etykieta := Label.new()
	etykieta.text = tekst
	etykieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if rodzic is BoxContainer:
		etykieta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		etykieta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etykieta.add_theme_font_override("font", preload("res://assets/fonts/Oxanium.ttf"))
	etykieta.add_theme_font_size_override("font_size", rozmiar)
	etykieta.add_theme_color_override("font_color", kolor)
	rodzic.add_child(etykieta)


func _dodaj_energie(przycisk: Button, akcent: Color) -> void:
	var energia := Panel.new()
	energia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energia.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var obrys := StyleBoxFlat.new()
	obrys.draw_center = false
	obrys.set_corner_radius_all(10)
	obrys.set_border_width_all(2)
	obrys.border_color = Color(akcent, 0.12)
	obrys.shadow_color = Color(akcent, 0.08)
	obrys.shadow_size = 9
	energia.add_theme_stylebox_override("panel", obrys)
	przycisk.add_child(energia)
	var puls := energia.create_tween().set_loops().set_parallel(true)
	puls.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	puls.tween_property(obrys, "border_color", Color(akcent, 0.50), 1.6)
	puls.tween_property(obrys, "shadow_color", Color(akcent, 0.22), 1.6)
	puls.chain().tween_property(obrys, "border_color", Color(akcent, 0.12), 1.6)
	puls.parallel().tween_property(obrys, "shadow_color", Color(akcent, 0.08), 1.6)
	animacje_energii.append(puls)


func _zatrzymaj_energie() -> void:
	for animacja in animacje_energii:
		if animacja.is_valid():
			animacja.kill()
	animacje_energii.clear()
