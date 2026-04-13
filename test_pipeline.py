import sys
sys.stdout.reconfigure(encoding="utf-8")

from section_predictor import SectionPredictor, generate_fir_draft

p = SectionPredictor()

print("=== TEST 1: Complete description (date + time + place present) ===")
t1 = "On 15th June 2024 at 10:30 PM near Gandhi Nagar market, the accused Raju threatened me with a knife and snatched my gold chain. He also beat me badly."
r1 = p.predict(t1)
print("Rule sections :", r1["rule_based_sections"])
print("ML sections   :", r1["ml_sections"])
print("Alerts        :", r1["alerts"])
print("Merged        :", r1["predicted_sections"])

print()
print("=== TEST 2: Missing date, time, place ===")
t2 = "The accused came and beat me and stole my mobile phone and threatened to kill me."
r2 = p.predict(t2)
print("Rule sections :", r2["rule_based_sections"])
print("Alerts        :", r2["alerts"])

print()
print("=== TEST 3: Rape + dowry case ===")
t3 = "On Sunday morning at 8 AM at my residence in Sector 5, my husband and in-laws harassed me for dowry and my husband sexually assaulted me."
r3 = p.predict(t3)
print("Rule sections :", r3["rule_based_sections"])
print("Alerts        :", r3["alerts"])

print()
print("=== FIR DRAFT ===")
draft = generate_fir_draft(
    complainant_name="Ramesh Kumar",
    description=t1,
    sections=r1["predicted_sections"],
    date_of_occurrence="15-06-2024",
    time_of_occurrence="10:30 PM",
    place_of_occurrence="Gandhi Nagar Market",
    police_station="Gandhi Nagar PS",
)
print(draft)
