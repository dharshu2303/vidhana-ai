import re
import pickle
import numpy as np
from datetime import datetime

# ─── Rule-based keyword map (section → keywords) ───────────────────────────
RULE_MAP = {
    "ipc_302": [
        "murder", "killed", "shot dead", "stabbed to death", "homicide",
        # Hindi
        "हत्या", "मार डाला", "गोली मार दी", "चाकू मारकर मार डाला",
        # Tamil
        "கொலை", "கொன்றார்", "சுட்டுக்கொன்றார்",
        # Telugu
        "హత్య", "చంపేశారు", "కాల్చి చంపారు",
        # Kannada
        "ಕೊಲೆ", "ಕೊಂದರು", "ಗುಂಡು ಹಾಕಿ ಕೊಂದರು",
    ],
    "ipc_307": [
        "attempt to murder", "attempted murder", "tried to kill",
        "हत्या का प्रयास", "मारने की कोशिश",
        "கொலை முயற்சி", "கொல்ல முயன்றார்",
        "హత్యాయత్నం", "చంపడానికి ప్రయత్నించారు",
        "ಕೊಲೆ ಯತ್ನ", "ಕೊಲ್ಲಲು ಪ್ರಯತ್ನಿಸಿದರು",
    ],
    "ipc_304": [
        "culpable homicide", "not amounting to murder",
        "गैर इरादतन हत्या",
        "தற்கொலை அல்லாத கொலை",
        "నేరపూరిత హత్య",
        "ಅಪರಾಧಿ ನರಹತ್ಯೆ",
    ],
    "ipc_376": [
        "rape", "sexual assault", "sexually assaulted", "forced intercourse",
        "बलात्कार", "यौन उत्पीड़न", "यौन हमला",
        "பாலியல் வன்கொடுமை", "பாலியல் தாக்குதல்", "கற்பழிப்பு",
        "అత్యాచారం", "లైంగిక దాడి",
        "ಅತ್ಯಾಚಾರ", "ಲೈಂಗಿಕ ದೌರ್ಜನ್ಯ",
    ],
    "ipc_354": [
        "molestation", "outrage modesty", "touched inappropriately", "groped",
        "छेड़छाड़", "अभद्रता",
        "பாலியல் தொல்லை", "தவறாக தொட்டார்",
        "అసభ్యంగా ప్రవర్తించారు", "వేధింపు",
        "ಅಸಭ್ಯವಾಗಿ ವರ್ತಿಸಿದರು", "ಕಿರುಕುಳ",
    ],
    "ipc_379": [
        "theft", "stolen", "stole", "pickpocket", "snatched",
        "चोरी", "चुराया", "उठाईगिरी",
        "திருட்டு", "திருடினார்", "களவு",
        "దొంగతనం", "దొంగిలించారు",
        "ಕಳ್ಳತನ", "ಕದ್ದರು",
    ],
    "ipc_380": [
        "house theft", "burglary", "broke into house", "stolen from house",
        "घर से चोरी", "सेंधमारी",
        "வீட்டு திருட்டு", "வீட்டில் புகுந்து திருடினார்",
        "ఇంటి దొంగతనం", "ఇంట్లో చొరబడి దొంగిలించారు",
        "ಮನೆ ಕಳ್ಳತನ", "ಮನೆಗೆ ನುಗ್ಗಿ ಕದ್ದರು",
    ],
    "ipc_392": [
        "robbery", "robbed", "snatched at gunpoint", "looted",
        "लूट", "लूटा", "डकैती",
        "கொள்ளை", "கொள்ளையடித்தார்",
        "దోపిడీ", "దోచుకున్నారు",
        "ದರೋಡೆ", "ಲೂಟಿ ಮಾಡಿದರು",
    ],
    "ipc_395": [
        "dacoity", "gang robbery", "armed gang looted",
        "डकैती", "सामूहिक लूट",
        "கொள்ளைக் கும்பல்",
        "సామూహిక దోపిడీ",
        "ಗುಂಡಾ ದರೋಡೆ",
    ],
    "ipc_420": [
        "cheating", "fraud", "deceived", "duped", "swindled", "scam",
        "cheated", "otp", "posed as", "bank officer", "collected otp",
        "withdraw money", "withdrew money", "online fraud", "cyber fraud",
        "phishing", "upi fraud", "debit card", "credit card fraud",
        "money transferred", "fake call", "unknown caller", "impersonated",
        # Hindi
        "धोखाधड़ी", "ठगी", "ठगा", "धोखा दिया", "जालसाजी",
        "पैसे ठगे", "ऑनलाइन ठगी",
        # Tamil
        "மோசடி", "ஏமாற்றினார்", "ஏமாற்று", "பணம் மோசடி",
        # Telugu
        "మోసం", "మోసగించారు", "నకిలీ", "డబ్బు మోసం",
        # Kannada
        "ವಂಚನೆ", "ಮೋಸ ಮಾಡಿದರು", "ಹಣ ವಂಚನೆ",
    ],
    "ipc_406": [
        "criminal breach of trust", "misappropriation", "embezzlement",
        "collected money", "took money", "did not return",
        "विश्वासघात", "गबन", "पैसे वापस नहीं किए",
        "நம்பிக்கை துரோகம்", "பணத்தை திருப்பி தரவில்லை",
        "నమ్మకద్రోహం", "డబ్బు తిరిగి ఇవ్వలేదు",
        "ನಂಬಿಕೆ ದ್ರೋಹ", "ಹಣ ಹಿಂತಿರುಗಿಸಲಿಲ್ಲ",
    ],
    "ipc_498a": [
        "dowry harassment", "cruelty by husband", "domestic violence", "dowry demand",
        "दहेज उत्पीड़न", "पति की क्रूरता", "घरेलू हिंसा", "दहेज की मांग",
        "வரதட்சணை கொடுமை", "கணவன் கொடுமை", "குடும்ப வன்முறை",
        "వరకట్న వేధింపు", "భర్త క్రూరత్వం", "గృహ హింస",
        "ವರದಕ್ಷಿಣೆ ಕಿರುಕುಳ", "ಗಂಡನ ಕ್ರೌರ್ಯ", "ಕೌಟುಂಬಿಕ ಹಿಂಸೆ",
    ],
    "ipc_304b": [
        "dowry death", "bride burning", "died due to dowry",
        "दहेज हत्या", "दहेज मृत्यु",
        "வரதட்சணை மரணம்",
        "వరకట్న మరణం",
        "ವರದಕ್ಷಿಣೆ ಸಾವು",
    ],
    "ipc_323": [
        "assault", "beaten", "hit", "punched", "slapped", "attacked",
        "मारपीट", "पीटा", "थप्पड़ मारा", "हमला किया",
        "தாக்குதல்", "அடித்தார்", "தாக்கினார்",
        "దాడి", "కొట్టారు", "కొట్టాడు",
        "ಹಲ್ಲೆ", "ಹೊಡೆದರು", "ದಾಳಿ ಮಾಡಿದರು",
    ],
    "ipc_324": [
        "hurt with weapon", "stabbed", "cut with knife", "injured with rod",
        "चाकू से हमला", "चाकू मारा", "हथियार से मारा",
        "கத்தியால் குத்தினார்", "ஆயுதத்தால் தாக்கினார்",
        "కత్తితో పొడిచారు", "ఆయుధంతో దాడి",
        "ಚಾಕುವಿನಿಂದ ಇರಿದರು", "ಆಯುಧದಿಂದ ಹೊಡೆದರು",
    ],
    "ipc_325": [
        "grievous hurt", "serious injury", "bone fracture", "grievous injury",
        "गंभीर चोट", "हड्डी टूटी",
        "கடுமையான காயம்", "எலும்பு முறிவு",
        "తీవ్రమైన గాయం", "ఎముక విరిగింది",
        "ಗಂಭೀರ ಗಾಯ", "ಮೂಳೆ ಮುರಿತ",
    ],
    "ipc_326": [
        "acid attack", "threw acid", "grievous hurt with weapon",
        "तेजाब हमला", "एसिड अटैक",
        "ஆசிட் தாக்குதல்",
        "యాసిడ్ దాడి",
        "ಆಮ್ಲ ದಾಳಿ",
    ],
    "ipc_363": [
        "kidnapping", "kidnapped", "abducted minor", "missing child",
        "अपहरण", "बच्चा गायब",
        "கடத்தல்", "சிறுவன் காணாமல்",
        "అపహరణ", "పిల్లవాడు కనిపించడం లేదు",
        "ಅಪಹರಣ", "ಮಗು ಕಾಣೆಯಾಗಿದೆ",
    ],
    "ipc_364": [
        "kidnapping for ransom", "abducted for ransom",
        "फिरौती के लिए अपहरण",
        "பணத்திற்காக கடத்தல்",
        "విమోచన కోసం అపహరణ",
        "ಹಣಕ್ಕಾಗಿ ಅಪಹರಣ",
    ],
    "ipc_365": [
        "wrongful confinement", "unlawfully confined", "held captive",
        "गलत कैद", "बंधक बनाया",
        "தவறான சிறை",
        "అక్రమ నిర్బంధం",
        "ಅಕ್ರಮ ಬಂಧನ",
    ],
    "ipc_366": [
        "abduction of woman", "kidnapped woman", "forced marriage",
        "महिला का अपहरण", "जबरन शादी",
        "பெண் கடத்தல்", "கட்டாய திருமணம்",
        "మహిళ అపహరణ", "బలవంతపు వివాహం",
        "ಮಹಿಳೆ ಅಪಹರಣ", "ಬಲವಂತದ ವಿವಾಹ",
    ],
    "ipc_384": [
        "extortion", "threatened for money", "blackmail",
        "जबरन वसूली", "ब्लैकमेल",
        "மிரட்டி பணம் பறித்தல்", "பிளாக்மெயில்",
        "బ్లాక్ మెయిల్", "బెదిరించి డబ్బు",
        "ಬ್ಲ್ಯಾಕ್ ಮೇಲ್", "ಬೆದರಿಸಿ ಹಣ",
    ],
    "ipc_506": [
        "criminal intimidation", "threatened", "death threat", "threatened to kill",
        "धमकी", "जान से मारने की धमकी",
        "மிரட்டல்", "கொலை மிரட்டல்",
        "బెదిరింపు", "చంపుతానని బెదిరించారు",
        "ಬೆದರಿಕೆ", "ಕೊಲ್ಲುತ್ತೇನೆ ಎಂದು ಬೆದರಿಸಿದರು",
    ],
    "ipc_509": [
        "word gesture to insult woman", "obscene gesture", "eve teasing",
        "छेड़छाड़", "अश्लील इशारे",
        "ஆபாச சைகை", "ஈவ் டீசிங்",
        "అసభ్య సంజ్ఞలు",
        "ಅಸಭ್ಯ ಸನ್ನೆ",
    ],
    "ipc_341": [
        "wrongful restraint", "blocked path", "prevented from moving",
        "गलत तरीके से रोका",
        "தடுத்து நிறுத்தினார்",
        "అడ్డుకున్నారు",
        "ತಡೆದರು",
    ],
    "ipc_143": [
        "unlawful assembly", "mob", "gathered illegally",
        "गैरकानूनी जमावड़ा",
        "சட்டவிரோத கூட்டம்",
        "అక్రమ సమావేశం",
        "ಅಕ್ರಮ ಸಭೆ",
    ],
    "ipc_147": [
        "rioting", "riot", "mob violence",
        "दंगा", "भीड़ हिंसा",
        "கலவரம்",
        "అల్లర్లు",
        "ಗಲಭೆ",
    ],
    "ipc_148": [
        "rioting armed with deadly weapon", "armed mob",
        "हथियारबंद दंगा",
        "ஆயுதம் ஏந்திய கலவரம்",
        "ఆయుధాలతో అల్లర్లు",
        "ಶಸ್ತ್ರಸಜ್ಜಿತ ಗಲಭೆ",
    ],
    "ipc_149": [
        "common object", "every member of unlawful assembly",
        "सामान्य उद्देश्य",
        "பொதுவான நோக்கம்",
        "సామాన్య ఉద్దేశం",
        "ಸಾಮಾನ್ಯ ಉದ್ದೇಶ",
    ],
    "ipc_186": [
        "obstruct public servant", "obstructed police", "hindered officer",
        "सरकारी कर्मचारी को रोका", "पुलिस को रोका",
        "அரசு ஊழியரை தடுத்தார்",
        "ప్రభుత్వ ఉద్యోగిని అడ్డుకున్నారు",
        "ಸರ್ಕಾರಿ ನೌಕಕರನ್ನು ತಡೆದರು",
    ],
    "ipc_353": [
        "assault on public servant", "attacked police officer",
        "पुलिस अधिकारी पर हमला",
        "காவல்துறை அதிகாரி மீது தாக்குதல்",
        "పోలీసు అధికారిపై దాడి",
        "ಪೊಲೀಸ್ ಅಧಿಕಾರಿ ಮೇಲೆ ಹಲ್ಲೆ",
    ],
    "ipc_332": [
        "voluntarily causing hurt to public servant",
        "सरकारी कर्मचारी को जानबूझकर चोट",
    ],
    "ipc_427": [
        "mischief", "property damage", "vandalism", "damaged property",
        "संपत्ति नुकसान", "तोड़फोड़",
        "சொத்து சேதம்", "அழிப்பு",
        "ఆస్తి నష్టం", "ధ్వంసం",
        "ಆಸ್ತಿ ಹಾನಿ", "ಧ್ವಂಸ",
    ],
    "ipc_436": [
        "mischief by fire", "arson", "set fire", "burnt house",
        "आगजनी", "आग लगा दी",
        "தீ வைத்தல்", "தீ வைத்தார்",
        "అగ్నిపెట్టారు",
        "ಬೆಂಕಿ ಹಚ್ಚಿದರು",
    ],
    "ipc_447": [
        "criminal trespass", "trespassed", "entered without permission",
        "अतिक्रमण", "बिना अनुमति प्रवेश",
        "அத்துமீறி நுழைந்தார்",
        "అనుమతి లేకుండా ప్రవేశించారు",
        "ಅನುಮತಿ ಇಲ್ಲದೆ ಪ್ರವೇಶಿಸಿದರು",
    ],
    "ipc_448": [
        "house trespass", "broke into house", "entered house illegally",
        "घर में अतिक्रमण",
        "வீட்டில் அத்துமீறல்",
        "ఇంట్లో అక్రమ ప్రవేశం",
        "ಮನೆಗೆ ಅಕ್ರಮ ಪ್ರವೇಶ",
    ],
    "ipc_465": [
        "forgery", "forged document", "fake document", "fake id", "fake identity",
        "जालसाजी", "नकली दस्तावेज",
        "போலி ஆவணம்",
        "నకిలీ పత్రం",
        "ನಕಲಿ ದಾಖಲೆ",
    ],
    "ipc_66d": [
        "cheating by impersonation", "posed as bank", "posed as officer",
        "fake caller", "otp fraud", "cyber impersonation", "impersonation online",
    ],
    "ipc_468": [
        "forgery for cheating", "forged for fraud",
        "धोखाधड़ी के लिए जालसाजी",
    ],
    "ipc_471": [
        "using forged document", "used fake document",
        "जाली दस्तावेज का उपयोग",
    ],
    "ipc_120b": [
        "criminal conspiracy", "conspired", "planned together to commit crime",
        "आपराधिक साजिश", "षड्यंत्र",
        "கிரிமினல் சதித்திட்டம்",
        "నేర కుట్ర",
        "ಅಪರಾಧ ಪಿತೂರಿ",
    ],
    "ipc_34": [
        "common intention", "acted together", "joint act",
        "सामान्य इरादा", "मिलकर किया",
        "பொதுவான நோக்கம்",
        "ఉమ్మడి ఉద్దేశం",
        "ಸಾಮಾನ್ಯ ಉದ್ದೇಶ",
    ],
}


