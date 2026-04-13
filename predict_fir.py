from section_predictor import SectionPredictor, generate_fir_draft


def run():
    print("=" * 65)
    print("       FIR SECTION PREDICTOR & DRAFT GENERATOR")
    print("=" * 65)

    predictor = SectionPredictor(model_path="fir_model.pkl")

    print("\nEnter the incident description (press Enter twice when done):")
    lines = []
    while True:
        line = input()
        if line == "":
            break
        lines.append(line)
    description = " ".join(lines).strip()

    if not description:
        print("[ERROR] No description provided.")
        return

    result = predictor.predict(description, top_k=5)

    print("\n" + "-" * 65)
    print("PREDICTION RESULTS")
    print("-" * 65)

    if result["alerts"]:
        print("\n[!] MISSING INFORMATION ALERTS:")
        for field, msg in result["alerts"].items():
            print(f"   {msg}")
    else:
        print("\n[OK] All key fields (date, time, place) detected in description.")

    print("\n[RULE-BASED] Sections Matched:")
    if result["rule_based_sections"]:
        for s in result["rule_based_sections"]:
            print(f"   * {s.upper().replace('_', ' ')}")
    else:
        print("   None matched by rules.")

    print("\n[ML] Predicted Sections (with confidence):")
    if result["ml_sections"]:
        for s in result["ml_sections"]:
            conf = result["ml_confidence"].get(s, 0)
            print(f"   * {s.upper().replace('_', ' ')}  [{conf:.1f}%]")
    else:
        print("   Model not loaded or no confident predictions.")

    print("\n[FINAL] Predicted Sections (merged):")
    if result["predicted_sections"]:
        for s in result["predicted_sections"]:
            print(f"   * {s.upper().replace('_', ' ')}")
    else:
        print("   No sections predicted.")

    print("\n" + "-" * 65)
    print("GENERATE FIR DRAFT")
    print("-" * 65)
    complainant = input("Complainant Name: ").strip() or "Unknown"
    date_occ = input("Date of Occurrence (e.g. 15-06-2024) [leave blank if unknown]: ").strip() or "Not specified"
    time_occ = input("Time of Occurrence (e.g. 10:30 PM) [leave blank if unknown]: ").strip() or "Not specified"
    place_occ = input("Place of Occurrence [leave blank if unknown]: ").strip() or "Not specified"
    ps = input("Police Station Name [leave blank if unknown]: ").strip() or "Not specified"

    draft = generate_fir_draft(
        complainant_name=complainant,
        description=description,
        sections=result["predicted_sections"],
        date_of_occurrence=date_occ,
        time_of_occurrence=time_occ,
        place_of_occurrence=place_occ,
        police_station=ps,
    )

    print(draft)

    save = input("Save FIR draft to file? (y/n): ").strip().lower()
    if save == "y":
        filename = f"fir_draft_{complainant.replace(' ', '_')}.txt"
        with open(filename, "w", encoding="utf-8") as f:
            f.write(draft)
        print(f"[INFO] FIR draft saved to '{filename}'")


if __name__ == "__main__":
    run()
