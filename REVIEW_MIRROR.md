# Reviewer mirror specification

This file is the pre-submission recipe for the double-anonymous artifact.
Creating the public mirrors is deliberately a separate, authenticated action:
Anonymous GitHub requires a GitHub sign-in. The mirror ID is chosen by the
author rather than randomized -- what is typed into the form is what appears in
the URL -- so the paper can carry the addresses before the mirrors exist. What
must not precede the mirrors is the availability claim, which waits for the
acceptance trial below.

## Sources and revisions

Create six read-only mirrors, each pinned to the revision below. The
documentation correction that held the entry point landed on 2026-08-26, so
nothing blocks its mirror any more.

| Role | Source repository | Revision to mirror | Mirror ID |
|---|---|---|---|
| Artifact entry point | `rdb-artifact` | HEAD at mirror creation -- see below | `retractordb-artifact` |
| Engine snapshot | `retractordb` | `16c516f9eb76c473d5ff8510a2a812b8c23a893d` | `retractordb-engine` |
| Experiments and data | `rdb-experiment` | `84fee502acb77b111b0f83bb07a2104b7477e560` | `retractordb-experiment` |
| Documentation | `documentation-rdb` | `00e571783c232e635bce924e294b99bd43033919` | `documentation-rdb` |
| Engine bundles for `--remeasure` | `rdb-binaries` | `29e86204339b833cc42e01bd7cdb0f85d0825210` | `retractordb-binaries` |

The bundles mirror carries only the `.tar.gz` engine bundles of `MANIFEST.md` §7, their `build-info.txt` and `SHA256SUMS`. It serves the archives byte for byte, as it serves the raw archives of the experiment mirror, and the redaction never reaches inside them; `bin/build_bundle.sh --terms` checks every binary for the identifying terms before the bundles are committed. It is the one mirror not created on 2026-08-26: it was created on 2026-11-09 and expires on 2027-08-25, like the others.

The source mirrors were created on 2026-08-26 and expire on 2027-08-25. One more, of the Polish documentation `dokumentacja-rdb`, existed from 2026-08-26 to 2026-11-09; it was removed to make room for the bundles mirror within the limit of five repositories of the service's free plan, and the Polish documentation left the package (`MANIFEST.md` §1, *Removal of 2026-11-09*).
The mirror ID is chosen, not generated: it is the repository name, unless that
name does not say what the repository is, in which case it takes a
`retractordb-` prefix.

The entry point cannot name its own revision in the commit that names it, so it
is pinned to whatever this repository's HEAD is when its mirror is created, and
that SHA is written into `MIRROR_TRIAL.md` afterwards. The record is one commit
behind the mirror by construction. Nothing is lost: `verify_pins.sh` checks the
source repositories and never asks which revision `rdb-artifact` itself is,
because that is where the script lives. The entry point's pin is a record, not a
check.

**Automatic updates stay off on every mirror, and not only for pinning.** A
mirror that follows a branch re-anonymizes each new commit against the term list
as it stood yesterday, and publishes the result before anyone has looked at it.
The redaction is only as good as that list: the 2026-08-26 run found a preprint
title prefix and a shell prompt split across SVG elements, both only because
someone read the affected files. A following mirror would ship the next such
case straight to reviewers.

The historical H9 measurement revisions remain the pair already recorded in
`MANIFEST.md`: engine
`856ee54b0f4ab450a6b61e3c08e045f404a79488` and experiment
`81bf4bea00efb922678862c90462fb3c0dfe5fda`.

## Redaction configuration

Use the same replacement rules for all six mirrors. At minimum, redact the
author's name in accented and ASCII forms, GitHub account, email addresses,
ORCID, personal domains, affiliation, local absolute paths, and any preprint
title that resolves to the author. The term field takes regular expressions, so
escape the dots in addresses and identifiers. Leave all four display options
off, leave automatic branch updates off, pin a commit rather than a moving
branch and set expiry beyond the review period.

Turning off image display removes image files from the downloadable archive as
well as from the rendered view -- measured on the English documentation mirror:
153 tracked files against 85 in the archive, the difference being exactly its 68
images. Binary archives are untouched: a `raw.tar.gz` pulled from the experiment
mirror matches its manifest SHA-256 byte for byte, so section 4 of
`verify_pins.sh` has something to check.

The form has no file-exclusion field, so a mirror carries the whole pinned tree
and differs from it only by redaction and by that image removal. Anything that must not be published has
to be handled by a term, or by a commit -- and a commit changes the pin.
Full operational detail, including the term list this artifact was redacted
with, is in `paper-arXiv/debs/procedura_anonimizacji.md`.

Inspect the rendered mirror and its downloadable archive for every configured
term. Automatic owner redaction is not enough: manifests and shell scripts
contain source URLs, and prior-work citations can contain author identifiers.

Keep the five repository names off the term list. Section 0 of
`bin/verify_pins.sh` (and, for `rdb-binaries`, `bin/reproduce_remeasure.sh`) finds each pin by grepping `MANIFEST.md` for a table row
that begins with the repository name and `checkout.sh` for a variable named
after it; redacting those names leaves the pins undeclared and step 4 below
fails on a mirror that is otherwise correct.

