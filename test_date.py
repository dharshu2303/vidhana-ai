import re

_monthMap = {
  'january': 1, 'february': 2, 'march': 3, 'april': 4,
  'may': 5, 'june': 6, 'july': 7, 'august': 8,
  'september': 9, 'october': 10, 'november': 11, 'december': 12,
}

def extract_date(description):
    patterns = [
        re.compile(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b'),
        re.compile(r'\b(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})\b', re.IGNORECASE),
        re.compile(r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})[,\s]+(\d{4})\b', re.IGNORECASE),
    ]
    for p in patterns:
        m = p.search(description)
        if m:
            return m.group(0)
    return None

def parse_date(s):
    s = s.strip()
    m = re.search(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})', s)
    if m:
        return (int(m.group(3)), int(m.group(2)), int(m.group(1)))
    return None

desc = "On 15/05/2026, the accused forcefully took possession of the complainant's property and threatened him with dire consequences if he resisted."
extracted = extract_date(desc)
print(f"Extracted date : {extracted}")
parsed = parse_date(extracted) if extracted else None
print(f"Parsed date    : {parsed}")

from datetime import date
today = date.today()
if parsed:
    d = date(parsed[0], parsed[1], parsed[2])
    print(f"Today          : {today}")
    print(f"Is future      : {d > today}")
