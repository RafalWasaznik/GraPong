# Rzadkości ulepszeń Nieskończonego

Aktualizacja wag: **44/28/15/7/6**. Poniższe wyniki testów są historyczne i dotyczą poprzednich wag 48/28/15/7/2. Po zmianie wag nie uruchamiano testów ponownie.

Wdrożono 30.10.2026. Godot 4.7.2. Zachowano 13 istniejących ulepszeń, ich limity i wartości. Klątwa szybkości i powiązane mnożniki usunięte. Run nie jest zapisywany; ustawienia i rekord pozostają kompatybilne. Nowy zapis pomija nieznane stare pola.

| Ulepszenie | Rzadkość | Maks. poziom |
|---|---|---:|
| Szersza paletka | Zwykłe | 5 |
| Większa piłka | Zwykłe | 3 |
| Szybszy dash | Zwykłe | 3 |
| Wolniejsza piłka | Niepospolite | 3 |
| Magnes | Niepospolite | 3 |
| Precyzja | Niepospolite | 3 |
| Spowolnienie na dash | Rzadkie | 2 |
| Mocniejsze uderzenie | Rzadkie | 5 |
| Kruszyciel | Rzadkie | 3 |
| Rój kryształów | Rzadkie | 2 |
| Dodatkowe życie | Epickie | 3 |
| Tarcza ściany | Epickie | 2 |
| Regeneracja | Legendarne | 1 |

Podstawowe statystyki są zwykłe, wspomaganie kontroli i premia wymagająca trafienia niepospolite, obrażenia/ekonomia i spowolnienie po dashu rzadkie, bezpośrednia ochrona życia epicka. Regeneracja jest legendarna ze względu na stałe, powtarzalne odzyskiwanie życia. Zachowano istniejący drugi poziom tarczy bez dodawania mu nowego efektu.

Losowanie najpierw wybiera dostępną kategorię z wagą 48/28/15/7/2, następnie jednostajnie ulepszenie w kategorii. Wybrane ID jest wykluczane przed kolejnym kafelkiem. Brak kategorii oznacza przeliczenie pozostałych wag. Boss gwarantuje rzadkie lub lepsze, jeśli dostępne. Pozostałe 1-2 ulepszenia dają 1-2 kafelki, pusta pula pomija wybór; po bossie gra wznawia się bez blokady. Limity nigdy nie są zwiększane przez losowanie.

## Weryfikacja

Rzeczywisty kod GDScript: `docs/test_rzadkosci.gd`, scena `docs/test_rzadkosci.tscn`. Ziarno 30102026.

| Kategoria | Waga | 100000 losowań pełnej puli | Udział |
|---|---:|---:|---:|
| Zwykłe, szare | 48 | 48350 | 48,350% |
| Niepospolite, zielone | 28 | 27790 | 27,790% |
| Rzadkie, niebieskie | 15 | 14761 | 14,761% |
| Epickie, fioletowe | 7 | 7020 | 7,020% |
| Legendarne, złote | 2 | 2079 | 2,079% |

Dodatkowe 100000 losowań bez zwykłych: `[0, 53880, 28755, 13485, 3880]`, zgodnie z wagami przeskalowanymi przez sumę 52. Te statystyki dotyczą pojedynczych losowań z resetowaną pełną pulą, a nie wszystkich kafelków oferty bez powtórzeń.

- 10000 standardowych ofert i 10000 bossowych: brak duplikatów i przekroczenia limitów, gwarancja bossa.
- 6400 ofert dla wszystkich 32 kombinacji wyczerpanych kategorii.
- Zachowane wartości maksymalnych poziomów, kompletna/1/2/0 pozostała pula.
- Rzeczywisty przepływ sceny meczu: pusta nagroda bossa wznawia grę.
- Rzeczywisty loader ustawień z podmienioną jedynie ścieżką do izolowanego pliku testowego: rekord 1234 zachowany, stare pola klątwy i stosów zignorowane i usunięte przy ponownym zapisie. Plik testowy usuwany; plik ustawień użytkownika nie był zapisywany przez fixture.
- Karty wszystkich pięciu kategorii: widoczna ramka w normal/hover/pressed/focus/disabled, delikatna poświata rzadkich/epickich, złota pulsująca energia legendarnej podczas pauzy. Animacje zatrzymane po wyborze. Istniejąca animacja wejścia zachowana.
- Pauza zawiera pięć grup; ustawienia otwierają się; statystyki końcowe zliczają rzeczywiste poziomy.
- Wynik końcowego uruchomienia graficznego: **27 kontroli, 0 błędów testów**, kod wyjścia 0. Pierwsza wersja fixture headless: 24/24; ostrzeżenie końcowego cleanup usunięte przez odczekanie drugiej klatki po zwolnieniu sceny.
- `git diff --check` dla pięciu zmienionych plików produkcyjnych: bez błędów białych znaków.

Uruchomienie:

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --log-file 'D:/Pong/pong-gra/docs/rarity-runtime.log' res://docs/test_rzadkosci.tscn
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-method gl_compatibility --windowed --resolution 1152x648 --log-file 'D:/Pong/pong-gra/docs/rarity-visual.log' res://docs/test_rzadkosci.tscn
```

Zrzuty obejrzane: [zwykłe/niepospolite/rzadkie](rzadkosci/oferta_0.png), [epickie/legendarne](rzadkosci/oferta_6.png), [pauza góra](rzadkosci/pauza_gora.png), [pauza dół](rzadkosci/pauza_dol.png), [ustawienia](rzadkosci/ustawienia.png), [koniec](rzadkosci/koniec.png). Dodatkowa faza animacji: [puls](rzadkosci/legendarne_puls.png).

Ograniczenia środowiska: edytor nie mógł zapisać konfiguracji AppData; wykrył też istniejący duplikat UID shaderów. Uruchomienie graficzne OpenGL działało, ale nie mogło utworzyć shader cache `user://`. Brak błędów parsera lub skryptów w testowanej scenie. Nie wykonywano eksportu EXE, testu multiplayera ani długiego testu balansu. Menu główne nie zawierało kategorii/klątw i nie wymagało zmian.