The URL column is a different matter and was misjudged once. Link redaction
replaces the whole address with `XXXX`, not just the account name inside it, so
a section 0 pattern anchored on `\`https` found nothing when the checker ran
from the artifact mirror -- which is how a reviewer runs it. Fixed 2026-08-26 by
anchoring on the repository name alone; verified against the redacted manifest.

## Paper integration

After all mirrors exist, replace the placeholders in
`paper-arXiv/debs/references.bib` with the randomized URLs. Cite the artifact
entry point plus the experiment mirror; expose the engine and the documentation
mirror from the entry point. Keep the full revisions visible in the anonymized
manifest. Do not claim availability before the acceptance trial below passes.

## Unauthenticated acceptance trial

Run the trial in a browser profile and shell with no GitHub or Anonymous GitHub
session:

1. Open every URL exactly as printed in the generated paper.
2. Download all six archives and verify that no request returns `401`.

   **The experiment archive cannot be downloaded whole, and the step is run
   per file there.** Measured on 2026-09-13: the service builds the ZIP as a
   stream at about 2.2 MB/s and cuts it off after about 220 s, with no central
   directory — the experiment tree (613 MB) ends after 1,107 of 4,346 files.
   Single files come from `/api/repo/<id>/file/<path>`: binary files of any size
   byte for byte (a 45 MB W8 part in 5 s), but a **text** file of about 1.2 MB
   or more returns HTTP 502. The nineteen raw K24-series CSV files of that size
   therefore also exist as `<name>.csv.gz` beside the original, and a reviewer
   takes those. Completeness is checked by listing directories through
   `/api/repo/<id>/files/?path=` against `git ls-tree` of the pinned revision
   (the listing reports pre-redaction sizes, so it proves presence, not
   redaction). The listing endpoint is rate-limited per address: a burst of
   about a hundred requests draws HTTP 429 with a `Retry-After` of up to nine
   minutes, so pace it.
3. Search paths and text for all configured identifying terms.
4. Arrange the extracted directories as siblings under one workspace, named
   `retractordb`, `rdb-experiment` and `documentation-rdb`,
   and run the mirror mode of the pin checker from the artifact entry point:

   ```bash
   RDB_MIRROR=1 RDB_WORKSPACE=<workspace> ./bin/verify_pins.sh snapshot
   ```

   Expect `RESULT: declarations and archives match; revision identity NOT
   verified`, six `SKIP` lines, and exit status 0. Mirror mode exists because a
   mirror is a snapshot without `.git`: sections 1 to 3 ask git which commit a
   directory is, which a redacted copy cannot answer even in principle, since
   the redaction rewrites file contents and no hash of it can equal the pinned
   one. Without `RDB_MIRROR=1` the script stops at the first missing `.git`,
   which is the correct behaviour for a broken clone and was, until 2026-08-26,
   the reason this step could not be run at all.

   A mismatch in section 4 is the finding to watch for: the raw archives are
   binary and must survive the mirror byte for byte. If one of them fails its
   SHA-256, the anonymizer rewrote a binary file, and the archives have to be
   excluded from redaction before the mirror is usable.

5. Reproduction is run on the mirror. `bin/reproduce_analytic.sh` alone reads stored products with `git show HEAD:<path>` and detects regeneration diffs with `git status`, so it has no meaning on a snapshot without history; `bin/review.sh` is the path that needs none. From an empty directory, extract the archive of `retractordb-artifact` from step 2 and run `bash bin/review.sh` there, in a shell whose `PATH` has no `git` (the archive drops the executable bit, hence `bash`). It fetches every input listed in `INPUTS.tsv` singly from the experiment mirror, checks each against the pin, regenerates the analytic groups and writes `review-report.md`. Expect exit status 0, `VERDICT PASS`, every input matching `INPUTS.tsv`, seven groups `OK` with their stored products identical, `ecg` `SKIP` with its reason, and every `COUNT` line as expected. Then run `bin/review.sh --workspace <workspace>` on clones made by `bin/checkout.sh` at the SHAs pinned above: it must give the same verdict and the same counts. `REPRODUCE.md` §3, *Without git: from the reviewer mirror*, describes the run and its checks.

   Then, from the same extracted archive and with the same `PATH`, run `bash bin/review.sh --remeasure` once on an x86_64 machine and once on an aarch64 machine, each a Linux with glibc 2.38 or later and with no other `xretractor` running. It fetches the inputs of `REMEASURE.tsv` from the experiment, engine and bundles mirrors, checks the four bundles of its architecture against `MANIFEST.md` §7 and measures the deterministic quantities again. Expect exit status 0, `VERDICT PASS`, seven groups `OK` and every `COUNT` line as expected; the run takes about 70 minutes. Record its `VERDICT`, `INPUTS` and `FETCH` lines, elapsed time and platform. `REPRODUCE.md` §3, *Without a compiler: remeasuring the deterministic quantities*, describes the groups.