def apply_rules(text: str) -> list[str]:
    """Return sections matched by keyword rules."""
    text_lower = text.lower()
    matched = []
    for section, keywords in RULE_MAP.items():
        if any(kw in text_lower for kw in keywords):
            matched.append(section)
    return matched


# ─── Missing field detection ────────────────────────────────────────────────
DATE_PATTERNS = [
    r"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b",
    r"\b\d{1,2}(?:st|nd|rd|th)?\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{2,4}\b",
    r"\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4}\b",
    r"\b(?:today|yesterday|on\s+\w+day)\b",
    r"\b\d{4}-\d{2}-\d{2}\b",
    # Hindi date words
    r"(?:जनवरी|फरवरी|मार्च|अप्रैल|मई|जून|जुलाई|अगस्त|सितंबर|अक्टूबर|नवंबर|दिसंबर)",
    r"(?:आज|कल|परसों)",
    # Tamil date words
    r"(?:ஜனவரி|பிப்ரவரி|மார்ச்|ஏப்ரல்|மே|ஜூன்|ஜூலை|ஆகஸ்ட்|செப்டம்பர்|அக்டோபர்|நவம்பர்|டிசம்பர்)",
    r"(?:இன்று|நேற்று|நாளை)",
    # Telugu
    r"(?:జనవరి|ఫిబ్రవరి|మార్చి|ఏప్రిల్|మే|జూన్|జూలై|ఆగస్టు|సెప్టెంబర్|అక్టోబర్|నవంబర్|డిసెంబర్)",
    r"(?:ఈరోజు|నిన్న|రేపు)",
    # Kannada
    r"(?:ಜನವರಿ|ಫೆಬ್ರವರಿ|ಮಾರ್ಚ್|ಏಪ್ರಿಲ್|ಮೇ|ಜೂನ್|ಜುಲೈ|ಆಗಸ್ಟ್|ಸೆಪ್ಟೆಂಬರ್|ಅಕ್ಟೋಬರ್|ನವೆಂಬರ್|ಡಿಸೆಂಬರ್)",
    r"(?:ಇಂದು|ನಿನ್ನೆ|ನಾಳೆ)",
    # Numeric patterns (dd/mm/yyyy, dd-mm-yyyy)
    r"\b\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}\b",
]

