import React, { useEffect } from 'react';
import { Stack, useRouter } from 'expo-router';
import { AuthProvider, useAuth } from '../src/contexts/AuthContext';

function NavigationHandler() {
  const { user, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && user) {
      // Auto-redirect based on user role
      switch (user.role) {
        case 'parent':
          router.replace('/(parent)/dashboard');
          break;
        case 'busminder':
          router.replace('/(busminder)/dashboard');
          break;
        case 'driver':
          router.replace('/(driver)/dashboard');
          break;
      }
    }
  }, [user, isLoading]);

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="index" />
      <Stack.Screen name="(parent)" />
      <Stack.Screen name="(busminder)" />
      <Stack.Screen name="(driver)" />
    </Stack>
  );
}

export default function RootLayout() {
  return (
    <AuthProvider>
      <NavigationHandler />
    </AuthProvider>
  );
}
