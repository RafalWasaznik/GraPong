class_name GraPongAPI
extends Node2D

@export_node_path("Node") var pilka_glowna_path: NodePath
@export_node_path("Node") var paletka_gracza_path: NodePath
@export_node_path("Node") var paletka_rywala_path: NodePath
@export_node_path("Node") var etykieta_wyniku_gracza_path: NodePath
@export_node_path("Node") var etykieta_wyniku_rywala_path: NodePath
@export_node_path("Node") var ekran_konca_path: NodePath
@export_node_path("Node") var przebieg_meczu_path: NodePath
@export_node_path("Node") var obsluga_online_path: NodePath
@export_node_path("Node") var bonus_manager_path: NodePath
@export_node_path("Node") var wskazniki_dasha_path: NodePath
@export_node_path("Node") var sciana_gorna_path: NodePath
@export_node_path("Node") var sciana_dolna_path: NodePath
@export_node_path("Node") var ksztalt_sciany_gornej_path: NodePath
@export_node_path("Node") var ksztalt_sciany_dolnej_path: NodePath
@export_node_path("Node") var czas_bonusu_path: NodePath
@export_node_path("Node") var rysowanie_areny_path: NodePath

var _pilka_glowna: Pilka
var _paletka_gracza: PaletkaBazowa
var _paletka_rywala: PaletkaBazowa
var _etykieta_wyniku_gracza: Label
var _etykieta_wyniku_rywala: Label
var _ekran_konca: EkranKonca
var _przebieg_meczu: PrzebiegMeczu
var _obsluga_online: ObslugaOnline
var _bonus_manager: BonusManager
var _wskazniki_dasha: Node2D
var _sciana_gorna: StaticBody2D
var _sciana_dolna: StaticBody2D
var _ksztalt_sciany_gornej: CollisionShape2D
var _ksztalt_sciany_dolnej: CollisionShape2D
var _czas_bonusu: Timer
var _rysowanie_areny: Node2D

var _arena_manager: ArenaManagerAPI
var efekty_wizualne: EfektyMeczu
var _referencje_sceny_poprawne = false


func pilka() -> Pilka:
	return _pilka_glowna


func lewa_paletka() -> PaletkaBazowa:
	return _paletka_gracza


func prawa_paletka() -> PaletkaBazowa:
	return _paletka_rywala


func etykieta_wyniku_lewego() -> Label:
	return _etykieta_wyniku_gracza


func etykieta_wyniku_prawego() -> Label:
	return _etykieta_wyniku_rywala


func ekran_konca_meczu() -> EkranKonca:
	return _ekran_konca


func przebieg() -> PrzebiegMeczu:
	return _przebieg_meczu


func obsluga_sieciowa() -> ObslugaOnline:
	return _obsluga_online


func bonusy() -> BonusManager:
	return _bonus_manager


func menedzer_areny() -> ArenaManagerAPI:
	return _arena_manager


func pobierz_wskazniki_dasha() -> Node2D:
	return _wskazniki_dasha


func zegar_bonusow() -> Timer:
	return _czas_bonusu


func ustaw_wyniki(wynik_lewy: int, wynik_prawy: int) -> void:
	if is_instance_valid(efekty_wizualne):
		if _etykieta_wyniku_gracza.text != str(wynik_lewy):
			efekty_wizualne.zmiana_wyniku(0)
		if _etykieta_wyniku_rywala.text != str(wynik_prawy):
			efekty_wizualne.zmiana_wyniku(1)
	_etykieta_wyniku_gracza.text = str(wynik_lewy)
	_etykieta_wyniku_rywala.text = str(wynik_prawy)


func pokaz_wyniki(pokaz: bool) -> void:
	_etykieta_wyniku_gracza.visible = pokaz
	_etykieta_wyniku_rywala.visible = pokaz and Ustawienia.tryb != "endless"


func zresetuj_rozpad_punktu() -> void:
	_rozpad_punktu_trwa = false


func postep_strefy() -> float:
	return _postep_animacji_strefy


func dane_gumowej_sciany() -> DaneGumowejSciany:
	var dane := DaneGumowejSciany.new()
	dane.strona = _gumowa_sciana_strona
	dane.y = _gumowa_sciana_y
	dane.ugiecie = _gumowa_sciana_ugiecie
	return dane