TIME_PATTERNS = [
    r"\b\d{1,2}:\d{2}\s*(?:am|pm)?\b",
    r"\b\d{1,2}\s*(?:am|pm)\b",
    r"\b(?:morning|afternoon|evening|night|midnight|noon|dawn|dusk)\b",
    r"\b(?:around|at|approximately)\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?\b",
    # Hindi time words
    r"(?:सुबह|दोपहर|शाम|रात|आधी रात|बजे)",
    # Tamil time words
    r"(?:காலை|மதியம்|மாலை|இரவு|நள்ளிரவு|மணி)",
    # Telugu time words
    r"(?:ఉదయం|మధ్యాహ్నం|సాయంత్రం|రాత్రి|అర్ధరాత్రి|గంటలు)",
    # Kannada time words
    r"(?:ಬೆಳಿಗ್ಗೆ|ಮಧ್ಯಾಹ್ನ|ಸಂಜೆ|ರಾತ್ರಿ|ಮಧ್ಯರಾತ್ರಿ|ಗಂಟೆ)",
]

# Explicit venue types
_VENUE_TYPES = (
    r"house|home|hotel|mall|shop|store|market|hospital|school|college|university|"
    r"office|bank|temple|church|mosque|park|stadium|theatre|theater|cinema|restaurant|"
    r"pub|farm|factory|warehouse|garage|flat|apartment|building|compound|campus"
)

