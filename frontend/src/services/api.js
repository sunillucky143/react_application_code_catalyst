import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

export const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Posts API
export const postsApi = {
  getAll: (page = 1, limit = 10) => 
    api.get(`/api/posts/?skip=${(page - 1) * limit}&limit=${limit}`),
  
  getById: (id) => 
    api.get(`/api/posts/${id}`),
  
  create: (postData) => 
    api.post('/api/posts/', postData),
  
  update: (id, postData) => 
    api.put(`/api/posts/${id}`, postData),
  
  delete: (id) => 
    api.delete(`/api/posts/${id}`),
};

// Auth API
export const authApi = {
  login: (credentials) => 
    api.post('/api/auth/login', credentials),
  
  signup: (userData) => 
    api.post('/api/auth/signup', userData),
};

// Users API
export const usersApi = {
  getProfile: () => 
    api.get('/api/users/me'),
  
  updateProfile: (userData) => 
    api.put('/api/users/me', userData),
};

export default api; 