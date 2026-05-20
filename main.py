from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()
templates = Jinja2Templates(directory="templates")


def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        port=os.getenv("DB_PORT", 5432)
    )
    return conn


@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse(request=request, name="index.html")


@app.post("/add")
async def add_contact(name: str = Form(...), location: str = Form(...)):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO contacts (name, location) VALUES (%s, %s)",
        (name, location)
    )
    conn.commit()
    cursor.close()
    conn.close()
    return RedirectResponse(url="/contacts", status_code=303)


@app.get("/contacts", response_class=HTMLResponse)
async def view_contacts(request: Request):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, location, created_at FROM contacts ORDER BY created_at DESC")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()

    contacts = [
        {"id": row[0], "name": row[1], "location": row[2], "created_at": row[3]}
        for row in rows
    ]
    return templates.TemplateResponse(request=request, name="view.html", context={"contacts": contacts})