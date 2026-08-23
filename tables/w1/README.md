# W-1 — dowody próby autonomii, 2026-08-23

Produkty próby opisanej w [`../../bin/w1_trial/README.md`](../../bin/w1_trial/README.md).
Wymaganie: `paper-arXiv/debs/plan-realizacji-K9b.md`, Krok 5 §W-1.

**Maszyna pomiarowa:** `pi400`, kernel `6.8.0-2049-raspi-realtime` (PREEMPT_RT),
`isolcpus=3 nohz_full=3 rcu_nocbs=3`, `/dev/shm` tmpfs 1,8 G.
**Maszyna sterująca:** host stacjonarny, `192.168.88.21`.
**Ładunek odcinka:** 9000 rund łańcucha SHA-256 nad buforem 1 MiB, `SCHED_FIFO`
priorytet 80 na CPU 3. Ładunek jest zastępczy — **żadna liczba stąd nie
występuje w artykule.**

## Przebieg właściwy — `cutoff/`

Kanał sterujący przecięty przez workera regułą `iptables DROP` na IP hosta,
odtwarzaną po każdym boocie i zdjętą dopiero przy `W1_COMPLETE`.

| | |
|---|---|
| start | 2026-08-23 20:40:32 CEST |
| koniec | 2026-08-23 20:46:29 CEST (`W1_COMPLETE`, 3/3 odcinki) |
| czas | 5 min 57 s |
| samodzielne restarty workera | **2** (po S1 i po S2) |
| sesje z maszyny sterującej w oknie | **0** |
| sondy TCP z hosta w oknie | 16 × `unreachable`, `REACHABLE` dopiero 2 s po zakończeniu |

Sumy archiwów odcinków:

| Odcinek | `runner.rc` | SHA-256 archiwum |
|---|---:|---|
| S1 | 0 | `71d160a37c43718edb15cfaf797d7bb29746ec97e2bde4200905b7effc2d0e6b` |
| S2 | 0 | `7416bd91efda9e3ef09a56a158f21ab8cbab31f996f163e8c557c105916927c9` |
| S3 | 0 | `87562aa4ffaf700decdc9c0891388d070b61be9a5ecd0f1b67944eecaa4b6be4` |

## Przebieg negatywny — `negative/`

`W1_FAIL_SEGMENT=S2`. S1 policzony i zamknięty archiwum, worker zrestartował się
sam, S2 zapisał `STOP` i zawiódł kodem 8, łańcuch odłożył
`HALT reason=stop segment=S2 rc=8` i **zatrzymał się**. `Restart=no` w unicie
zadziałał: zero pętli, zero fałszywego sukcesu.

## Osiem własności — gdzie każda jest widoczna

| # | Własność | Dowód | Stan |
|---|---|---|---|
| 1 | host startuje i odbiera, nic poza tym | `cutoff/worker-logins.txt` — ostatnia sesja z `192.168.88.21` o 20:10, przed przebiegiem; `host-probe.log` | [x] |
| 2 | usługa `systemd` wstaje po boocie | `cutoff/chain.log` — wpisy „chain start" o 20:42:19 i 20:44:20, bez udziału hosta | [x] |
| 3 | łańcuch odcinków, nie jeden proces | `cutoff/timeline.tsv`, `cutoff/worker-reboots.txt` — dwa boot-y w oknie | [x] |
| 4 | postęp w plikach | `chain.log`, `RUN_COMPLETE`, `runner.rc`, `STOP`, `HALT` | [x] |
| 5 | odbiór bezstanowy i idempotentny | `w1_collect.sh` uruchomiony dwukrotnie, wynik i kod wyjścia identyczne | [x] |
| 6 | trzy stany, nie dwa | `complete` (cutoff, kod 0), `halted` (negative, kod 4), `running`/nieosiągalny (kod 3) | [x] |
| 7 | wznowienie należy do usługi | `w1_start.sh` na zastanych artefaktach → kod 2; `systemctl start` po stopie → łańcuch podjął S1 | [x] |
| 8 | zdalny stop jednym poleceniem | `w1_stop.sh` → `is-active: inactive`, **bez `HALT`** — stop operatora nie udaje awarii | [x] |

## Co ta próba mówi, a czego nie

Sprawdzono **osprzęt autonomii**: że łańcuch przeżywa własne restarty, że nie
potrzebuje maszyny sterującej i że rozróżnia trzy stany końcowe. Odcinek liczy
~76 s, nie dobę, więc próba **nie** mówi, że konkretna kampania zmieści się
w oknie termicznym maszyny ani że jej czasy się odtworzą. Ta granica jest
zapisana w `MANIFEST.md` §5 pkt 4.

## Dwie usterki wykryte przez samą próbę

1. **`chrt` bez `RLIMIT_RTPRIO`.** Pierwszy przebieg padł natychmiast:
   `chrt: failed to set pid 0's policy: Operation not permitted`. Usługa chodzi
   jako zwykły użytkownik, a limit priorytetu RT wynosi domyślnie 0. Naprawione
   przez `LimitRTPRIO=99` w unicie plus łagodną degradację po stronie odcinka —
   maszyna, która `SCHED_FIFO` odmawia, ma liczyć dalej i **zapisać to**
   w `environment.tsv`, a nie umrzeć na polityce szeregowania, której ten rig
   i tak nie bada. Awaria była nieplanowana i przez to cenna: pokazała ścieżkę
   `HALT` na prawdziwym błędzie aparatury, zanim sprawdziłem ją celowo.
2. **Przecięcie kanału przed oknem `settle`.** Łańcuch odcinał hosta zanim
   skrypt startowy zdążył potwierdzić `is-active`, więc start raportował
   porażkę dla przebiegu, który właśnie ruszał. Okno `settle` ma dwóch odbiorców
   — człowieka, który chce zatrzymać niechciany start, i skrypt startowy — a
   przecięcie przed nim zamykało obu. Przeniesione za `settle`.
