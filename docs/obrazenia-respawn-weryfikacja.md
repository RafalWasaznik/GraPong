# Uszkodzenia, pociski i respawn - 29.10.2026

## Zmiany

- `krysztal_run.gd`: usunięte segmenty HP; wspólne etapy z istniejącego `hp/max_hp`: >0.66, >0.33, pozostałe. Pęknięcia, odsłonięte światło, odpryski po trafieniu, łagodne wyładowanie krytyczne. Trzy losowe układy rozpadu kryształu. Wartości HP, pancerz, nagrody, wybuch i wygasanie pozostają z istniejących mechanik.
- `dron_run.gd`: mechaniczne uszkodzenia paneli i działka, zdeformowane panele, iskry i delikatne światło o przesuniętej fazie. Oddzielny rozpad: płytki, zwarcia i mała fala energetyczna, trzy warianty. Ostrzeżenie i zablokowany kierunek celowania zachowane. Strzał ma błysk, pierścień, odrzut działka, rozświetlenie rdzenia i osobny dźwięk.
- `pocisk_drona_run.gd`: zachowany świecący ślad. Analityczne przecięcie odcinka ruchu z granicami, uwzględniające promień pocisku i wewnętrzne powierzchnie poziomych ścian (10 px od ich środka). Wcześniejsza kolizja z paletką zachowuje pierwszeństwo. Flaga `zuzyty` gwarantuje pojedynczy kontakt/usunięcie.
- `efekty_meczu.gd`: punktowy błysk kontaktu, pięć cząsteczek rysowanych bez węzłów, półpierścień i krótki blask powierzchni obrócone normalną; limit 20 kontaktów, istniejąca intensywność efektów. Cztery stałe odtwarzacze z ograniczoną polifonią na magistrali `Efekty`.
- `dzwieki_gry.gd`: cztery krótkie syntetyczne efekty energetyczne (strzał, rozproszenie, awaria drona, rozpad kryształu). Przegląd dostępnych WAV i Kenney UI OGG nie wykazał dedykowanego energetycznego strzału; wykorzystana istniejąca metoda syntezy PCM, bez zewnętrznych zasobów i nowych ustawień.
- `bezpieczny_respawn.gd`: osobny typowany helper; fizyczna kontrola kształtu i pełnych torów przeciwników, również w trakcie pojawiania przed aktywacją kolizji. Rezerwacja całego koła intro z marginesem 10 px. Wolny środek jest sprawdzany przed tworzeniem siatki. Zajęty środek: najbliższy bezpieczny punkt próbkowanej siatki 8 px w centralnym prostokącie 320x360 px.
- `piłka.gd`: bezpieczny reset tylko przy aktywnym RunState; rewalidacja intro. Awaryjny skończony skan całej areny (16 px) z rzeczywistym promieniem piłki i stacjonarnym intro. Przy zupełnym braku przestrzeni piłka czeka, widać krótki komunikat, przeciwnicy pozostają aktywni i wygasają normalnie. Ponowienia co 0.5 s, po 44 próbach co 2 s; brak busy loop i trwałego wyłączenia odzyskania miejsca. Podczas oczekiwania odświeżana istniejąca nietykalność gracza. Brak utraty życia lub zakończenia biegu z powodu zajętego środka.
- `przebieg_meczu.gd`: jedynie aktualizacja istniejącego tooltipu, który opisywał usunięte segmenty HP.
- `docs/test_obrazenia_respawn.gd`, `.tscn`: powtarzalny test na prawdziwej scenie gry.
- `docs/obrazenia-etapy.png`: zrzut z działającego renderera; górny rząd kamienie, dolny drony; od lewej sprawny, uszkodzony, krytyczny.

## Wykonane sprawdzenia

Godot **4.7.2 stable**, `D:/Godot/Godot_v4.7.2-stable_win64_console.exe`. APPDATA i LOCALAPPDATA przekierowane do `.godot/test-user`, bez eksportu EXE.

1. Import edytora headless: bez błędów skryptów; zgłoszony istniejący duplikat UID dwóch shaderów `glow_effect_2d.gdshader` i `2D Outline Shader.gdshader`.
2. Istniejący `docs/test_dron_run.tscn`: **21 PASS, 0 FAIL**. Losowanie/limit dronów, ostrzeżenie, kierunek strzału, trafienie gracza, tarcza, dash/nietykalność, jedna strata życia, punktacja, regeneracja, pauza, wybór ulepszeń, cleanup i klasyczny tryb. Przy wyjściu tego starego zestawu: ostrzeżenie o dwóch instancjach ObjectDB i jednym zasobie.
3. Nowy `docs/test_obrazenia_respawn.tscn`, uruchomiony graficznie OpenGL Compatibility na RTX4070: **60 PASS, 0 FAIL**, bez błędów i ostrzeżeń w końcowym uruchomieniu. HP100 i HP6 dla obu typów, reakcja w tym samym etapie, wszystkie trzy warianty rozpadu obu typów, zajęty środek/grupy1/4/8 z dronami, zachowanie liczby przeciwników, pełny tor wanderera, fallback poza centrum, odrzucenie pozycji poza areną, całkowite zapełnienie i odzyskanie po przekroczeniu44 prób, wolny środek, błysk/bus/audio PCM, cztery normalne i dokładne punkty kontaktu, jednokrotność, runtime start trybów bot/2graczy/arena.
4. Zrzut `obrazenia-etapy.png` obejrzany: brak kresek HP, odmienne uszkodzenia i poprawne polskie etykiety. `git diff --check`: bez błędów białych znaków.

Uruchomienie:

```powershell
$env:APPDATA = Join-Path $PWD '.godot/test-user/AppData'
$env:LOCALAPPDATA = Join-Path $PWD '.godot/test-user/LocalAppData'
& 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe' --path . --windowed --resolution 1280x720 --rendering-method gl_compatibility docs/test_obrazenia_respawn.tscn --log-file .godot/obrazenia-test.log
```

## Granice weryfikacji

Testy potwierdzają runtime i renderowanie, tworzenie strumieni audio i przypisanie do istniejącej magistrali; nie zastępują odsłuchu na urządzeniu użytkownika. Nie wykonano pełnego ręcznego przejścia menu/ustawień/wyników ani meczu online na dwóch komputerach. Start innych trybów i zachowanie mechanik dronów sprawdzono lokalnie. Najbliższy punkt jest wybierany spośród bezpiecznych próbek siatki, nie jest analitycznym minimum ciągłej przestrzeni. Trwale fizycznie wypełniona cała arena nie ma legalnego punktu - pozostaje bezpieczne odroczenie, które odzyskuje start po zwolnieniu miejsca.

Końcowe powtórzenie na docelowym rendererze Mobile/D3D12, RTX 4070: 60 PASS, 0 błędów, bez ostrzeżeń. Skorygowano nazwę trybu w teście z ai na rzeczywisty bot. Log: .godot/obrazenia-mobile.log.
