from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from asyncpg import create_pool
import uvicorn
import os

app = FastAPI()

DB_URL = "postgresql://David:123@localhost:5432/Pharmasy_Chain_DB"
pool = None

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    global pool
    pool = await create_pool(dsn=DB_URL)

@app.on_event("shutdown")
async def shutdown():
    await pool.close()

@app.post("/process_sale_transaction/")
async def process_sale_transaction(sold_quantity: int, branch_id: int, medication_id: int, customer_id: int, employee_id: int):
    async with pool.acquire() as connection:
        try:
            await connection.execute(
                """
                SELECT process_sale_transaction($1, $2, $3, $4, $5);
                """,
                sold_quantity, branch_id, medication_id, customer_id, employee_id
            )
            return {"status": "Transaction processed successfully"}
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)