_PLACE_SUFFIXES = r"nagar|puram|patti|palayam|abad|pur|ganj|wadi|pet|kuppam|salai"

_KNOWN_CITIES = (
    r"chennai|mumbai|delhi|kolkata|bangalore|bengaluru|hyderabad|pune|ahmedabad|"
    r"surat|jaipur|lucknow|kanpur|nagpur|indore|thane|bhopal|visakhapatnam|patna|"
    r"vadodara|ghaziabad|ludhiana|agra|nashik|faridabad|meerut|rajkot|coimbatore|"
    r"madurai|namakkal|salem|trichy|tiruchirappalli|erode|tirunelveli|vellore|"
    r"thoothukudi|dindigul|kanchipuram|thanjavur|tiruppur|krishnagiri|dharmapuri|"
    r"cuddalore|villupuram|puducherry|pondicherry|karur|perambalur|ariyalur|"
    r"nagapattinam|tiruvarur|ramanathapuram|virudhunagar|tenkasi|kallakurichi"
)

_MULTIWORD_SUFFIXES = r"nagar|street|colony|layout|extension|enclave|vihar|puram|salai|road|lane"

# Hindi venue words
_HINDI_VENUES = r"घर|मकान|होटल|दुकान|बाजार|अस्पताल|स्कूल|कॉलेज|ऑफिस|बैंक|मंदिर|चर्च|मस्जिद|पार्क"
# Tamil venue words
_TAMIL_VENUES = r"வீடு|கடை|சந்தை|மருத்துவமனை|பள்ளி|கல்லூரி|அலுவலகம|வங்கி|கோயில்|பூங்கா"
# Telugu venue words
_TELUGU_VENUES = r"ఇల్లు|హోటల్|దుకాణం|బజార్|ఆసుపత్రి|పాఠశాల|కళాశాల|కార్యాలయం|బ్యాంక్|గుడి|పార్కు"
# Kannada venue words
_KANNADA_VENUES = r"ಮನೆ|ಹೋಟೆಲ್|ಅಂಗಡಿ|ಮಾರುಕಟ್ಟೆ|ಆಸ್ಪತ್ರೆ|ಶಾಲೆ|ಕಾಲೇಜು|ಕಚೇರಿ|ಬ್ಯಾಂಕ್|ದೇವಸ್ಥಾನ|ಉದ್ಯಾನ"

