
import requests
from secrets import alphavantage_api_key


r = requests.get('https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=IBM&interval=5min&outputsize=full&apikey=alphavantage_api_key')


print(r.status_code)

