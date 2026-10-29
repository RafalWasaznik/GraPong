# Kolizje piłki i pancerz wieżyczek - 2026-10-30

## Przyczyna i poprawka

`piłka.gd` wykonywała jeden `move_and_collide` i porzucała remainder. Boss i kryształy przesuwały StaticBody2D przez position bez prędkości powierzchni. Bramka Areny zmienia pozycje i rozmiary swoich kształtów, więc prędkość całego ciała nie opisuje ruchu krawędzi. Zwykłe przeszkody odbijały piłkę także przy oddalaniu.

Piłka teraz wykorzystuje pozostały czas klatki, maksymalnie 16 kontaktów. Warunek uderzenia i odbicie używają prędkości względnej. Kierunek uwzględnia ruch powierzchni, długość velocity pozostaje zgodna z dotychczasowymi modyfikatorami. Boss publikuje ruch korpusu i satelitów; kryształ ruch korpusu; bramka prędkości górnej i dolnej krawędzi każdego segmentu. Kontakt rozdziela niewielki, sprawdzany kolizyjnie ruch (margines 0.12 px), powiększony o konieczny ruch nadjeżdżającej powierzchni w reszcie klatki. Nie zmieniono hitboxów. Kryształ zniszczony podczas klatki jest pomijany tylko na resztę jej ruchu, zanim wykona się deferred wyłączenie kolizji.

Watchdog zlicza czas rzeczywistego braku postępu, w tym penetrację z niewielkim przesunięciem netto. Po 0.12 s próbuje lokalnego rozdzielenia po normalnej, potem stycznych. Nie losuje kierunku, nie zmienia szybkości ani nie przenosi na środek. W geometrycznie niemożliwym prześwicie (test 16 px przy średnicy 20 px) wykrywa problem, ale nie obiecuje wyjścia przez pełną przeszkodę. Limit kontaktów również świadomie zatrzymuje pozostały ruch przy patologicznej geometrii.

Diagnostyka jest domyślnie wyłączona. Tymczasowo ustaw `$env:PONG_DIAGNOSTYKA_KOLIZJI = '1'` przed uruchomieniem gry, a po próbie usuń tę zmienną. Log zawiera obiekt, normalną, prędkości, rzeczywistą/oczekiwaną drogę, wynik separacji i czas zastoju. Zwykły wolny ruch, intro i oczekiwanie na respawn nie uruchamiają tego mechanizmu.

## Wieżyczki

Dron korzysta z czterech progów: >75%, >50%, >25%, pozostałe żywe HP. Pełny pancerz nie ma trwałych pęknięć. Kolejne etapy dodają szczeliny, wyrwy segmentów, odsłonięte mechanizmy korpusu i lufy. Każde rzeczywiste trafienie inicjuje lokalny błysk, iskry i fragmenty, także bez przekroczenia progu i przy 1 HP. Etap krytyczny emituje krótkie okresowe iskry. Zachowano sylwetkę, namierzanie, ostrzeżenie, strzelanie, HP, obrażenia, nagrody i kształt kolizji. Porównanie z aktualnymi kryształami: `wiezyczki-pancerz.png`.

## Wykonana weryfikacja

Godot 4.7.2 Windows. `docs/test_kolizje_pancerz.tscn`: **61/61 kontroli PASS**, zarówno headless, jak i OpenGL Compatibility / RTX 4070. Scenariusze używają faktycznych ciał fizycznych Godota i kodu Pilka: góra/dół bossa, rzeczywiście nadjeżdżający boss, boss ze spowolnioną piłką, wędrujący kamień, nieruchoma i poruszana ściana, 6000 px/s z wykonaniem remainder, mnożnik 0.2, narożnik, ciasny prześwit i szybkie kolejne kontakty, oddalanie z penetracji, głębokie zastane nakładanie, zmieniająca kształt bramka Areny, aktywacja watchdog w niemożliwej szczelinie. Kontrole pancerza obejmują cztery progi, zachowany hitbox, trafienie w każdym etapie i przy 1 HP, czas ostrzeżenia 0.5 s, zablokowanie kierunku i interwał strzału 2.5-4 s.

Istniejąca regresja `docs/test_odbicia.tscn`: **126/126 kontroli PASS** (obie paletki, różne wysokości, 620/6000 px/s i prawa granica Nieskończonego).

Logi: `kolizje-runtime.log`, `kolizje-visual.log`, `kolizje-odbicia.log`. Headless przy zamykaniu zgłasza zasoby/ObjectDB pozostające w użyciu, również w istniejącym teście odbić; nie było błędów wykonywania skryptów ani nieudanych kontroli. Przebieg GPU zakończył się bez tych komunikatów. Edytor miał ograniczenia zapisu konfiguracji użytkownika; testy uruchomiono bez eskalacji, z APPDATA skierowanym do ignorowanego `.godot/test-user`.

```powershell
$env:APPDATA = 'D:\Pong\pong-gra\.godot\test-user'
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://docs/test_kolizje_pancerz.tscn
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://docs/test_odbicia.tscn
```

To deterministyczne próby silnika i podgląd renderowania, nie pełny ręczny run ani test sieci na dwóch komputerach. Nie wykonano nowego eksportu EXE. Nie zmieniano istniejącego `test_dron_run.gd`, który zawiera historyczne założenie 35% losowania wobec aktualnego 30%; zachowanie strzelania sprawdzono w nowym harnessie.

Dokumentacja API sprawdzona przez Context7, gałąź Godot 4.7: PhysicsBody2D.move_and_collide (safe_margin/recovery), KinematicCollision2D.get_collider_velocity oraz StaticBody2D.constant_linear_velocity.