PLACE_PATTERNS = [
    r"\b(?:at|near|in|from|behind|opposite|beside)\s+(?:" + _KNOWN_CITIES + r")\b",
    r"\b(?:at|near|in|from|behind|opposite|beside)\s+(?:a\s+|the\s+)?(?:" + _VENUE_TYPES + r")\b",
    r"\b(?:at|near|in|from|behind|opposite|beside)\s+[A-Z][a-z]+\s+(?:" + _MULTIWORD_SUFFIXES + r")\b",
    r"\b\w{3,}(?:" + _PLACE_SUFFIXES + r")\b",
    r"\b(?:plot no|door no|flat no|house no|survey no)\.?\s*\d+\b",
    # Hindi place patterns
    r"(?:में|पर|के पास|के सामने)\s+\S+",
    r"(?:" + _HINDI_VENUES + r")",
    # Tamil place patterns
    r"(?:இல்|அருகில்|எதிரில்)\s+\S+",
    r"(?:" + _TAMIL_VENUES + r")",
    # Telugu place patterns
    r"(?:లో|దగ్గర|ఎదురుగా)\s+\S+",
    r"(?:" + _TELUGU_VENUES + r")",
    # Kannada place patterns
    r"(?:ನಲ್ಲಿ|ಹತ್ತಿರ|ಎದುರು)\s+\S+",
    r"(?:" + _KANNADA_VENUES + r")",
]


