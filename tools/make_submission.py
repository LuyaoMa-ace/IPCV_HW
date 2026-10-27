#!/usr/bin/env python3
"""Build and verify the submission zip required by the course ("Assignment Submission Guidelines").

Rules checked:
  * one .zip named surname1_surname2.zip (lowercase surnames, alphabetical order)
  * the zip contains exactly two files, assignment_module_one.ipynb and assignment_module_two.ipynb
  * the first cell of each notebook contains the student IDs, names and e-mail addresses of all team members

Usage:
  python3 tools/make_submission.py --one path/to/assignment_module_one.ipynb \
                                   --two path/to/assignment_module_two.ipynb [--out submission] [--team submission/team.json]
"""
import argparse, json, sys, zipfile
from pathlib import Path

TEAM = []   # filled from --team (a local, untracked json file with surname, name, student_id, email per member)
NAMES = ("assignment_module_one.ipynb", "assignment_module_two.ipynb")


def first_cell_text(path):
    cells = json.loads(Path(path).read_text())["cells"]
    s = cells[0]["source"]
    return "".join(s) if isinstance(s, list) else s


def check_first_cell(path, label):
    text = first_cell_text(path).lower()
    problems = []
    for _, name, sid, mail in TEAM:
        for what, value in (("name", name), ("student ID", sid), ("e-mail", mail)):
            if value.lower() not in text:
                problems.append(f"{label}: first cell does not contain {what} '{value}'")
    return problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--one", required=True); ap.add_argument("--two", required=True)
    ap.add_argument("--out", default="submission"); ap.add_argument("--team", default="submission/team.json")
    a = ap.parse_args()
    TEAM.extend((m["surname"], m["name"], m["student_id"], m["email"]) for m in json.loads(Path(a.team).read_text())["team"])

    problems = []
    for label, p in (("module one", a.one), ("module two", a.two)):
        if not Path(p).is_file():
            problems.append(f"{label}: file not found: {p}")
    if problems:
        print("\n".join("PROBLEM: " + x for x in problems)); sys.exit(1)

    problems += check_first_cell(a.one, "assignment_module_one")
    problems += check_first_cell(a.two, "assignment_module_two")
    try:
        import nbformat
        for p in (a.one, a.two):
            nbformat.validate(nbformat.read(p, as_version=4))
    except ImportError:
        print("note: nbformat not installed, skipping notebook validation")
    except Exception as e:
        problems.append(f"invalid notebook: {e}")

    surnames = sorted(s for s, *_ in TEAM)
    zname = "_".join(surnames) + ".zip"
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    zpath = out / zname
    if zpath.exists():
        zpath.unlink()
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(a.one, NAMES[0]); z.write(a.two, NAMES[1])

    with zipfile.ZipFile(zpath) as z:
        members = z.namelist()
    if sorted(members) != sorted(NAMES):
        problems.append(f"zip members are {members}, expected exactly {list(NAMES)}")

    print(f"zip: {zpath}  ({zpath.stat().st_size/1e6:.2f} MB)")
    print("members:", members)
    if problems:
        print("\n".join("PROBLEM: " + x for x in problems)); sys.exit(1)
    print("OK: name, contents and first cells follow the submission guidelines.")


if __name__ == "__main__":
    main()