6. Record the mirror IDs, pinned revisions, UTC time, command transcript, and
   generated checksums in the submission handoff, together with the six skipped
   checks from step 4 and where they were verified instead. The record lives in
   [`MIRROR_TRIAL.md`](MIRROR_TRIAL.md); the 2026-08-26 run is already in it.

Only after all six steps pass may the paper say that the artifact is available
to reviewers through an anonymized mirror. The claim that step 4 supports is
availability and integrity of the delivered bytes. The claim that step 5 supports is that a reviewer can regenerate the analytic products from the mirrors alone, without git or a clone; its run from the archive of the re-pointed `retractordb-artifact` mirror passed on 2026-11-08 (*Seventh trial*). The `--remeasure` run of step 5 supports a third claim: that a reviewer can measure the deterministic quantities again from the mirrors alone, without git or a compiler, on x86_64 and on aarch64. Its run from the mirrors alone, the archive of the re-pointed `retractordb-artifact` mirror with the bundles of `retractordb-binaries`, passed on 2026-11-09 on both platforms (*Eighth trial*).

## Moving a pin

A pin moves forward only, one source repository at a time, and the package must not declare a revision its mirror does not serve. `bin/move_pin.sh` does the local part; the mirror and the trial stay manual. The paper pin is an annotated tag, `artifact/594b` since 2026-11-09; it moves to a new annotated tag, never by re-tagging and never with this procedure, and the earlier tags stay as the record of earlier trials.

1. **Dry run.** Copy the term list of `paper-arXiv/debs/procedura_anonimizacji.md` (section 4) to a file outside every repository and run `RDB_REDACTION_TERMS_FILE=<file> bin/move_pin.sh <repository> <new-sha>`. It needs a local clone of the source repository next to this one (or `RDB_SOURCES`) holding both revisions. It must end with `RESULT: dry run, 0 finding(s), 0 skipped`. A text file of 1.2 MB or more without a `.gz` copy is a finding: fix it by a commit in the source repository and start again from the new SHA. Every file it lists under *identifying terms* goes on the search list of step 4; one that is also an input of the analytic path is named with a `note`, because the mirror will serve it redacted and `INPUTS.tsv` will give it the `masked` check.
2. **Apply, commit, push** - only when step 3 can follow in the same session. `RDB_REDACTION_TERMS_FILE=<file> bin/move_pin.sh <repository> <new-sha> --apply` writes the four declarations of the pin (`MANIFEST.md` section 1, `bin/verify_pins.sh`, `bin/checkout.sh`, the table in *Sources and revisions* above), clones a fresh pinned workspace into a temporary directory and runs `verify_pins.sh snapshot` there. It then renews `INPUTS.tsv` with `bin/make_inputs.sh`: `reproduce_analytic.sh` runs over that workspace under `strace`, which records the inputs actually read and the counts to expect, and the new list replaces the old one only after `bin/review.sh` passes with it on a simulated mirror of the new pins. Products stay outside this repository. `--apply` needs the terms file and `strace`, and refuses to start while any of the five files has uncommitted changes. Commit those five files together with a paragraph in `MANIFEST.md` section 1 saying what the new revision adds, and push.
3. **Re-point the mirrors** (external, by the mirror owner): the mirror of the moved repository to `<new-sha>` and `retractordb-artifact` to the commit of step 2. Automatic updates stay off and the term list stays as it is. `/api/repo/<id>/options` reports the `lastUpdateDate` that confirms the move.
4. **Acceptance trial on the delta.** Steps 1, 4 and 5 of the trial above run in full; step 5 runs `bash bin/review.sh` against the live mirrors, so it fetches the renewed `INPUTS.tsv` of step 2. Steps 2 and 3 are narrowed to what moved: fetch every file of the delta singly through `/api/repo/<id>/file/<path>`, check that it equals its blob at the new pin except for redaction markers and contains none of the configured terms, and list the directories holding the delta through `/api/repo/<id>/files/?path=` against `git ls-tree` of the new pin, pacing the requests for the rate limit.
5. **Record** a new trial section in [`MIRROR_TRIAL.md`](MIRROR_TRIAL.md), as the fourth trial did for `d319e88`: the pins, the `lastUpdateDate` of each re-pointed mirror, the verdict of each step and the delta it covered, and from step 5 the `VERDICT`, `INPUTS` and `FETCH` lines of `bin/review.sh` with its elapsed time.

Between steps 2 and 3 the package declares a revision its mirror does not serve yet; that window is why the two steps belong to one session.

`bin/move_pin.sh` renews `INPUTS.tsv` but not `REMEASURE.tsv`, which `bin/fetch_mirror.sh` then refuses as generated for the old pins. Renew it in step 2 with `RDB_REDACTION_TERMS_FILE=<file> bin/make_inputs.sh --remeasure --workspace <workspace>` on clones of the new pins and a clone of `rdb-binaries`. When the engine pin moves, rebuild the bundles first: `bin/build_bundle.sh --arch x86_64 --terms <file>` and the same with `--arch aarch64`, from a clone of the new engine pin, commit them to `rdb-binaries`, and update its pin in section 1 of `MANIFEST.md` and in the table above, and the sums in §7. The bundles mirror is then re-pointed in step 3 with the others.
