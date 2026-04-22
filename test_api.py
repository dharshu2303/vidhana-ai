import requests

url = "http://localhost:8000/predict"
payload = {"text": "My name is John Doe. Yesterday night I was near Anna Nagar Police Station and someone stole my phone."}
response = requests.post(url, json=payload)
print(response.json())
