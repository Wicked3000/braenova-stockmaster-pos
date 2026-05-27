from datetime import datetime

expiry_yymmdd = '260626'
expiry_dt = datetime.strptime(f"20{expiry_yymmdd}", "%Y%m%d").date()
today_dt = datetime.now().date()
days_left = (expiry_dt - today_dt).days

print("Expiry DT:", expiry_dt)
print("Today DT:", today_dt)
print("Days Left:", days_left)