def check_missing_fields(text: str) -> dict:
    """Check for missing date, time, and place of occurrence."""
    text_lower = text.lower()
    alerts = {}

    has_date = any(re.search(p, text_lower, re.IGNORECASE) for p in DATE_PATTERNS)
    has_time = any(re.search(p, text_lower, re.IGNORECASE) for p in TIME_PATTERNS)
    has_place = any(re.search(p, text, re.IGNORECASE) for p in PLACE_PATTERNS)

    if not has_date:
        alerts["date"] = "[ALERT] Date of occurrence is MISSING. Please provide the date."
    if not has_time:
        alerts["time"] = "[ALERT] Time of occurrence is MISSING. Please provide the time."
    if not has_place:
        alerts["place"] = "[ALERT] Place of occurrence is MISSING. Please provide the location."

    return alerts


# ─── Detail extraction from text ────────────────────────────────────────────
def extract_details_from_text(text: str) -> dict:
    """Extract complainant name, date, time, and place from description text."""
    details = {
        "complainant_name": "",
        "date_of_occurrence": "",
        "time_of_occurrence": "",
        "place_of_occurrence": "",
        "police_station": "",
    }

    text_lower = text.lower()

    # 1. Extract date (find the first valid date pattern)
    for p in DATE_PATTERNS:
        m = re.search(p, text, re.IGNORECASE)
        if m:
            date_str = m.group(0).strip()
            # Basic validation: ignore if it's just a single month name without a number
            if len(date_str) > 2:
                details["date_of_occurrence"] = date_str
                break

    # 2. Extract time
    for p in TIME_PATTERNS:
        m = re.search(p, text, re.IGNORECASE)
        if m:
            details["time_of_occurrence"] = m.group(0).strip()
            break
    
    # 3. Extract place (updated to look for police stations too)
    best_place = ""
    found_ps = ""
    ps_keywords = ["police station", "ps", "station", "தேர்ந்தெடுக்கப்பட்ட காவல் நிலையம்", "कवि स्टेशन", "थाना"]
    for p in PLACE_PATTERNS:
        matches = re.finditer(p, text, re.IGNORECASE)
        for m in matches:
            found = m.group(0).strip()
            # If it's a police station mention, store it specifically
            if any(kw in found.lower() for kw in ps_keywords):
                found_ps = found
            # Cleanup common prefixes like 'at ', 'in ', 'near ' if they are at the start
            cleaned = re.sub(r'^(at|in|near|beside|opposite|behind|from)\s+', '', found, flags=re.I)
            if len(cleaned) > len(best_place):
                best_place = cleaned
    
    details["place_of_occurrence"] = best_place
    
    # Try more specific PS patterns if not found in place patterns
    if not found_ps:
        ps_patterns = [
            r"(?i)\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+(?:Police Station|PS|Station)\b",
            r"(?i)(?:Police Station|PS|Station)\s+(?:of|at)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)",
            # Tamil
            r"([\u0B80-\u0BFF]+)\s+காவல் நிலையம்",
            # Hindi
            r"([\u0900-\u097F]+)\s+थाना",
        ]
        for p in ps_patterns:
            m = re.search(p, text)
            if m:
                found_ps = m.group(0).strip()
                break
    
    details["police_station"] = found_ps

    # 4. Extract complainant name
    # We look for "My name is ...", "I am ...", or just capitalized words at the start/after specific markers
    name_patterns = [
        # English
        r"(?i)(?:my name is|i am|complainant(?:'s)? name is|this is)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})",
        r"(?i)(?:mr\.|mrs\.|ms\.|smt\.|shri|sri)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})",
        # Hindi
        r"(?:मेरा नाम|मैं)\s+([\u0900-\u097F]+(?:\s+[\u0900-\u097F]+)?)\s+(?:हूँ|हूं|है|बोल रहा हूँ|बोल रही हूँ)",
        # Tamil
        r"(?:என் பெயர்|நான்)\s+([\u0B80-\u0BFF]+(?:\s+[\u0B80-\u0BFF]+)?)",
        # Telugu
        r"(?:నా పేరు|నేను)\s+([\u0C00-\u0C7F]+(?:\s+[\u0C00-\u0C7F]+)?)",
        # Kannada
        r"(?:ನನ್ನ ಹೆಸರು|ನಾನು)\s+([\u0C80-\u0CFF]+(?:\s+[\u0C80-\u0CFF]+)?)",
        # Generic start of sentence: "I, [Name], ..."
        r"(?i)^I,\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,2})",
    ]
    
    for p in name_patterns:
        m = re.search(p, text)
        if m:
            name = m.group(1).strip()
            # Simple heuristic: ignore if result is a common stop word or too short
            if len(name) > 2 and name.lower() not in ["the", "this", "that"]:
                details["complainant_name"] = name
                break

    return details


