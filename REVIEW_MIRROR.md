# Reviewer mirror specification

This file is the pre-submission recipe for the double-anonymous artifact.
Creating the public mirrors is deliberately a separate, authenticated action:
Anonymous GitHub requires a GitHub sign-in. The mirror ID is chosen by the
author rather than randomized -- what is typed into the form is what appears in
the URL -- so the paper can carry the addresses before the mirrors exist. What
must not precede the mirrors is the availability claim, which waits for the
acceptance trial below.

## Sources and revisions

Create five read-only mirrors, each pinned to the revision below. The
documentation correction that held the entry point landed on 2026-08-26, so
nothing blocks its mirror any more.

| Role | Source repository | Revision to mirror | Mirror ID |
|---|---|---|---|
| Artifact entry point | `rdb-artifact` | HEAD at mirror creation -- see below | `retractordb-artifact` |
| Engine snapshot | `retractordb` | `8aa4ee2f18a003fcf55db8a4f810c720094e1b1a` | `retractordb-engine` |
| Experiments and data | `rdb-experiment` | `4ca09c56713757b480eb6fda4d6718506a9153fd` | `retractordb-experiment` |
| Canonical documentation | `dokumentacja-rdb` | `07c89acd493500be248836fbadbabbdf4cc0eadd` | `dokumentacja-rdb` |
| English documentation | `documentation-rdb` | `5b57ebd82093ecfd71954aa3896faab791f42886` | `documentation-rdb` |

The four source mirrors were created on 2026-08-26 and expire on 2027-08-25.
The mirror ID is chosen, not generated: it is the repository name, unless that
name does not say what the repository is, in which case it takes a
`retractordb-` prefix.

The entry point cannot name its own revision in the commit that names it, so it
is pinned to whatever this repository's HEAD is when its mirror is created, and
that SHA is written into `MIRROR_TRIAL.md` afterwards. The record is one commit
behind the mirror by construction. Nothing is lost: `verify_pins.sh` checks the
four source repositories and never asks which revision `rdb-artifact` itself is,
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

Use the same replacement rules for all five mirrors. At minimum, redact the
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
`bin/verify_pins.sh` finds each pin by grepping `MANIFEST.md` for a table row
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
entry point plus the experiment mirror; expose the engine and both documentation
mirrors from the entry point. Keep the full revisions visible in the anonymized
manifest. Do not claim availability before the acceptance trial below passes.

## Unauthenticated acceptance trial

Run the trial in a browser profile and shell with no GitHub or Anonymous GitHub
session:

1. Open every URL exactly as printed in the generated paper.
2. Download all five archives and verify that no request returns `401`.
3. Search paths and text for all configured identifying terms.
4. Arrange the extracted directories as siblings under one workspace, named
   `retractordb`, `rdb-experiment`, `dokumentacja-rdb` and `documentation-rdb`,
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

5. Reproduction is verified on a clone, not on the mirror.
   `bin/reproduce_analytic.sh` reads stored products with `git show HEAD:<path>`
   and detects regeneration diffs with `git status`, so it has no meaning on a
   snapshot without history. Clone each source at the SHA pinned above, run
   `bin/verify_pins.sh snapshot` (no `RDB_MIRROR`) and then
   `bin/reproduce_analytic.sh --workspace <workspace>`, and compare all
   regenerated tables with the preserved products. What the mirror has to
   deliver is the same bytes as that clone; step 4 is what checks it.

6. Record the mirror IDs, pinned revisions, UTC time, command transcript, and
   generated checksums in the submission handoff, together with the six skipped
   checks from step 4 and where they were verified instead. The record lives in
   [`MIRROR_TRIAL.md`](MIRROR_TRIAL.md); the 2026-08-26 run is already in it.

Only after all six steps pass may the paper say that the artifact is available
to reviewers through an anonymized mirror. The claim that step 4 supports is
availability and integrity of the delivered bytes. It is not a claim that a
reviewer can reproduce the analysis from the mirror alone: today that needs a
clone, and making the analytic path work without history is an open item.
