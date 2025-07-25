from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

app = FastAPI(title="Pritchard Stock API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_KEY")
)

class StockNumberCreate(BaseModel):
    location_code: str
    department: str
    condition: str
    order_id: Optional[str] = None
    notes: Optional[str] = None

@app.get("/")
async def root():
    return {"message": "Pritchard Stock Number System API"}

@app.post("/api/generate-stock-number")
async def generate_stock_number(data: StockNumberCreate):
    try:
        # Get current year code
        from datetime import datetime
        year = datetime.now().year
        year_code = chr(ord('A') + (year - 2025))
        
        # Call Supabase function
        result = supabase.rpc('get_next_stock_number', {
            'p_location_code': data.location_code,
            'p_department': data.department,
            'p_year_code': year_code,
            'p_condition': data.condition
        }).execute()
        
        stock_number = result.data
        
        # Insert record
        insert_result = supabase.table('stock_numbers').insert({
            'stock_number': stock_number,
            'location_code': data.location_code,
            'department': data.department,
            'year_code': year_code,
            'condition': data.condition,
            'sequential_number': int(stock_number[-5:]),
            'status': 'available',
            'order_id': data.order_id,
            'notes': data.notes
        }).execute()
        
        return {
            "stock_number": stock_number,
            "data": insert_result.data[0] if insert_result.data else None
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/api/stock-numbers")
async def get_stock_numbers(
    location_code: Optional[str] = None,
    department: Optional[str] = None,
    status: Optional[str] = None
):
    query = supabase.table('stock_numbers_detailed').select('*')
    
    if location_code:
        query = query.eq('location_code', location_code)
    if department:
        query = query.eq('department', department)
    if status:
        query = query.eq('status', status)
    
    result = query.order('created_at', desc=True).execute()
    return result.data

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
