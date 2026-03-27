import argparse
import csv
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Counts:
    total: int
    tp: int  # genuine accepted
    fn: int  # genuine rejected
    fp: int  # imposter accepted
    tn: int  # imposter rejected


def _norm(s: str | None) -> str:
    return (s or "").strip()


def _parse_decision(row: dict[str, str]) -> bool:
    """
    Returns True if the system ACCEPTED the claimed identity for this attempt.

    Supported inputs (any one is enough):
    - decision: accept/reject, true/false, 1/0, yes/no
    - accepted: true/false, 1/0, yes/no
    - matched_reg: non-empty implies accept
    """
    decision = _norm(row.get("decision"))
    accepted = _norm(row.get("accepted"))
    matched_reg = _norm(row.get("matched_reg")) or _norm(row.get("predicted_reg"))

    def to_bool(v: str) -> bool | None:
        v = v.lower()
        if v in {"accept", "accepted", "true", "1", "yes", "y", "ok", "pass"}:
            return True
        if v in {"reject", "rejected", "false", "0", "no", "n", "fail"}:
            return False
        return None

    b = to_bool(decision)
    if b is not None:
        return b
    b = to_bool(accepted)
    if b is not None:
        return b
    if matched_reg:
        return True
    return False


def compute_counts(csv_path: Path) -> Counts:
    """
    Expected CSV columns (minimum):
    - claimed_reg: registration number entered/claimed by user
    - actual_reg: the real person in front of camera for that attempt (ground truth)

    Plus either:
    - decision / accepted (accept/reject), OR
    - matched_reg (predicted registration number; blank if rejected)
    """
    if not csv_path.exists():
        raise FileNotFoundError(f"Input file not found: {csv_path}")

    total = tp = fn = fp = tn = 0

    with csv_path.open(newline="", encoding="utf-8", errors="replace") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            raise ValueError("CSV has no header row.")

        required = {"claimed_reg", "actual_reg"}
        missing = sorted(required - set(reader.fieldnames))
        if missing:
            raise ValueError(f"Missing required columns: {', '.join(missing)}")

        for row in reader:
            claimed = _norm(row.get("claimed_reg"))
            actual = _norm(row.get("actual_reg"))
            if not claimed or not actual:
                # skip incomplete rows
                continue

            accepted = _parse_decision(row)
            genuine = (claimed == actual)

            total += 1
            if genuine and accepted:
                tp += 1
            elif genuine and not accepted:
                fn += 1
            elif (not genuine) and accepted:
                fp += 1
            else:
                tn += 1

    return Counts(total=total, tp=tp, fn=fn, fp=fp, tn=tn)


def pct(n: int, d: int) -> str:
    if d <= 0:
        return "n/a"
    return f"{(n / d) * 100:.2f}%"


def main():
    ap = argparse.ArgumentParser(
        description="Compute face verification metrics (TP/FN/FP/TN) from a labeled attempts CSV."
    )
    ap.add_argument(
        "csv",
        help="Path to attempts CSV (must include claimed_reg, actual_reg, and decision/accepted or matched_reg).",
    )
    args = ap.parse_args()

    counts = compute_counts(Path(args.csv))

    print("\n=== Face verification metrics (confusion matrix) ===")
    print(f"Total attempts             : {counts.total}")
    print(f"True verifications (TP)    : {counts.tp}  ({pct(counts.tp, counts.total)})")
    print(f"False negatives (FN)       : {counts.fn}  ({pct(counts.fn, counts.total)})")
    print(f"False positives (FP)       : {counts.fp}  ({pct(counts.fp, counts.total)})")
    print(f"True negatives (TN)        : {counts.tn}  ({pct(counts.tn, counts.total)})")

    genuine_total = counts.tp + counts.fn
    imposter_total = counts.fp + counts.tn

    print("\nRates:")
    # For verification systems:
    # - FRR (False Rejection Rate) = FN / genuine_total
    # - FAR (False Acceptance Rate) = FP / imposter_total
    # - TAR (True Acceptance Rate) = TP / genuine_total
    print(f"  Genuine attempts         : {genuine_total}")
    print(f"  Imposter attempts        : {imposter_total}")
    print(f"  TAR / TPR                : {pct(counts.tp, genuine_total)}")
    print(f"  FRR (FN rate)            : {pct(counts.fn, genuine_total)}")
    print(f"  FAR (FP rate)            : {pct(counts.fp, imposter_total)}")


if __name__ == "__main__":
    main()

