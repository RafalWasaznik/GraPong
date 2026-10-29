class_name StylMenu
extends RefCounted

const FONT_MENU = preload("res://assets/fonts/Oxanium.ttf")
const DZWIEK_NAJECHANIA = preload("res://assets/kenney_ui/Sounds/tap-a.ogg")
const PROMIEN_PRZYCISKU = 10

static func styl_przycisku_karty(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var wynik := styl(tlo, obramowanie)
	wynik.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	wynik.shadow_size = 6
	wynik.shadow_offset = Vector2(0.0, 3.0)
	return wynik


static func styl_pola(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var wynik := StyleBoxFlat.new()
	wynik.bg_color = Color(tlo.r, tlo.g, tlo.b, minf(tlo.a, 0.94))
	wynik.border_color = obramowanie
	wynik.set_border_width_all(1)
	wynik.border_width_bottom = 2
	wynik.set_corner_radius_all(9)
	wynik.content_margin_left = 14.0
	wynik.content_margin_right = 14.0
	wynik.content_margin_top = 8.0
	wynik.content_margin_bottom = 8.0
	return wynik


static func dodaj_opis_trybu(przycisk: Button, tytul: String, opis: String, akcent: Color, font_arcade: Font) -> void:
	przycisk.text = ""
	przycisk.custom_minimum_size = Vector2(420.0, 76.0 if opis.is_empty() else 96.0)
	przycisk.tooltip_text = opis
	przycisk.set_meta("neon_akcent", akcent)
	var styl_karty := styl_przycisku_karty(Color("#101f31"), Color(akcent, 0.32))
	przycisk.add_theme_stylebox_override("normal", styl_karty)
	var styl_hover := styl_przycisku_karty(Color("#1a2d47"), akcent)
	styl_hover.border_width_bottom = 2
	styl_hover.shadow_color = Color(akcent, 0.08)
	styl_hover.shadow_size = 5
	styl_hover.shadow_offset = Vector2.ZERO
	przycisk.add_theme_stylebox_override("hover", styl_hover)
	if opis.is_empty():
		var etykieta := Label.new()
		etykieta.text = tytul
		etykieta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etykieta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etykieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		etykieta.add_theme_font_override("font", font_arcade)
		etykieta.add_theme_font_size_override("font_size", 26)
		etykieta.add_theme_color_override("font_color", Color("#f2f8ff"))
		przycisk.add_child(etykieta)
		return
	var uklad := VBoxContainer.new()
	uklad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uklad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	uklad.offset_left = 24.0
	uklad.offset_right = -24.0
	uklad.offset_top = 11.0
	uklad.offset_bottom = -9.0
	uklad.add_theme_constant_override("separation", 2)
	przycisk.add_child(uklad)
	var etykieta_tytulu := Label.new()
	etykieta_tytulu.text = tytul
	etykieta_tytulu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_tytulu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etykieta_tytulu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etykieta_tytulu.add_theme_font_size_override("font_size", 22)
	etykieta_tytulu.add_theme_color_override("font_color", Color("#f2f8ff"))
	uklad.add_child(etykieta_tytulu)
	var etykieta_opisu := Label.new()
	etykieta_opisu.text = opis
	etykieta_opisu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_opisu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etykieta_opisu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etykieta_opisu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etykieta_opisu.add_theme_font_size_override("font_size", 15)
	etykieta_opisu.add_theme_color_override("font_color", Color("#b9cde2"))
	uklad.add_child(etykieta_opisu)

static func styluj_przycisk(
	przycisk: Button,
	minimalny_rozmiar: Vector2,
	akcent: Color,
	tlo_normalne: Color,
	obramowanie_normalne: Color,
	tlo_najechane: Color,
	tlo_wcisniete: Color,
	obramowanie_wcisniete: Color,
	rozmiar_czcionki: int = 20
) -> void:
	przycisk.custom_minimum_size = minimalny_rozmiar
	przycisk.alignment = HORIZONTAL_ALIGNMENT_CENTER
	przycisk.add_theme_font_override("font", FONT_MENU)
	przycisk.add_theme_font_size_override("font_size", rozmiar_czcionki)
	przycisk.add_theme_color_override("font_color", Color("#e8f4ff"))
	przycisk.add_theme_color_override("font_hover_color", Color.WHITE)
	przycisk.add_theme_color_override("font_pressed_color", Color("#b8f5ff"))
	przycisk.add_theme_stylebox_override("normal", styl(tlo_normalne, obramowanie_normalne))
	przycisk.add_theme_stylebox_override("hover", styl(tlo_najechane, akcent))
	przycisk.add_theme_stylebox_override("pressed", styl(tlo_wcisniete, obramowanie_wcisniete))
	var fokus := styl(Color.TRANSPARENT, Color(akcent, 0.85))
	fokus.bg_color = Color.TRANSPARENT
	fokus.set_border_width_all(2)
	przycisk.add_theme_stylebox_override("focus", fokus)
	przycisk.add_theme_stylebox_override("disabled", styl(Color("#151d2b"), Color("#293a4e")))
	dodaj_animacje(przycisk, akcent)


static func dodaj_animacje(przycisk: Button, akcent: Color) -> void:
	if przycisk.has_meta("neon_animacje"):
		return
	przycisk.set_meta("neon_animacje", true)
	if not przycisk.has_meta("neon_akcent"):
		przycisk.set_meta("neon_akcent", akcent)
	var poswiata := Panel.new()
	poswiata.name = "PoswiataPrzycisku"
	poswiata.mouse_filter = Control.MOUSE_FILTER_IGNORE
	poswiata.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var obrys := StyleBoxFlat.new()
	obrys.bg_color = Color.TRANSPARENT
	obrys.border_color = Color(akcent, 0.0)
	obrys.set_border_width_all(1)
	obrys.border_width_bottom = 2
	obrys.set_corner_radius_all(PROMIEN_PRZYCISKU)
	obrys.shadow_color = Color(akcent, 0.0)
	obrys.shadow_size = 7
	poswiata.add_theme_stylebox_override("panel", obrys)
	przycisk.add_child(poswiata)
	przycisk.set_meta("neon_obrys", obrys)
	przycisk.pivot_offset = przycisk.size * 0.5
	przycisk.resized.connect(func(): przycisk.pivot_offset = przycisk.size * 0.5)
	przycisk.mouse_entered.connect(animuj_najechanie.bind(przycisk, true))
	przycisk.mouse_entered.connect(_odtworz_najechanie.bind(przycisk))
	przycisk.mouse_exited.connect(animuj_najechanie.bind(przycisk, false))
	przycisk.focus_entered.connect(animuj_najechanie.bind(przycisk, true))
	przycisk.focus_entered.connect(_odtworz_najechanie.bind(przycisk))
	przycisk.focus_exited.connect(animuj_najechanie.bind(przycisk, false))
	przycisk.visibility_changed.connect(func():
		if przycisk.has_meta("animacja_najechania"):
			var poprzednia: Tween = przycisk.get_meta("animacja_najechania")
			if is_instance_valid(poprzednia):
				poprzednia.kill()
		przycisk.scale = przycisk.get_meta("neon_skala_bazowa", Vector2.ONE)
		obrys.border_color.a = 0.0
		obrys.shadow_color.a = 0.0
	)


static func _odtworz_najechanie(przycisk: Button) -> void:
	if not przycisk.is_visible_in_tree() or przycisk.disabled:
		return
	var viewport := przycisk.get_viewport()
	var dzwiek := viewport.get_node_or_null("DzwiekNajechaniaUI") as AudioStreamPlayer
	if dzwiek == null:
		dzwiek = AudioStreamPlayer.new()
		dzwiek.name = "DzwiekNajechaniaUI"
		dzwiek.stream = DZWIEK_NAJECHANIA
		dzwiek.bus = &"Efekty"
		dzwiek.volume_db = -24.0
		dzwiek.process_mode = Node.PROCESS_MODE_ALWAYS
		viewport.add_child(dzwiek)
	var teraz := Time.get_ticks_msec()
	var ostatnio: int = dzwiek.get_meta("ostatnie_najechanie", -120)
	if teraz - ostatnio < 120:
		return
	dzwiek.set_meta("ostatnie_najechanie", teraz)
	dzwiek.play()


static func animuj_najechanie(przycisk: Button, _aktywne: bool) -> void:
	var aktywne := przycisk.is_visible_in_tree() and not przycisk.disabled and (przycisk.is_hovered() or przycisk.has_focus())
	var akcent: Color = przycisk.get_meta("neon_akcent", Color("#55e7ff"))
	var obrys: StyleBoxFlat = przycisk.get_meta("neon_obrys")
	if przycisk.has_meta("animacja_najechania"):
		var poprzednia: Variant = przycisk.get_meta("animacja_najechania")
		if is_instance_valid(poprzednia):
			poprzednia.kill()
	var animacja = przycisk.create_tween()
	przycisk.set_meta("animacja_najechania", animacja)
	animacja.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacja.set_parallel(true)
	var skala_bazowa: Vector2 = przycisk.get_meta("neon_skala_bazowa", Vector2.ONE)
	animacja.tween_property(przycisk, "scale", skala_bazowa * (1.012 if aktywne else 1.0), 0.16)
	animacja.tween_property(obrys, "border_color", Color(akcent, 0.95 if aktywne else 0.0), 0.18)
	animacja.tween_property(obrys, "shadow_color", Color(akcent, 0.12 if aktywne else 0.0), 0.18)


static func styl(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color(tlo.r, tlo.g, tlo.b, minf(tlo.a, 0.90))
	styl.border_color = Color(obramowanie, 0.42)
	styl.set_border_width_all(1)
	styl.border_width_bottom = 2
	styl.set_corner_radius_all(PROMIEN_PRZYCISKU)
	styl.content_margin_left = 22.0
	styl.content_margin_right = 22.0
	styl.content_margin_top = 16.0
	styl.content_margin_bottom = 16.0
	return styl


static func styl_bloku() -> StyleBoxFlat:
	var wynik := StyleBoxFlat.new()
	wynik.bg_color = Color("#102235", 0.88)
	wynik.border_color = Color("#6bb9d8", 0.16)
	wynik.set_border_width_all(1)
	wynik.border_width_top = 2
	wynik.set_corner_radius_all(8)
	wynik.content_margin_left = 18.0
	wynik.content_margin_right = 18.0
	wynik.content_margin_top = 18.0
	wynik.content_margin_bottom = 18.0
	return wynik
