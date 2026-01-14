from fastapi import FastAPI
from pydantic import BaseModel
import os, math, datetime

app = FastAPI(title="Fubon Quote API", version=os.getenv("APP_VERSION","1.0.0"))

class QuoteResponse(BaseModel):
    age: int
    coverage: int
    term: int
    annual_premium: int
    currency: str = "TWD"
    risk_band: str
    factors: dict
    meta: dict

@app.get("/health")
def health():
    return {"status":"ok","time":datetime.datetime.utcnow().isoformat()+"Z"}

@app.get("/quote", response_model=QuoteResponse)
def quote(age: int = 35, coverage: int = 1000000, term: int = 20):
    base_rate = float(os.getenv("BASE_RATE", "0.0026"))
    age_factor = 1.0 + max(0, (age - 30)) * 0.018
    term_factor = 1.0 + max(0, (term - 10)) * 0.012
    pricing_factor = float(os.getenv("PRICING_FACTOR", "1.00"))
    raw = coverage * base_rate * age_factor * term_factor * pricing_factor
    annual = int(math.ceil(raw / 10.0) * 10)
    band = "A" if age < 35 else ("B" if age < 50 else "C")
    meta = {
        "service": "quote-api",
        "version": os.getenv("APP_VERSION","1.0.0"),
        "revision": os.getenv("CONTAINER_APP_REVISION","local"),
        "label": os.getenv("DEPLOYMENT_LABEL","local"),
        "received": datetime.datetime.utcnow().isoformat()+"Z",
    }
    return QuoteResponse(
        age=age, coverage=coverage, term=term,
        annual_premium=annual, risk_band=band,
        factors={
            "base_rate": base_rate,
            "age_factor": round(age_factor, 4),
            "term_factor": round(term_factor, 4),
            "pricing_factor": pricing_factor,
        },
        meta=meta,
    )
