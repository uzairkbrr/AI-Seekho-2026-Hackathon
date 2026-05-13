from fastapi import FastAPI
from sqlalchemy import inspect, text
from app.infra.db import engine, Base
from app.api.router import router
from app.core import models

models.Base.metadata.create_all(bind=engine)


def _add_missing_columns(engine, table, columns):
    insp = inspect(engine)
    if table not in insp.get_table_names():
        return
    existing = {c["name"] for c in insp.get_columns(table)}
    with engine.begin() as conn:
        for name, ddl in columns.items():
            if name not in existing:
                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {name} {ddl}"))


_add_missing_columns(
    engine,
    "agent_traces",
    {"prompt": "TEXT", "decision": "TEXT"},
)

app = FastAPI(title="CIRO")
app.include_router(router, prefix="/api")

@app.get("/")
def root():
    return {"msg": "CIRO API"}
