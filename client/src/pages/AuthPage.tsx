import React, { useState } from 'react';
import { LogIn, UserPlus, Bus } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import { login, signup, storeAuthData } from '../services/authApi';

interface AuthPageProps {
  onLogin: () => void;
}

export default function AuthPage({ onLogin }: AuthPageProps) {
  const [isSignup, setIsSignup] = useState(false);
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    confirmPassword: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Validation
    if (!formData.email || !formData.password) {
      setError('Please enter email and password');
      return;
    }

    if (isSignup) {
      if (!formData.firstName || !formData.lastName) {
        setError('Please enter your name');
        return;
      }

      if (formData.password !== formData.confirmPassword) {
        setError('Passwords do not match');
        return;
      }

      if (formData.password.length < 6) {
        setError('Password must be at least 6 characters long');
        return;
      }
    }

    setLoading(true);
    try {
      if (isSignup) {
        // Signup - Create username from email
        const username = formData.email.split('@')[0];
        const authResponse = await signup({
          username,
          email: formData.email,
          password: formData.password,
          password_confirm: formData.confirmPassword,
          first_name: formData.firstName,
          last_name: formData.lastName,
          user_type: 'admin',
        });

        storeAuthData(authResponse);
        onLogin();
      } else{
        // Login - Send email/phone directly as username (backend will handle)
        const authResponse = await login({
          username: formData.email,
          password: formData.password
        });

        storeAuthData(authResponse);
        onLogin();
      }
    } catch (err: any) {
      const errorMessage = err.response?.data?.error || err.response?.data?.message ||
                          (isSignup ? 'Failed to create account' : 'Invalid credentials');
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const toggleMode = () => {
    setIsSignup(!isSignup);
    setError('');
    setFormData({
      firstName: '',
      lastName: '',
      email: '',
      password: '',
      confirmPassword: '',
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="max-w-2xl w-full">
        {/* Logo and Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-2xl mb-4">
            <Bus className="text-white" size={32} />
          </div>
          <h1 className="text-3xl font-bold text-slate-900 mb-2">AppBasi Admin</h1>
          <p className="text-slate-600">
            {isSignup ? 'Create your admin account' : 'Sign in to manage your bus system'}
          </p>
        </div>

        {/* Auth Form */}
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <form onSubmit={handleSubmit} className="space-y-6">
            {isSignup && (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <Input
                    label="First Name"
                    name="firstName"
                    value={formData.firstName}
                    onChange={handleChange}
                    placeholder="John"
                    required
                  />

                  <Input
                    label="Last Name"
                    name="lastName"
                    value={formData.lastName}
                    onChange={handleChange}
                    placeholder="Doe"
                    required
                  />
                </div>
              </>
            )}

            <Input
              label={isSignup ? "Email Address" : "Email or Phone"}
              name="email"
              type={isSignup ? "email" : "text"}
              value={formData.email}
              onChange={handleChange}
              placeholder={isSignup ? "admin@example.com" : "Email or phone number"}
              required
            />

            {isSignup ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <Input
                  label="Password"
                  name="password"
                  type="password"
                  value={formData.password}
                  onChange={handleChange}
                  placeholder="Min. 6 characters"
                  required
                />

                <Input
                  label="Confirm Password"
                  name="confirmPassword"
                  type="password"
                  value={formData.confirmPassword}
                  onChange={handleChange}
                  placeholder="Re-enter password"
                  required
                />
              </div>
            ) : (
              <Input
                label="Password"
                name="password"
                type="password"
                value={formData.password}
                onChange={handleChange}
                placeholder="Enter your password"
                required
              />
            )}

            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <Button
              type="submit"
              className="w-full"
              disabled={loading}
            >
              {loading ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  {isSignup ? 'Creating account...' : 'Signing in...'}
                </span>
              ) : (
                <span className="flex items-center justify-center">
                  {isSignup ? <UserPlus className="mr-2" size={20} /> : <LogIn className="mr-2" size={20} />}
                  {isSignup ? 'Create Account' : 'Sign In'}
                </span>
              )}
            </Button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-slate-600">
              {isSignup ? 'Already have an account?' : "Don't have an account?"}{' '}
              <button
                onClick={toggleMode}
                className="text-blue-600 font-medium hover:text-blue-700"
              >
                {isSignup ? 'Sign in' : 'Sign up'}
              </button>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
