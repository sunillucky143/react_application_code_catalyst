import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from '../context/AuthContext';
import App from '../App';

// Mock the API service
jest.mock('../services/api', () => ({
  api: {
    interceptors: {
      request: { use: jest.fn() },
      response: { use: jest.fn() }
    }
  },
  postsApi: {
    getAll: jest.fn(),
    getById: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn()
  },
  authApi: {
    login: jest.fn(),
    signup: jest.fn()
  },
  usersApi: {
    getProfile: jest.fn(),
    updateProfile: jest.fn()
  }
}));

const renderWithProviders = (component) => {
  return render(
    <BrowserRouter>
      <AuthProvider>
        {component}
      </AuthProvider>
    </BrowserRouter>
  );
};

describe('App Component', () => {
  test('renders without crashing', () => {
    renderWithProviders(<App />);
    expect(screen.getByText(/BlogApp/i)).toBeInTheDocument();
  });

  test('renders navigation links', () => {
    renderWithProviders(<App />);
    expect(screen.getByText(/Home/i)).toBeInTheDocument();
    expect(screen.getByText(/Login/i)).toBeInTheDocument();
    expect(screen.getByText(/Sign Up/i)).toBeInTheDocument();
  });
}); 