# W-1 — próba zgodności autonomii przebiegu

Ten katalog sprawdza **empirycznie** wymaganie W-1 z
`paper-arXiv/debs/done/plan-realizacji-K9b.md`, Krok 5: *przebieg wielodniowy nie może
wymagać, żeby maszyna sterująca stała włączona przez cały ten czas*.

Kryterium W-1 jest empiryczne, nie deklaratywne. Zapis „skrypt nie wymaga hosta"
bez próby nie liczy się jako spełnienie — ta sama zasada co przy kontroli
negatywnej bramki SHA.

## Czym to jest, a czym nie jest

To jest próba **osprzętu**, nie pomiar. Ładunek odcinka to deterministyczny
łańcuch skrótów przypięty do wydzielonego CPU pod `SCHED_FIFO`. Odtwarza
**kształt** odcinka pomiarowego — ograniczona praca, artefakty na dysku, jawny
status, archiwum zamknięte sumą kontrolną — i nic poza tym. **Żadna liczba
stąd nie występuje w artykule.**

Wzorzec nie jest wymyślony na nowo. Jest przeniesiony ze sprawdzonego w boju
`rdb-experiment/results_20260814_K26v3/`:

| Tutaj | Odpowiednik K26v3 P8 |
|---|---|
| `w1_install_worker_service.sh` | `install_worker_service.sh` |
| `w1_run_chain.sh` | `run_matrix_chain.sh` |
| `w1_run_segment.sh` | `run_matrix_family.sh` |
| `w1_start.sh` | `start_matrix_p8.sh` |
| `w1_collect.sh` | `collect_p8_archives.sh` |

Różnica jest jedna i celowa: odcinek liczy minuty zamiast doby, więc cały
łańcuch trzech odcinków z dwoma restartami mieści się w kwadransie. Dzięki temu
własności 1–8 dają się sprawdzić w jednej sesji, a nie w trzy doby.

## Osiem własności W-1 i miejsce, w którym każda jest widoczna

| # | Własność | Mechanizm | Dowód w plikach |
|---|---|---|---|
| 1 | host startuje i odbiera, nic poza tym | `w1_start.sh` kończy się i oddaje maszynę | `worker-logins.txt` — zero sesji z hosta w oknie przebiegu |
| 2 | przebieg prowadzi `systemd` na workerze | unit z `WantedBy=multi-user.target` | `chain.log` — wpisy po każdym boocie |
| 3 | łańcuch odcinków, nie jeden proces | `systemctl --no-block reboot` między odcinkami | `worker-reboots.txt`, `timeline.tsv` |
| 4 | postęp w plikach, nie w pamięci procesu | `chain.log`, `RUN_COMPLETE`, `runner.rc`, `STOP`, `HALT` | te pliki |
| 5 | odbiór bezstanowy i idempotentny | `w1_collect.sh` niczego nie zapisuje na workerze | powtórzone wywołania dają ten sam wynik |
| 6 | jednoznaczny sygnał zakończenia, trzy stany | `W1_COMPLETE` / brak / `HALT` | `w1_collect.sh` wypisuje `STATE:` |
| 7 | wznowienie należy do usługi, nie do skryptu startowego | `w1_start.sh` odmawia przy zastanych artefaktach | kod 2 z komunikatem o `systemctl start` |
| 8 | zdalny stop jednym poleceniem | `w1_stop.sh` | `systemctl is-active` po stopie |

Własność 6 wymaga **trzech** stanów, więc trzeci sprawdza się osobnym przebiegiem
negatywnym: `W1_FAIL_SEGMENT=S2` każe odcinkowi zapisać `STOP` i zawieść.
Łańcuch ma wtedy odłożyć `HALT` i **zatrzymać się**, a nie zapętlić —
`Restart=no` w unicie jest po to.

## Przecięcie kanału sterującego

Własność 1 mówi, że host może być wyłączony. Sprawdzenie tego przez odłożenie
rąk od klawiatury dowodzi tylko, że nikt nie sięgnął — nie że sięgnąć nie było
trzeba. Dlatego kanał zostaje **przecięty**, jednym z dwóch sposobów:

* **po stronie hosta** — reguła `DROP` na IP workera; wymaga `sudo` bez hasła na
  hoście. Wtedy `CUT_HOST_IP` zostaje puste;
* **po stronie workera** — `CUT_HOST_IP=<ip hosta>`; łańcuch zakłada `DROP` po
  każdym boocie, w tym samym miejscu, w którym ustawia governor.

Wariant workera ma dwa niezależne wyjścia awaryjne, bo zamknięcie się w maszynie
pomiarowej jest jedyną awarią, na którą ten rig nie może sobie pozwolić:
reguły **nie są trwałe**, więc każdy reboot sam przywraca łączność, a ponadto
przejściowy timer `systemd-run --on-active` zdejmuje je nawet wtedy, gdy łańcuch
zginie przed własnym sprzątaniem. Plik `cutoff-deadline` ustala termin, po
którym łańcuch przestaje regułę odtwarzać.

Wyłączenie hosta fizycznie jest oczywiście mocniejsze i nie wymaga żadnego
z tych dwóch wariantów. Rig ich wtedy nie potrzebuje — `CUT_HOST_IP` puste,
`sudo` nietykane.

## Przebieg

```bash
# 1. próba negatywna — trzeci stan własności 6
W1_FAIL_SEGMENT=S2 ./w1_start.sh
./w1_collect.sh                      # STATE: halted, kod 4

# 2. sprzątnięcie po próbie negatywnej (świadome, nie automatyczne)
ssh michal@192.168.88.13 'sudo -n systemctl disable k9b-w1.service; rm -rf ~/w1_out ~/w1_archives ~/w1_control'

# 3. przebieg właściwy z przeciętym kanałem
CUT_HOST_IP=192.168.88.21 ./w1_start.sh
./w1_collect.sh                      # STATE: worker unreachable, kod 3 — to jest oczekiwana odpowiedź
# ... po zakończeniu ...
./w1_collect.sh                      # STATE: complete, kod 0
```

Dowody lądują w `rdb-artifact/tables/w1/`.

## Kody wyjścia `w1_collect.sh`

| Kod | Znaczenie |
|---|---|
| 0 | `complete` — łańcuch skończony, archiwa odebrane |
| 3 | `running` albo worker nieosiągalny — przebieg trwa |
| 4 | `halted` — zatrzymany z błędem, czeka na decyzję człowieka |
