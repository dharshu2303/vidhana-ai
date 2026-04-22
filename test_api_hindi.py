import requests
import json

url = "http://localhost:8000/predict"
payload = {"text": "मेरा नाम अजय है और कल रात मेरी साइकिल अन्ना नगर रेलवे स्टेशन के पास चोरी हो गई।"}
response = requests.post(url, json=payload)
with open('test_api_hindi_out.json', 'w', encoding='utf-8') as f:
    json.dump(response.json(), f, ensure_ascii=False, indent=2)
