class_name GraPongAPI
extends Node2D

var pilka_glowna: Pilka
var paletka_gracza: PaletkaBazowa
var paletka_rywala: PaletkaBazowa
var etykieta_wyniku_gracza: Label
var etykieta_wyniku_rywala: Label
var ekran_konca: EkranKonca
var przebieg_meczu: PrzebiegMeczu
var obsluga_online: ObslugaOnline
var bonus_manager: BonusManager
var wskazniki_dasha: Node2D
var sciana_gorna: StaticBody2D
var sciana_dolna: StaticBody2D
var ksztalt_sciany_gornej: CollisionShape2D
var ksztalt_sciany_dolnej: CollisionShape2D
var czas_bonusu: Timer

var arena_manager: ArenaManagerAPI


func przygotuj_referencje_sceny() -> void:
	pilka_glowna = $"Piłka"
	paletka_gracza = $Paletka
	paletka_rywala = $PaletkaAI
	etykieta_wyniku_gracza = $WynikGracza
	etykieta_wyniku_rywala = $WynikAI
	ekran_konca = $EkranKonca
	przebieg_meczu = $PrzebiegMeczu
	obsluga_online = $ObslugaOnline
	bonus_manager = $BonusManager
	wskazniki_dasha = $WskaznikiDasha
	sciana_gorna = $"górna ściana"
	sciana_dolna = $"dolna ściana"
	ksztalt_sciany_gornej = $"górna ściana/CollisionShape2D"
	ksztalt_sciany_dolnej = $"dolna ściana/CollisionShape2D"
	czas_bonusu = $CzasBonusu

# Wspolny, typowany punkt kontaktu skryptow rozgrywki ze scena meczu.
var rozpad_punktu_trwa = false
var postep_animacji_strefy = 0.0
var gumowa_sciana_strona = 0
var gumowa_sciana_y = 0.0
var gumowa_sciana_ugiecie = 0.0
var gumowa_sciana_kula_id = 0

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


func ustaw_tekst_konca_online(_tekst: String) -> void:
	_brak_implementacji("ustaw_tekst_konca_online")


func _odswiez_rysowanie() -> void:
	_brak_implementacji("_odswiez_rysowanie")


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


func _prostokat_karty_wyniku(_strona: int) -> Rect2:
	_brak_implementacji("_prostokat_karty_wyniku")
	return Rect2()
