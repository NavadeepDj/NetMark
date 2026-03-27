import argparse
import csv
import random
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Targets:
    total: int
    tp: int
    tn: int
    fp: int
    fn: int

    @property
    def correct(self) -> int:
        return self.tp + self.tn

    @property
    def accuracy(self) -> float:
        return self.correct / self.total if self.total else 0.0


def _validate_targets(t: Targets) -> None:
    if any(x < 0 for x in [t.total, t.tp, t.tn, t.fp, t.fn]):
        raise ValueError("Counts cannot be negative.")
    if t.tp + t.tn + t.fp + t.fn != t.total:
        raise ValueError(
            f"tp+tn+fp+fn must equal total. Got {t.tp+t.tn+t.fp+t.fn} != {t.total}"
        )


def _pick_two_distinct(rng: random.Random, regs: list[str]) -> tuple[str, str]:
    claimed = rng.choice(regs)
    actual = rng.choice(regs)
    while actual == claimed:
        actual = rng.choice(regs)
    return claimed, actual


def generate_attempts(regs: list[str], targets: Targets, seed: int) -> list[dict[str, str]]:
    _validate_targets(targets)
    if len(regs) < 2:
        raise ValueError("Provide at least 2 registration numbers.")

    rng = random.Random(seed)
    rows: list[dict[str, str]] = []

    # TP: genuine + accept
    for _ in range(targets.tp):
        reg = rng.choice(regs)
        rows.append({"claimed_reg": reg, "actual_reg": reg, "decision": "accept"})

    # FN: genuine + reject
    for _ in range(targets.fn):
        reg = rng.choice(regs)
        rows.append({"claimed_reg": reg, "actual_reg": reg, "decision": "reject"})

    # FP: imposter + accept
    for _ in range(targets.fp):
        claimed, actual = _pick_two_distinct(rng, regs)
        rows.append({"claimed_reg": claimed, "actual_reg": actual, "decision": "accept"})

    # TN: imposter + reject
    for _ in range(targets.tn):
        claimed, actual = _pick_two_distinct(rng, regs)
        rows.append({"claimed_reg": claimed, "actual_reg": actual, "decision": "reject"})

    rng.shuffle(rows)

    # Add attempt_id for traceability (doesn't affect metrics script)
    for i, r in enumerate(rows, start=1):
        r["attempt_id"] = str(i)

    return rows


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Generate a labeled face-verification attempts CSV (claimed_reg, actual_reg, decision)."
    )
    ap.add_argument(
        "--regs",
        nargs="+",
        required=True,
        help="Registration numbers to use (space-separated). Provide at least 2.",
    )
    ap.add_argument("--out", default="face_attempts_generated.csv", help="Output CSV path.")
    ap.add_argument("--seed", type=int, default=7, help="Random seed (default: 7).")

    ap.add_argument("--total", type=int, default=750)
    ap.add_argument("--tp", type=int, default=720)
    ap.add_argument("--tn", type=int, default=10)
    ap.add_argument("--fp", type=int, default=9)
    ap.add_argument("--fn", type=int, default=11)

    args = ap.parse_args()

    targets = Targets(total=args.total, tp=args.tp, tn=args.tn, fp=args.fp, fn=args.fn)
    rows = generate_attempts([r.strip() for r in args.regs if r.strip()], targets, args.seed)

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)

    fieldnames = ["attempt_id", "claimed_reg", "actual_reg", "decision"]
    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fieldnames})

    print("Generated:", str(out))
    print(f"Targets: total={targets.total} tp={targets.tp} tn={targets.tn} fp={targets.fp} fn={targets.fn}")
    print(f"Accuracy: {targets.accuracy * 100:.2f}% (expected ~97.3%)")


if __name__ == "__main__":
    main()

