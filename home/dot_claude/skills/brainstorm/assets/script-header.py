"""vN : <subject of this round> (FEEDBACK-<DELIVERABLE>-v<N-1>).

Question posee : <the question, with the numbers it was asked with>

Methode : <what is computed and how>. Reutilise strictement la methode de
<previous_script.py> ; seul <what changed> change.

Sorties :
  out_<subject>.csv       - <one line per output file: what a row is>
  out_<subject>_roi.csv   - <...>
"""
import csv, os

# Paths are RELATIVE to this script — the folder must survive being cloned
# elsewhere. Never hardcode D:\... here.
HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "..", "<data-folder>", "<input>.csv")
OUT = HERE

# --- Hypotheses --------------------------------------------------------------
# Every constant that a later round might revisit, named and commented with its
# unit and its source. These are what get challenged at v5.
PRIX_KWH = 0.18          # EUR/kWh TTC, releve du <date>

# --- Computation -------------------------------------------------------------

# --- Output ------------------------------------------------------------------
# Write CSV, and print the headline figures so the deliverable can quote them
# without re-running. The CSV remains the source of truth.
with open(os.path.join(OUT, "out_<subject>.csv"), "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["scenario", "..."])
