================================================================
  FIR SECTION PREDICTOR - SETUP GUIDE
================================================================

REQUIREMENTS
------------
- Python 3.11+
- Flutter SDK (https://flutter.dev/docs/get-started/install)
- Google Chrome (for web) or Android device

PYTHON DEPENDENCIES
-------------------
Run this once:
  pip install fastapi uvicorn scikit-learn pandas numpy

IF fir_model.pkl IS MISSING, retrain the model:
  python train_model.py

================================================================
HOW TO RUN
================================================================

STEP 1 - Start the backend API (Terminal 1):
  cd crime-ocr-project
  python -m uvicorn api:app --reload

  API will run at: http://127.0.0.1:8000
  Health check:   http://127.0.0.1:8000/health

STEP 2 - Run the Flutter app (Terminal 2):
  cd crime-ocr-project/fir_app
  flutter pub get
  flutter run -d chrome        (web browser)
  flutter run -d windows       (Windows desktop)
  flutter run                  (connected Android device)

NOTE FOR ANDROID DEVICE:
  Open fir_app/lib/api_service.dart
  Change baseUrl from '127.0.0.1' to your machine's local IP
  Example: 'http://192.168.1.5:8000'

================================================================
PROJECT STRUCTURE
================================================================

crime-ocr-project/
  api.py                  - FastAPI backend server
  section_predictor.py    - IPC section prediction logic
  train_model.py          - Model training script
  ipc_sections.csv        - IPC sections dataset
  fir_model.pkl           - Trained ML model
  fir_app/                - Flutter mobile/web app
    lib/
      main.dart           - App entry point
      api_service.dart    - HTTP client
      predict_screen.dart - Incident description input screen
      fir_form_screen.dart- FIR details form screen
      fir_draft_screen.dart- Generated FIR draft screen
    pubspec.yaml          - Flutter dependencies

================================================================
USAGE
================================================================

1. Enter incident description in the text box
2. Tap "Predict IPC Sections" to get matched IPC sections
3. Review alerts for any missing fields (date/time/place)
4. Tap "Generate FIR Draft"
5. Fill in complainant name, police station, etc.
6. Tap "Generate" to see the formatted FIR draft
7. Use the copy button to copy the draft to clipboard

================================================================