func przygotuj_referencje_sceny() -> bool:
	_referencje_sceny_poprawne = false
	_pilka_glowna = get_node_or_null(pilka_glowna_path) as Pilka
	_paletka_gracza = get_node_or_null(paletka_gracza_path) as PaletkaBazowa
	_paletka_rywala = get_node_or_null(paletka_rywala_path) as PaletkaBazowa
	_etykieta_wyniku_gracza = get_node_or_null(etykieta_wyniku_gracza_path) as Label
	_etykieta_wyniku_rywala = get_node_or_null(etykieta_wyniku_rywala_path) as Label
	_ekran_konca = get_node_or_null(ekran_konca_path) as EkranKonca
	_przebieg_meczu = get_node_or_null(przebieg_meczu_path) as PrzebiegMeczu
	_obsluga_online = get_node_or_null(obsluga_online_path) as ObslugaOnline
	_bonus_manager = get_node_or_null(bonus_manager_path) as BonusManager
	_wskazniki_dasha = get_node_or_null(wskazniki_dasha_path) as Node2D
	_sciana_gorna = get_node_or_null(sciana_gorna_path) as StaticBody2D
	_sciana_dolna = get_node_or_null(sciana_dolna_path) as StaticBody2D
	_ksztalt_sciany_gornej = get_node_or_null(ksztalt_sciany_gornej_path) as CollisionShape2D
	_ksztalt_sciany_dolnej = get_node_or_null(ksztalt_sciany_dolnej_path) as CollisionShape2D
	_czas_bonusu = get_node_or_null(czas_bonusu_path) as Timer
	_rysowanie_areny = get_node_or_null(rysowanie_areny_path) as Node2D
	var wymagane_referencje = [_pilka_glowna, _paletka_gracza, _paletka_rywala, _etykieta_wyniku_gracza, _etykieta_wyniku_rywala, _ekran_konca, _przebieg_meczu, _obsluga_online, _bonus_manager, _wskazniki_dasha, _sciana_gorna, _sciana_dolna, _ksztalt_sciany_gornej, _ksztalt_sciany_dolnej, _czas_bonusu, _rysowanie_areny]
	for referencja in wymagane_referencje:
		if referencja == null:
			push_error("Scena meczu ma nieprzypisaną albo nieprawidłową referencję w GraPongAPI.")
			return false
	_referencje_sceny_poprawne = true
	return true


# Wspolny, typowany punkt kontaktu skryptow rozgrywki ze scena meczu.
var _rozpad_punktu_trwa = false
var _postep_animacji_strefy = 0.0
var _gumowa_sciana_strona = 0
var _gumowa_sciana_y = 0.0
var _gumowa_sciana_ugiecie = 0.0
var _gumowa_sciana_kula_id = 0

var wynik_gracza: int:
	get:
		return pobierz_wynik_gracza()
var wynik_ai: int:
	get:
		return pobierz_wynik_ai()
var mecz_zakonczony: bool:
	get:
		return czy_mecz_zakonczony()


func _brak_implementacji(metoda: String) -> void:
	push_error("GraPongAPI nie ma implementacji metody: " + metoda)


func pobierz_wynik_gracza() -> int:
	_brak_implementacji("pobierz_wynik_gracza")
	return 0


func pobierz_wynik_ai() -> int:
	_brak_implementacji("pobierz_wynik_ai")
	return 0


func czy_mecz_zakonczony() -> bool:
	_brak_implementacji("czy_mecz_zakonczony")
	return false


func pokaz_informacje_graczowi(_tytul: String, _opis: String, _kolor: Color, _czas: float) -> void:
	_brak_implementacji("pokaz_informacje_graczowi")


func odtworz_dzwiek_modyfikatora() -> void:
	_brak_implementacji("odtworz_dzwiek_modyfikatora")


func odtworz_dzwiek_bonusu() -> void:
	_brak_implementacji("odtworz_dzwiek_bonusu")


func odtworz_dzwiek_punktu() -> void:
	_brak_implementacji("odtworz_dzwiek_punktu")


func odtworz_dzwiek_kamienia_milowego() -> void:
	_brak_implementacji("odtworz_dzwiek_kamienia_milowego")


func odtworz_dzwiek_rekordu() -> void:
	_brak_implementacji("odtworz_dzwiek_rekordu")


func ustaw_tekst_konca_online(_tekst: String) -> void:
	_brak_implementacji("ustaw_tekst_konca_online")


func odswiez_rysowanie() -> void:
	_brak_implementacji("odswiez_rysowanie")


func animuj_granice_areny(_gora: float, _dol: float, _czas: float = 0.8) -> void:
	_brak_implementacji("animuj_granice_areny")


func animuj_wymiary_areny(_lewa: float, _prawa: float, _gora: float, _dol: float, _czas: float = 0.8) -> void:
	_brak_implementacji("animuj_wymiary_areny")


func animuj_strefe_przyspieszenia(_pokaz: bool, _czas: float = 0.55) -> void:
	_brak_implementacji("animuj_strefe_przyspieszenia")


func animuj_wysokosc_paletek(_proporcja: float, _czas: float = 0.45) -> void:
	_brak_implementacji("animuj_wysokosc_paletek")


func animuj_rozmiar_pilki(_proporcja: float, _czas: float = 0.55) -> void:
	_brak_implementacji("animuj_rozmiar_pilki")


func ukryj_informacje_graczowi() -> void:
	_brak_implementacji("ukryj_informacje_graczowi")


func rozpocznij_rozpad_pilki(_pilka: PilkaAPI) -> bool:
	_brak_implementacji("rozpocznij_rozpad_pilki")
	return false


func ustaw_ugiecie_gumowej_sciany(_strona: int, _y: float, _ugiecie: float, _kula_id: int) -> void:
	_brak_implementacji("ustaw_ugiecie_gumowej_sciany")


func odpusc_gumowa_sciane(_kula_id: int) -> void:
	_brak_implementacji("odpusc_gumowa_sciane")


func dodaj_dodatkowa_pilke(_pilka_zrodlowa: PilkaAPI, _pozycja: Vector2) -> void:
	_brak_implementacji("dodaj_dodatkowa_pilke")


func prostokat_karty_wyniku(_strona: int) -> Rect2:
	_brak_implementacji("prostokat_karty_wyniku")
	return Rect2()