# ─── FIR Draft Generator (Formal Format) ────────────────────────────────────
def generate_fir_draft(
    complainant_name: str,
    description: str,
    sections: list[str],
    date_of_occurrence: str = "Not specified",
    time_of_occurrence: str = "Not specified",
    place_of_occurrence: str = "Not specified",
    police_station: str = "Not specified",
) -> str:
    fir_no = f"FIR-{datetime.now().strftime('%Y%m%d%H%M%S')}"
    filing_date = datetime.now().strftime('%d-%m-%Y')
    filing_time = datetime.now().strftime('%H:%M')
    sections_str = ", ".join(s.upper().replace("_", " ") for s in sections) if sections else "To be determined"

    draft = f"""GOVERNMENT OF INDIA
FIRST INFORMATION REPORT
(Under Section 154 Cr.P.C.)

═══════════════════════════════════════════════════════════════════

1. District: ..................    P.S.: {police_station}
   Year: {datetime.now().year}            FIR No.: {fir_no}
   Date of Filing: {filing_date}    Time: {filing_time}

═══════════════════════════════════════════════════════════════════

2. ACT(S) AND SECTION(S):
   {sections_str}

═══════════════════════════════════════════════════════════════════

3. OCCURRENCE OF OFFENCE:
   (a) Day & Date: {date_of_occurrence}
   (b) Time: {time_of_occurrence}

4. TYPE OF INFORMATION: Written / Oral

5. PLACE OF OCCURRENCE:
   (a) Direction and Distance from P.S.: ..................
   (b) Address: {place_of_occurrence}

═══════════════════════════════════════════════════════════════════

6. COMPLAINANT / INFORMANT:
   (a) Name: {complainant_name}
   (b) Father's / Husband's Name: ..................
   (c) Date / Year of Birth: ..................
   (d) Nationality: Indian
   (e) Occupation: ..................
   (f) Address: ..................

═══════════════════════════════════════════════════════════════════

7. DETAILS OF KNOWN / SUSPECTED / UNKNOWN ACCUSED:
   As per investigation.

═══════════════════════════════════════════════════════════════════

8. REASONS FOR DELAY IN REPORTING BY COMPLAINANT / INFORMANT:
   N/A

═══════════════════════════════════════════════════════════════════

9. PARTICULARS OF PROPERTIES STOLEN / INVOLVED:
   As per complainant's statement.

═══════════════════════════════════════════════════════════════════

10. TOTAL VALUE OF PROPERTY STOLEN:
    As per investigation.

═══════════════════════════════════════════════════════════════════

11. INQUEST REPORT / U.D. CASE NO., IF ANY:
    N/A

═══════════════════════════════════════════════════════════════════

12. DESCRIPTION OF INCIDENT:

{description.strip()}

═══════════════════════════════════════════════════════════════════

13. ACTION TAKEN:
    Since the above information reveals commission of offence(s)
    u/s {sections_str}, registered the case and
    took up the investigation.

═══════════════════════════════════════════════════════════════════

14. SIGNATURE / THUMB IMPRESSION OF
    THE COMPLAINANT / INFORMANT:       ____________________

15. DATE & TIME OF DISPATCH TO
    THE COURT:                         ____________________

═══════════════════════════════════════════════════════════════════

   Signature of Officer-in-Charge,
   Police Station: {police_station}
   Name: ..............................
   Rank: ..............................
   No.: ...............................
   Date: {filing_date}

═══════════════════════════════════════════════════════════════════
NOTE: This is a system-generated draft.
Please verify all details and applicable sections with a legal
expert before filing. This document is for reference only and
does not constitute a legally filed FIR.
═══════════════════════════════════════════════════════════════════"""

    return draft


