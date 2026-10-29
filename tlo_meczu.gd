class_name TloMeczu
extends Node2D

const SHADER_TLA = preload("res://shaders/tlo_meczu.gdshader")
const CZAS_PRZEJSCIA: float = 0.65
const PALETY: Array[Vector2] = [Vector2(0.51, 0.88), Vector2(0.64, 0.83), Vector2(0.88, 0.56), Vector2(0.37, 0.47)]

var motyw: int = 0
var ziarno: int = 1
var parametry: PackedFloat32Array = PackedFloat32Array()
var dekoracje: PackedVector2Array = PackedVector2Array()
var czas: float = 0.0
var podklad: ColorRect
var obszar: Control
var powierzchnia: ColorRect
var material_tla: ShaderMaterial
var kolor_a: Color
var kolor_b: Color
var prostokat: Rect2 = Rect2(150, 110, 852, 428)
var rozmiar_okna: Vector2 = Vector2.ZERO
var _przenikanie: float = 1.0
var _poprzednie: Array[ColorRect] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	podklad = ColorRect.new()
	podklad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	podklad.color = Color("#080e18")
	add_child(podklad)
	obszar = Control.new()
	obszar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(obszar)
	get_viewport().size_changed.connect(_zmieniono_okno)
	Ustawienia.grafika_tla_zmieniona.connect(_odswiez_jakosc)
	Ustawienia.motyw_tla_zmieniony.connect(_zmieniono_motyw)
	# Każdy nowy mecz ma własny układ, niezależny od zapisanych ustawień.
	rozpocznij(Ustawienia.motyw_tla)


func _dodaj_powierzchnie(wyglad: ShaderMaterial) -> ColorRect:
	var prostokat_tla := ColorRect.new()
	prostokat_tla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prostokat_tla.material = wyglad
	obszar.add_child(prostokat_tla)
	prostokat_tla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return prostokat_tla


func rozpocznij(wybor: int, ziarno_wariantu: int = 0) -> void:
	var los := RandomNumberGenerator.new()
	ziarno = ziarno_wariantu
	if ziarno <= 0:
		los.randomize()
		ziarno = los.randi_range(1, 2147483646)
	los.seed = ziarno
	motyw = los.randi_range(0, 3) if wybor == 0 else clampi(wybor - 1, 0, 3)
	Ustawienia.ustaw_motyw_przeciwnikow(motyw)
	los.seed = ziarno ^ ((motyw + 1) * 73856093)
	parametry.clear()
	dekoracje.clear()
	for i in range(8):
		parametry.append(los.randf())
	kolor_a = Color.from_hsv(fposmod(PALETY[motyw].x + (parametry[0] - 0.5) * 0.06, 1.0), 0.72, 0.78)
	kolor_b = Color.from_hsv(fposmod(PALETY[motyw].y + (parametry[1] - 0.5) * 0.06, 1.0), 0.65, 0.7)
	if powierzchnia != null:
		_poprzednie.append(powierzchnia)
		if _poprzednie.size() > 4:
			var najstarsza: ColorRect = _poprzednie.pop_front()
			najstarsza.queue_free()
		_przenikanie = 0.0
	else:
		_przenikanie = 1.0
	material_tla = ShaderMaterial.new()
	material_tla.shader = SHADER_TLA
	material_tla.set_shader_parameter(&"motif", motyw)
	material_tla.set_shader_parameter(&"layout_seed", float(ziarno % 65521))
	material_tla.set_shader_parameter(&"variant", Vector4(parametry[2], parametry[3], parametry[4], parametry[5]))
	material_tla.set_shader_parameter(&"accent_a", kolor_a)
	material_tla.set_shader_parameter(&"accent_b", kolor_b)
	material_tla.set_shader_parameter(&"opacity", _przenikanie)
	material_tla.set_shader_parameter(&"czas", czas)
	powierzchnia = _dodaj_powierzchnie(material_tla)
	_zmieniono_okno()
	_odswiez_jakosc()


func pobierz_sygnature() -> String:
	return "%d:%d:%s:%s" % [motyw, ziarno, str(parametry), str(dekoracje)]


func ustaw_obszar(nowy: Rect2, okno: Vector2) -> void:
	if nowy == prostokat and okno == rozmiar_okna:
		return
	prostokat = nowy
	rozmiar_okna = okno
	_dopasuj_obszar()


func _zmieniono_okno() -> void:
	rozmiar_okna = get_viewport_rect().size
	_dopasuj_obszar()


func _dopasuj_obszar() -> void:
	var rozmiar := rozmiar_okna.max(Vector2.ONE)
	podklad.size = rozmiar
	obszar.position = Vector2.ZERO
	obszar.size = rozmiar
	_ustaw_geometrie(material_tla, rozmiar)
	for stara: ColorRect in _poprzednie:
		_ustaw_geometrie(stara.material as ShaderMaterial, rozmiar)


func _ustaw_geometrie(wyglad: ShaderMaterial, rozmiar: Vector2) -> void:
	wyglad.set_shader_parameter(&"rect_size", rozmiar)
	wyglad.set_shader_parameter(&"arena_rect", Vector4(prostokat.position.x, prostokat.position.y, prostokat.size.x, prostokat.size.y))


func _zmieniono_motyw(wybor: int) -> void:
	rozpocznij(wybor)


func _odswiez_jakosc() -> void:
	var sila := Ustawienia.intensywnosc_efektow / 100.0
	var aktywne := Ustawienia.jakosc_tla > 0 and sila > 0.0
	obszar.visible = aktywne
	_ustaw_jakosc(material_tla, sila)
	for stara: ColorRect in _poprzednie:
		_ustaw_jakosc(stara.material as ShaderMaterial, sila)
	set_process(aktywne or not _poprzednie.is_empty())


func _ustaw_jakosc(wyglad: ShaderMaterial, sila: float) -> void:
	wyglad.set_shader_parameter(&"strength", sila)
	wyglad.set_shader_parameter(&"quality", Ustawienia.jakosc_tla)


func _process(delta: float) -> void:
	czas += delta
	material_tla.set_shader_parameter(&"czas", czas)
	_przenikanie = minf(1.0, _przenikanie + delta / CZAS_PRZEJSCIA)
	material_tla.set_shader_parameter(&"opacity", smoothstep(0.0, 1.0, _przenikanie))
	# Starsze powierzchnie pozostają pod nową, więc przerwane przejście nie miga.
	for stara: ColorRect in _poprzednie:
		(stara.material as ShaderMaterial).set_shader_parameter(&"czas", czas)
	if _przenikanie >= 1.0 and not _poprzednie.is_empty():
		for stara: ColorRect in _poprzednie:
			stara.queue_free()
		_poprzednie.clear()
		_odswiez_jakosc()
