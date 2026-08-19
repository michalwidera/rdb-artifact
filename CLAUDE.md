# CLAUDE.md — rdb-artifact

Pakiet artefaktów do artykułu o RetractorDB. Repozytorium **cienkie**: manifest,
mapa kampanii, instrukcja odtworzenia i skrypty. Buduje je krok **K9b** planu
badawczego (`paper-arXiv/debs/plan-realizacji-K9b.md`) — ten plan jest źródłem
normatywnym dla zakresu i kolejności prac.

## Uprawnienia asystenta — odstępstwo od reguły ogólnej

**W tym repozytorium asystent commituje i wypycha samodzielnie, bez pytania.**
Decyzja człowieka z 2026-08-19. Odstępstwo dotyczy **wyłącznie `rdb-artifact`**
i wynika z jego charakteru: nie ma tu kodu silnika ani danych badawczych, treść
jest wtórna wobec przypięć, a każda zmiana jest odwracalna commitem.

W pozostałych repozytoriach obowiązuje reguła podstawowa: na gałęzi głównej
commituje i wypycha **człowiek**, po przejrzeniu diffu. Dotyczy to `retractordb`,
`rdb-experiment`, `paper-arXiv` i obu repozytoriów dokumentacji.

Wyjątki, których to uprawnienie **nie** obejmuje, bo są nieodwracalne albo
zewnętrzne: nadanie DOI, upublicznienie repozytorium, kasowanie tagów `campaign/*`,
`push --force`.

## Zasady treści

1. **Żadnej kopii danych badawczych.** Dane zostają w `rdb-experiment`, przypięte
   po SHA. Kopia byłaby piątym miejscem, które się rozjeżdża.
2. **Nazwa gałęzi nigdy nie jest identyfikatorem wersji.** Wyłącznie pełne,
   czterdziestoznakowe SHA albo tag adnotowany `campaign/*`.
3. **Nie zgadywać przypięć.** Rewizja pochodzi z `PIN.md`/`manifest.md` katalogu
   kampanii albo z tagu. Gdzie źródła brak — wpisać „nieznana" i wymienić
   w granicach, nigdy domysł.
4. **Pozycje niegotowe znakować `[K9b/Krok N]`**, żeby czytelnik odróżniał lukę
   od przeoczenia.
5. **Skrypty w `bin/` mają działać w chwili commitowania.** Nie zostawiać
   szkieletów; brakujący tryb opisać w `REPRODUCE.md`, a nie pustym plikiem.

## Higiena tekstu

Obowiązuje ta sama kontrola watermarków co w repozytorium kodu — przed każdym
commitem, tryb `--aggressive --strip-emoji-glue` dla `.sh` i `.cff`.
Komentarze w skryptach bez polskich znaków diakrytycznych, spójnie z konwencją
tagów `campaign/*`.
