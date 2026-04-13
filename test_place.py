import re

_VENUE_TYPES = r'house|home|hotel|mall|shop|store|market|hospital|school|college|university|office|bank|temple|church|mosque|park|stadium|theatre|theater|cinema|restaurant|pub|farm|factory|warehouse|garage|flat|apartment|building|compound|campus'
_PLACE_SUFFIXES = r'nagar|puram|patti|palayam|abad|pur|ganj|wadi|pet|kuppam|salai'
_MULTIWORD_SUFFIXES = r'nagar|street|colony|layout|extension|enclave|vihar|puram|salai|road|lane'
_KNOWN_CITIES = r'chennai|mumbai|delhi|kolkata|bangalore|bengaluru|hyderabad|pune|ahmedabad|surat|jaipur|lucknow|kanpur|nagpur|indore|thane|bhopal|visakhapatnam|patna|vadodara|ghaziabad|ludhiana|agra|nashik|faridabad|meerut|rajkot|coimbatore|madurai|namakkal|salem|trichy|tiruchirappalli|erode|tirunelveli|vellore|thoothukudi|dindigul|kanchipuram|thanjavur|tiruppur|krishnagiri|dharmapuri|cuddalore|villupuram|puducherry|pondicherry|karur|perambalur|ariyalur|nagapattinam|tiruvarur|ramanathapuram|virudhunagar|tenkasi|kallakurichi'

PLACE_PATTERNS = [
    r'\b(?:at|near|in|from|behind|opposite|beside)\s+(?:' + _KNOWN_CITIES + r')\b',
    r'\b(?:at|near|in|from|behind|opposite|beside)\s+(?:a\s+|the\s+)?(?:' + _VENUE_TYPES + r')\b',
    r'\b(?:at|near|in|from|behind|opposite|beside)\s+[A-Z][a-z]+\s+(?:' + _MULTIWORD_SUFFIXES + r')\b',
    r'\b\w{3,}(?:' + _PLACE_SUFFIXES + r')\b',
    r'\b(?:plot no|door no|flat no|house no|survey no)\.?\s*\d+\b',
]

tests = [
    ("he stabbed at neck", False),
    ("he hit me at back", False),
    ("attacked at shoulder", False),
    ("punched at face", False),
    ("stabbed at chest", False),
    ("kicked at leg", False),
    ("at night he came", False),
    ("at the time of incident", False),
    ("incident at Anna Nagar", True),
    ("near Chennai", True),
    ("at hotel", True),
    ("at mall", True),
    ("in hospital", True),
    ("at Namakkal", True),
    ("at market", True),
    ("at school", True),
    ("at bank", True),
    ("near Coimbatore", True),
    ("Annanagar street", True),
    ("door no 5", True),
]

all_ok = True
for t, expected in tests:
    found = any(re.search(p, t, re.IGNORECASE) for p in PLACE_PATTERNS)
    status = "OK" if found == expected else "FAIL"
    if status == "FAIL":
        all_ok = False
    print(f"  [{status}] \"{t}\" -> {'PLACE' if found else 'NO PLACE'} (expected {'PLACE' if expected else 'NO PLACE'})")

print()
print("All tests passed!" if all_ok else "Some tests FAILED!")
