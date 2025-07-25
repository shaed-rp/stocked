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
