const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Mock data
const products = [
  {
    id: "1",
    name: "Producto 1",
    description: "Descripción del producto 1",
    price: 10.50,
    stock: 100,
    imageUrl: "https://via.placeholder.com/200"
  },
  {
    id: "2", 
    name: "Producto 2",
    description: "Descripción del producto 2",
    price: 15.75,
    stock: 50,
    imageUrl: "https://via.placeholder.com/200"
  }
];

// Login endpoint
app.post('/auth/login', (req, res) => {
  console.log('Login request:', req.body);
  
  // Mock successful login
  res.status(201).json({
    access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock_token_data.signature',
    user: {
      id: 'user-123',
      username: 'usuario_real',
      email: req.body.email,
      role: 'employee'
    }
  });
});

// Products endpoint
app.get('/products', (req, res) => {
  console.log('Products request with headers:', req.headers);
  
  // Check for authorization
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
  
  console.log('Auth token:', authHeader);
  
  // Return products
  res.json({
    data: products,
    total: products.length,
    page: 0,
    limit: 20
  });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Mock server running on http://127.0.0.1:${PORT}`);
});