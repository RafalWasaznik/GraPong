# Zasady repozytorium

## Struktura projektu i organizacja modułów

PongGra korzysta z Godot 4.7 i GDScript. Skrypty `.gd` i sceny `.tscn` w katalogu głównym zawierają rozgrywkę i interfejs, a `project.godot` określa scenę startową i autoloady. Grafiki są w `assets/`, część zasobów audio leży w katalogu głównym. `.godot/` zawiera wygenerowane dane edytora, a `PONG/` wyeksportowane buildy.

- `scena_główna.gd` składa mecze, a `przebieg_meczu.gd` obsługuje punktację i wyniki.
- `arena_manager.gd` zarządza zdarzeniami Areny, a `arena_katalog.gd` definiuje ich katalog.
- `siec.gd` i `obsluga_online.gd` obsługują połączenia i synchronizację.
- `menu*.gd`, `ustawienia*.gd` i `ekran_konca.gd` implementują przepływy menu.

Przy łączeniu tych modułów używaj istniejących typowanych API i obiektów danych.

## Budowanie, testy i komendy developerskie

Uruchamiaj z katalogu głównego repozytorium, mając plik wykonywalny Godot 4.7 dostępny jako `godot`:

```powershell
godot --editor --path .
godot --path .
godot --headless --path . --export-release "TestEksportu" "PONG/Pong.exe"
```

Kolejno: otwierają edytor, uruchamiają skonfigurowaną scenę startową i eksportują grę na Windows. Eksport wymaga pasujących szablonów eksportu. Istniejące pliki wykonywalne nie zawierają późniejszych zmian w kodzie, więc przed sprawdzeniem buildu wyeksportuj go ponownie.

## Styl kodu i konwencje nazewnicze

W GDScript wcinaj tabulatorami. Trzymaj się istniejących polskich identyfikatorów: `snake_case` dla plików, metod i zmiennych, `PascalCase` dla nazwanych klas, `UPPER_SNAKE_CASE` dla stałych. Zachowuj istniejące nazwy plików z polskimi znakami. Preferuj jawne typy, sygnały i bezpośrednie wywołania metod zamiast słowników i wywołań opartych na stringach. Nie ma skonfigurowanego formatera ani lintera.

## Zasady testowania

Nie ma zautomatyzowanych testów ani wymaganego pokrycia. Nie uruchamiaj testów ani gry, chyba że wyraźnie o to poproszono. W raportach rozróżniaj przegląd kodu, weryfikację w działającej grze i test multiplayera na dwóch komputerach.

Gdy poproszono o weryfikację, sprawdź dotknięte tryby i pełne przepływy interfejsu, w tym pauzę i ustawienia pod Escape oraz wyniki meczu. Weryfikacja online wymaga dwóch komputerów, a samo lokalne sprawdzenie kodu nie dowodzi, że całość działa end-to-end.

## Zasady dotyczące commitów i pull requestów

Ostatnie commity mają krótkie polskie opisy, np. `Małe poprawki składni`, bez obowiązkowego prefiksu. Pisz konkretnie, co zmienia się w zachowaniu. PR powinien wyjaśniać zmianę, których trybów dotyczy, jaką weryfikację wykonano lub pominięto, i linkować powiązane issues. Przy zmianach interfejsu dołącz zrzuty ekranu.

## Ograniczenia projektu

Zachowuj lokalne zmiany. Utrzymuj styl Neon Arcade powściągliwy i spójny w menu. Gra online używa hosta jako autorytetu (ENet, UDP `24567`), a zdalne połączenia idą przez Tailscale. Przy niekompatybilnych zmianach formatu sieciowego zwiększ wersję schematu odpowiedniego pakietu.

## Dokumentacja bibliotek

Przy pytaniach o API Godota i GDScript użyj context7, zamiast polegać na pamięci modelu.

Przy pytaniach o API Godota i GDScript użyj context7, zamiast polegać na pamięci modelu.
Zmiany w menu wprowadzaj we wszystkich ekranach naraz: menu główne (`menu.gd`), pauza i ustawienia pod Escape (`menu_pauzy.gd`) oraz ekran końca i statystyk (`scena_główna.gd`).
W etykietach interfejsu używaj zwykłego ` - ` zamiast długiego myślnika.