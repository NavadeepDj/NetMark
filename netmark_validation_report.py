import argparse
import csv
import ipaddress
import re
from pathlib import Path
from typing import Iterable


# Matches text that indicates the app could NOT connect to classroom server.
# (Based on `file_sender/lib/user_screen.dart` + common SocketException strings)
CONNECTION_ERROR_PATTERNS = [
    r"Unable to connect to the classroom server",
    r"\bConnection Error\b",
    r"\bConnection error\b",
    r"Error fetching user details",
    r"Error uploading unique ID",
    r"SocketException",
    r"Connection refused",
    r"timed out",
    r"Failed host lookup",
]

# Matches text that indicates a server call succeeded (connected correctly).
# (Based on `file_sender/lib/user_screen.dart` prints + your stress test logs)
CONNECTED_OK_PATTERNS = [
    r"✅ Attendance uploaded successfully",
    r"✅ Face verification successful",
    r"\bSuccessful:\s*\d+\b",  # stress test logs
]


def _compile_any(patterns: list[str]) -> re.Pattern:
    joined = "|".join(f"(?:{p})" for p in patterns)
    return re.compile(joined, flags=re.IGNORECASE)


_RE_CONN_ERR = _compile_any(CONNECTION_ERROR_PATTERNS)
_RE_CONN_OK = _compile_any(CONNECTED_OK_PATTERNS)


def is_in_same_subnet(client_ip: str, host_ip: str, cidr: int) -> bool:
    try:
        network = ipaddress.ip_network(f"{host_ip}/{cidr}", strict=False)
        ip_obj = ipaddress.ip_address(client_ip)
        return ip_obj in network
    except ValueError:
        return False


def iter_lines(paths: Iterable[Path]) -> Iterable[tuple[Path, str]]:
    for p in paths:
        if not p.exists():
            continue
        # tolerate mixed encodings from logcat / terminals
        with p.open("r", encoding="utf-8", errors="replace") as f:
            for line in f:
                yield p, line.rstrip("\n")


def analyze_logs(log_paths: list[Path]) -> dict:
    totals = {
        "connected_ok": 0,
        "connection_errors": 0,
        "files_missing": [],
        "per_file": {},
    }

    existing = []
    for p in log_paths:
        if p.exists():
            existing.append(p)
        else:
            totals["files_missing"].append(str(p))

    per_file = {str(p): {"connected_ok": 0, "connection_errors": 0} for p in existing}

    for p, line in iter_lines(existing):
        key = str(p)
        if _RE_CONN_OK.search(line):
            per_file[key]["connected_ok"] += 1
            totals["connected_ok"] += 1
        if _RE_CONN_ERR.search(line):
            per_file[key]["connection_errors"] += 1
            totals["connection_errors"] += 1

    totals["per_file"] = per_file
    return totals


def analyze_ip_tracking(ip_tracking_csv: Path, host_ip: str, cidr: int) -> dict:
    result = {
        "total_ips": 0,
        "subnet_ok": 0,
        "subnet_fail": 0,
        "invalid_rows": 0,
        "missing_file": None,
    }

    if not ip_tracking_csv.exists():
        result["missing_file"] = str(ip_tracking_csv)
        return result

    with ip_tracking_csv.open(newline="", encoding="utf-8", errors="replace") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames or "IP" not in reader.fieldnames:
            result["invalid_rows"] += 1
            return result

        for row in reader:
            ip = (row.get("IP") or "").strip()
            if not ip:
                continue
            result["total_ips"] += 1
            if is_in_same_subnet(ip, host_ip, cidr):
                result["subnet_ok"] += 1
            else:
                result["subnet_fail"] += 1

    return result


def main():
    ap = argparse.ArgumentParser(
        description="NetMark: count classroom connection errors vs ok, and optionally validate subnet using ip_tracking.csv"
    )
    ap.add_argument(
        "--logs",
        nargs="*",
        default=[],
        help="One or more log files (flutter run output, adb logcat dump, stress_test_logs/*.log).",
    )
    ap.add_argument(
        "--ip-tracking",
        default="ip_tracking.csv",
        help="Path to ip_tracking.csv (default: ip_tracking.csv).",
    )
    ap.add_argument(
        "--host-ip",
        default=None,
        help="Host/server IP (e.g. 10.2.8.97). Required for subnet validation.",
    )
    ap.add_argument(
        "--cidr",
        type=int,
        default=24,
        help="Subnet CIDR (default: 24 for /24).",
    )

    args = ap.parse_args()

    logs = [Path(p) for p in args.logs]
    log_stats = analyze_logs(logs) if logs else None

    print("\n=== Classroom connection outcome counts ===")
    if not logs:
        print("No logs provided. Use --logs <file1> <file2> ... to count outcomes from logs.")
    else:
        for missing in log_stats["files_missing"]:
            print(f"Missing log file: {missing}")

        for file_path, s in log_stats["per_file"].items():
            print(f"\n{file_path}")
            print(f"  Connected OK hits     : {s['connected_ok']}")
            print(f"  Connection error hits : {s['connection_errors']}")

        total_ok = log_stats["connected_ok"]
        total_err = log_stats["connection_errors"]
        total = total_ok + total_err
        print("\nTOTAL")
        print(f"  Connected OK hits     : {total_ok}")
        print(f"  Connection error hits : {total_err}")
        if total:
            print(f"  OK %                  : {total_ok / total * 100:.2f}%")
            print(f"  Error %               : {total_err / total * 100:.2f}%")

    print("\n=== Subnet validation (ip_tracking.csv) ===")
    if not args.host_ip:
        print("Subnet validation skipped (pass --host-ip 10.2.8.97 --cidr 24).")
    else:
        ip_stats = analyze_ip_tracking(Path(args.ip_tracking), args.host_ip, args.cidr)
        if ip_stats["missing_file"]:
            print(f"Missing file: {ip_stats['missing_file']}")
        else:
            print(f"Host: {args.host_ip}/{args.cidr}")
            print(f"  Total IPs checked : {ip_stats['total_ips']}")
            print(f"  In subnet (OK)    : {ip_stats['subnet_ok']}")
            print(f"  Out of subnet     : {ip_stats['subnet_fail']}")
            if ip_stats["total_ips"]:
                print(f"  OK %              : {ip_stats['subnet_ok'] / ip_stats['total_ips'] * 100:.2f}%")
                print(
                    f"  Out %             : {ip_stats['subnet_fail'] / ip_stats['total_ips'] * 100:.2f}%"
                )


if __name__ == "__main__":
    main()