# ─── IPC Section Info Loader ────────────────────────────────────────────────
def load_section_info(csv_path: str = "ipc_sections.csv") -> dict:
    """Load section descriptions from CSV into a lookup dict."""
    info = {}
    try:
        import pandas as pd
        df = pd.read_csv(csv_path)
        df = df[["Section", "Offense", "Description", "Punishment"]].dropna(subset=["Section"])
        for _, row in df.iterrows():
            key = str(row["Section"]).strip().lower().replace(" ", "_").replace("ipc_", "ipc_")
            desc = str(row["Description"])
            simple = ""
            if "in Simple Words" in desc:
                simple = desc.split("in Simple Words")[-1].strip().lstrip("\n")
            else:
                simple = desc.strip()
            info[key] = {
                "offense": str(row["Offense"]).strip(),
                "description": simple[:600],
                "punishment": str(row["Punishment"]).strip(),
            }
    except Exception as e:
        print(f"[WARN] Could not load section info: {e}")
    return info


SECTION_INFO = load_section_info()


# ─── Main Predictor ─────────────────────────────────────────────────────────
class SectionPredictor:
    def __init__(self, model_path: str = "fir_model.pkl"):
        self.model_path = model_path
        self.model = None
        self.vectorizer = None
        self.label_encoder = None
        self._load_model()

    def _load_model(self):
        try:
            with open(self.model_path, "rb") as f:
                data = pickle.load(f)
            self.model = data["model"]
            self.vectorizer = data["vectorizer"]
            self.label_encoder = data["label_encoder"]
        except FileNotFoundError:
            print(f"[INFO] Model file '{self.model_path}' not found. Run train_model.py first.")

    def predict(self, text: str, top_k: int = 3) -> dict:
        """
        Predict IPC sections from input text.
        Returns rule-based matches, ML predictions, alerts, and merged results.
        """
        # 1. Rule-based
        rule_sections = apply_rules(text)

        # 2. ML-based
        ml_sections = []
        ml_confidence = {}
        if self.model and self.vectorizer and self.label_encoder:
            vec = self.vectorizer.transform([text])
            proba = self.model.predict_proba(vec)[0]
            top_indices = np.argsort(proba)[::-1][:top_k]
            for idx in top_indices:
                if proba[idx] > 0.05:
                    label = self.label_encoder.inverse_transform([idx])[0]
                    ml_sections.append(label)
                    ml_confidence[label] = round(float(proba[idx]) * 100, 2)

        # 3. Merge
        merged = list(dict.fromkeys(rule_sections + ml_sections))

        # 4. Missing field alerts
        alerts = check_missing_fields(text)

        # 5. Extract details for auto-fill
        extracted = extract_details_from_text(text)

        return {
            "rule_based_sections": rule_sections,
            "ml_sections": ml_sections,
            "ml_confidence": ml_confidence,
            "predicted_sections": merged,
            "alerts": alerts,
            "extracted_details": extracted,
        }
