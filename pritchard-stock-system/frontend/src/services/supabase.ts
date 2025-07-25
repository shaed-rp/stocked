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
