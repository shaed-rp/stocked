#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Setting up Pritchard Stock Number System${NC}"

# Create main project directory
mkdir -p pritchard-stock-system
cd pritchard-stock-system

# Create .env file with your Supabase credentials
cat > .env << 'EOL'
# Supabase Configuration
SUPABASE_URL=https://snbmeychvfqbmqblezpw.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNuYm1leWNodmZxYm1xYmxlenB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMjA5MjgsImV4cCI6MjA2ODc5NjkyOH0.5QNuG84eLpbipcV-x2UG6j_jigHZYo1U54QKTQudJ1I
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNuYm1leWNodmZxYm1xYmxlenB3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzIyMDkyOCwiZXhwIjoyMDY4Nzk2OTI4fQ.ucLUhPue3r7SvPyXO2j6l6UAodx8bw6917LZBzYyQq8

# React App
REACT_APP_SUPABASE_URL=https://snbmeychvfqbmqblezpw.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNuYm1leWNodmZxYm1xYmxlenB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMjA5MjgsImV4cCI6MjA2ODc5NjkyOH0.5QNuG84eLpbipcV-x2UG6j_jigHZYo1U54QKTQudJ1I
REACT_APP_API_URL=http://localhost:8000
EOL

# Initialize git
git init
echo -e "${GREEN}✓ Created .env file and initialized Git${NC}"

# Create React frontend
echo -e "${BLUE}Creating React frontend...${NC}"
npx create-react-app@latest frontend --template typescript --use-npm

cd frontend

# Install dependencies
echo -e "${BLUE}Installing frontend dependencies...${NC}"
npm install --save \
  @supabase/supabase-js \
  @mui/material @emotion/react @emotion/styled @mui/icons-material \
  react-router-dom \
  react-hot-toast \
  axios

# Copy env file
cp ../.env .env.local

# Create basic project structure
mkdir -p src/{components,services,types,utils}

# Create Supabase client
cat > src/services/supabase.ts << 'EOL'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL!
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Types
export interface StockNumber {
  id?: number
  stock_number: string
  location_code: string
  department: string
  year_code: string
  condition: string
  sequential_number: number
  status: string
  order_id?: string
  notes?: string
  created_at?: string
  updated_at?: string
}

// Stock Number Service
export const stockNumberService = {
  async generateStockNumber(
    locationCode: string,
    department: string,
    condition: string
  ): Promise<string> {
    const { data, error } = await supabase.rpc('get_next_stock_number', {
      p_location_code: locationCode,
      p_department: department,
      p_year_code: String.fromCharCode(65 + (new Date().getFullYear() - 2025)),
      p_condition: condition
    })

    if (error) throw error
    return data
  },

  async createStockNumber(stockNumber: string, details: any): Promise<StockNumber> {
    const { data, error } = await supabase
      .from('stock_numbers')
      .insert({
        stock_number: stockNumber,
        location_code: details.locationCode,
        department: details.department,
        year_code: details.yearCode,
        condition: details.condition,
        sequential_number: parseInt(stockNumber.slice(-5)),
        status: 'available',
        order_id: details.orderID,
        notes: details.notes
      })
      .select()
      .single()

    if (error) throw error
    return data
  },

  async getStockNumbers(filters?: any): Promise<StockNumber[]> {
    let query = supabase
      .from('stock_numbers_detailed')
      .select('*')
      .order('created_at', { ascending: false })

    if (filters?.location_code) {
      query = query.eq('location_code', filters.location_code)
    }
    if (filters?.department) {
      query = query.eq('department', filters.department)
    }
    if (filters?.status) {
      query = query.eq('status', filters.status)
    }

    const { data, error } = await query

    if (error) throw error
    return data || []
  },

  async updateStatus(stockNumber: string, status: string, notes?: string): Promise<StockNumber> {
    const { data, error } = await supabase
      .from('stock_numbers')
      .update({ 
        status, 
        notes,
        updated_at: new Date().toISOString()
      })
      .eq('stock_number', stockNumber)
      .select()
      .single()

    if (error) throw error
    return data
  }
}
EOL

# Create constants
cat > src/utils/constants.ts << 'EOL'
export const LOCATIONS = {
  'CL': 'Lake Chevrolet',
  'CF': 'Pritchard Ford of Clear Lake',
  'MC': 'Pritchard Motor Company of Mason City',
  'MG': 'Pritchard GMC',
  'MN': 'Pritchard Nissan',
  'FC': 'Chrysler of Forest City',
  'FG': 'Forest City Auto Center',
  'BR': 'Pritchard Auto Britt',
  'GR': 'Pritchard Auto Garner'
}

export const DEPARTMENTS = {
  'R': 'Retail',
  'F': 'Fleet/Commercial',
  'A': 'All-Four/NIE'
}

export const CONDITIONS = {
  'N': 'New',
  'U': 'Used',
  'C': 'CPO (Certified Pre-Owned)',
  'D': 'Demo/Loaner'
}

export const STOCK_STATUS = {
  'available': 'Available',
  'reserved': 'Reserved',
  'cancelled': 'Cancelled',
  'transferred': 'Transferred'
}
EOL

