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
