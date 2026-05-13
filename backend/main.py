from fastapi import FastAPI
from app.infra.db import engine, Base
from app.api.router import router
from app.core import models

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="CIRO")
app.include_router(router, prefix="/api")

@app.get("/")
def root():
    return {"msg": "CIRO API"}
