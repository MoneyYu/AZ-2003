import os, time, requests
quote_url = os.getenv('QUOTE_URL', 'http://fubon-quote-api:8000/quote?age=40&coverage=1500000&term=20')
retries = int(os.getenv('RETRIES','3'))
wait = float(os.getenv('WAIT_SECONDS','2'))

for i in range(retries):
    try:
        r = requests.get(quote_url, timeout=10)
        print('status', r.status_code)
        print(r.text)
        r.raise_for_status()
        break
    except Exception as e:
        print('error', e)
        if i == retries-1:
            raise
        time.sleep(wait)

print('job completed')
