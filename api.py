import io
import re
import cv2
import numpy as np
import pytesseract
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from section_predictor import SectionPredictor, generate_fir_draft, SECTION_INFO, extract_details_from_text

pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

app = FastAPI(title="Vidhana AI — FIR Legal Assistant API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

predictor = SectionPredictor("fir_model.pkl")

# ─── Translation helper ─────────────────────────────────────────────────────
_deep_translator_available = False

try:
    from deep_translator import GoogleTranslator
    from langdetect import detect as langdetect_detect
    _deep_translator_available = True
except ImportError:
    print("[WARN] deep-translator / langdetect not installed. Translation disabled.")
    print("[WARN] Install with: pip install deep-translator langdetect")


def _detect_language(text: str) -> str:
    """Detect the language of the given text."""
    if not _deep_translator_available:
        return "en"
    try:
        lang = langdetect_detect(text)
        return lang if lang else "en"
    except Exception:
        return "en"


def _detect_and_translate(text: str) -> tuple[str, str, str]:
    """Detect language and translate to English if needed.
    Returns (translated_text, detected_language, original_text).
    """
    if not _deep_translator_available:
        return text, "en", text

    try:
        lang = _detect_language(text)

        # If already English, return as-is
        if lang == "en":
            return text, "en", text

        # Translate to English
        translated = GoogleTranslator(source=lang, target="en").translate(text)
        return translated or text, lang, text
    except Exception as e:
        print(f"[WARN] Translation error: {e}")
        return text, "en", text


def _translate_to(text: str, target_lang: str) -> tuple[str, str, str]:
    """Translate text to a specific target language.
    Returns (translated_text, detected_language, original_text).
    """
    if not _deep_translator_available:
        return text, "en", text

    try:
        lang = _detect_language(text)

        # If already in target language, return as-is
        if lang == target_lang:
            return text, lang, text

        translated = GoogleTranslator(source=lang, target=target_lang).translate(text)
        return translated or text, lang, text
    except Exception as e:
        print(f"[WARN] Translation error: {e}")
        return text, "en", text


# ─── Request models ─────────────────────────────────────────────────────────
class PredictRequest(BaseModel):
    text: str
    top_k: int = 3


class FIRRequest(BaseModel):
    complainant_name: str
    description: str
    sections: list[str]
    date_of_occurrence: str = "Not specified"
    time_of_occurrence: str = "Not specified"
    place_of_occurrence: str = "Not specified"
    police_station: str = "Not specified"


class TranslateRequest(BaseModel):
    text: str
    target_lang: str = "en"


# ─── Endpoints ───────────────────────────────────────────────────────────────
@app.post("/predict")
def predict(req: PredictRequest):
    original_text = req.text

    # Step 1: Translate non-English text to English for prediction
    translated_text, detected_lang, _ = _detect_and_translate(req.text)

    # Step 2: Run prediction on both original and translated text
    # Use translated for ML model, original for rule-based (has multi-language keywords)
    result = predictor.predict(req.text, req.top_k)

    # Also run ML on translated text and merge
    if detected_lang != "en" and translated_text != req.text:
        translated_result = predictor.predict(translated_text, req.top_k)
        # Merge sections: keep original results, add translated ones
        all_sections = list(dict.fromkeys(
            result["predicted_sections"] + translated_result["predicted_sections"]
        ))
        result["predicted_sections"] = all_sections

        # Merge ML confidence
        for k, v in translated_result["ml_confidence"].items():
            if k not in result["ml_confidence"]:
                result["ml_confidence"][k] = v

        # Replace UI alerts with translated_result alerts using English text which guarantees robust missing-field grammar detection
        result["alerts"] = translated_result.get("alerts", {})

        # Extract details from both original and translated
        translated_details = extract_details_from_text(translated_text)
        original_details = result.get("extracted_details", {})

        # Always prefer translated details (English logic is robust and captures full phrases),
        # but fallback to original if translation failed to extract specifically.
        for key in translated_details:
            if translated_details[key]:
                original_details[key] = translated_details[key]
        result["extracted_details"] = original_details

    result["detected_language"] = detected_lang
    result["translated_text"] = translated_text
    return result


@app.post("/generate_fir")
def generate_fir(req: FIRRequest):
    draft = generate_fir_draft(
        complainant_name=req.complainant_name,
        description=req.description,
        sections=req.sections,
        date_of_occurrence=req.date_of_occurrence,
        time_of_occurrence=req.time_of_occurrence,
        place_of_occurrence=req.place_of_occurrence,
        police_station=req.police_station,
    )
    return {"draft": draft}


@app.get("/section_info/{section}")
def section_info(section: str):
    key = section.strip().lower()
    info = SECTION_INFO.get(key)
    if not info:
        return {"offense": "", "description": "No description available.", "punishment": ""}
    return info


@app.post("/translate")
def translate(req: TranslateRequest):
    """Translate text to target language (default: English)."""
    if req.target_lang == "en":
        translated, detected_lang, original = _detect_and_translate(req.text)
    else:
        translated, detected_lang, original = _translate_to(req.text, req.target_lang)
    return {
        "original": original,
        "translated": translated,
        "detected_language": detected_lang,
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/ocr")
async def ocr_extract(file: UploadFile = File(...)):
    """Extract text from an uploaded image using Tesseract OCR."""
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            return {"text": "", "error": "Could not decode image"}

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        gray = cv2.medianBlur(gray, 3)
        gray = cv2.adaptiveThreshold(
            gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
        )

        text = pytesseract.image_to_string(gray, lang="eng")
        data = pytesseract.image_to_data(gray, output_type=pytesseract.Output.DICT)
        confidences = [int(c) for c in data["conf"] if int(c) > 0]
        avg_conf = round(sum(confidences) / len(confidences), 1) if confidences else 0

        return {"text": text.strip(), "confidence": avg_conf}
    except Exception as e:
        return {"text": "", "error": str(e)}