# Create main App component
cat > src/App.tsx << 'EOL'
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { Toaster } from 'react-hot-toast';
import { Container, AppBar, Toolbar, Typography, Box } from '@mui/material';
import StockNumberGenerator from './components/StockNumberGenerator';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1F4993', // Pritchard Blue
    },
    secondary: {
      main: '#414042', // Pritchard Gray
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Box sx={{ flexGrow: 1 }}>
          <AppBar position="static">
            <Toolbar>
              <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                🚗 Pritchard Stock Number System
              </Typography>
            </Toolbar>
          </AppBar>
          <Container maxWidth="lg" sx={{ mt: 4 }}>
            <Routes>
              <Route path="/" element={<StockNumberGenerator />} />
            </Routes>
          </Container>
        </Box>
        <Toaster position="top-right" />
      </Router>
    </ThemeProvider>
  );
}

export default App;
EOL

# Create Stock Number Generator component
cat > src/components/StockNumberGenerator.tsx << 'EOL'
import React, { useState } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Grid,
  TextField,
  Button,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Box,
  Alert,
  CircularProgress,
  Paper
} from '@mui/material';
import toast from 'react-hot-toast';
import { stockNumberService } from '../services/supabase';
import { LOCATIONS, DEPARTMENTS, CONDITIONS } from '../utils/constants';

const StockNumberGenerator: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    locationCode: '',
    department: '',
    condition: '',
    orderID: '',
    notes: ''
  });
  const [generatedNumber, setGeneratedNumber] = useState<string>('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.locationCode || !formData.department || !formData.condition) {
      toast.error('Please fill in all required fields');
      return;
    }

    setLoading(true);
    try {
      // Generate stock number
      const stockNumber = await stockNumberService.generateStockNumber(
        formData.locationCode,
        formData.department,
        formData.condition
      );

      // Create record
      await stockNumberService.createStockNumber(stockNumber, {
        ...formData,
        yearCode: String.fromCharCode(65 + (new Date().getFullYear() - 2025))
      });

      setGeneratedNumber(stockNumber);
      toast.success('Stock number generated successfully!');
      
      // Reset form
      setFormData({
        locationCode: '',
        department: '',
        condition: '',
        orderID: '',
        notes: ''
      });
    } catch (error: any) {
      toast.error(error.message || 'Failed to generate stock number');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Generate Stock Number
      </Typography>
      
      <Card>
        <CardContent>
          <form onSubmit={handleSubmit}>
            <Grid container spacing={3}>
              <Grid item xs={12} md={4}>
                <FormControl fullWidth required>
                  <InputLabel>Location</InputLabel>
                  <Select
                    value={formData.locationCode}
                    label="Location"
                    onChange={(e) => setFormData({ ...formData, locationCode: e.target.value })}
                  >
                    {Object.entries(LOCATIONS).map(([code, name]) => (
                      <MenuItem key={code} value={code}>
                        {code} - {name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} md={4}>
                <FormControl fullWidth required>
                  <InputLabel>Department</InputLabel>
                  <Select
                    value={formData.department}
                    label="Department"
                    onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                  >
                    {Object.entries(DEPARTMENTS).map(([code, name]) => (
                      <MenuItem key={code} value={code}>
                        {code} - {name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} md={4}>
                <FormControl fullWidth required>
                  <InputLabel>Condition</InputLabel>
                  <Select
                    value={formData.condition}
                    label="Condition"
                    onChange={(e) => setFormData({ ...formData, condition: e.target.value })}
                  >
                    {Object.entries(CONDITIONS).map(([code, name]) => (
                      <MenuItem key={code} value={code}>
                        {code} - {name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Order ID (Optional)"
                  value={formData.orderID}
                  onChange={(e) => setFormData({ ...formData, orderID: e.target.value })}
                />
              </Grid>

              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Notes (Optional)"
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  multiline
                  rows={1}
                />
              </Grid>

              <Grid item xs={12}>
                <Button
                  type="submit"
                  variant="contained"
                  size="large"
                  fullWidth
                  disabled={loading}
                >
                  {loading ? <CircularProgress size={24} /> : 'Generate Stock Number'}
                </Button>
              </Grid>
            </Grid>
          </form>

          {generatedNumber && (
            <Paper 
              elevation={3} 
              sx={{ 
                mt: 3, 
                p: 3, 
                backgroundColor: '#1F4993',
                color: 'white',
                textAlign: 'center'
              }}
            >
              <Typography variant="h6">Generated Stock Number:</Typography>
              <Typography variant="h3" sx={{ fontFamily: 'monospace', mt: 1 }}>
                {generatedNumber}
              </Typography>
            </Paper>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default StockNumberGenerator;
EOL

cd ..

# Create simple FastAPI backend
echo -e "${BLUE}Creating FastAPI backend...${NC}"
mkdir backend
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate || . venv/Scripts/activate

# Create requirements.txt
cat > requirements.txt << 'EOL'
fastapi==0.104.1
uvicorn[standard]==0.24.0
supabase==2.3.0
python-dotenv==1.0.0
pydantic==2.5.0
EOL

# Install dependencies
pip install -r requirements.txt

# Create main.py
cat > main.py << 'EOL'
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
EOL

cd ..

echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${YELLOW}To start the application:${NC}"
echo ""
echo "1. Start the backend:"
echo "   cd backend"
echo "   source venv/bin/activate"
echo "   python main.py"
echo ""
echo "2. In a new terminal, start the frontend:"
echo "   cd frontend"
echo "   npm start"
echo ""
echo "3. Open http://localhost:3000 in your browser"