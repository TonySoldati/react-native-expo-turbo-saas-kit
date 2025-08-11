import { useEffect } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';

import { Redirect, Tabs, router } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';

import {
  AuthProvider,
  AuthProviderLoading,
  AuthProviderSignedIn,
  AuthProviderSignedOut,
} from '@kit/supabase';

void SplashScreen.preventAutoHideAsync();

export default function MainLayout() {
  return (
    <AuthProvider>
      <AuthProviderLoading>
        <SplashScreenLoading />
      </AuthProviderLoading>

      <AuthProviderSignedIn>
        <MainLayoutTabs />
      </AuthProviderSignedIn>

      <AuthProviderSignedOut>
        <Redirect href={'/auth/sign-in'} />
      </AuthProviderSignedOut>
    </AuthProvider>
  );
}

function MainLayoutTabs() {
  return (
    <Tabs 
      initialRouteName={'index'}
      screenOptions={{
        headerShown: false,
        tabBarStyle: { display: 'none' }, // Hide default tab bar
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          href: '/',
        }}
      />

      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          href: '/settings',
        }}
      />
    </Tabs>
  );
}

// Custom Tab Bar Component
export function CustomTabBar({ onCreatePost }: { onCreatePost?: () => void }) {
  const handleHomePress = () => {
    router.push('/');
  };

  const handleCreatePress = () => {
    if (onCreatePost) {
      onCreatePost();
    } else {
      console.log('Create pressed');
    }
  };

  const handleSettingsPress = () => {
    router.push('/settings');
  };

  return (
    <View className="h-16 bg-background border-t border-border flex-row items-center justify-around px-4">
      {/* Home Button */}
      <TouchableOpacity 
        onPress={handleHomePress}
        className="flex-1 items-center justify-center"
      >
        <Text className="text-lg">🏠</Text>
        <Text className="text-xs text-muted-foreground">Home</Text>
      </TouchableOpacity>

      {/* Create Post Button */}
      <TouchableOpacity 
        onPress={handleCreatePress}
        className="flex-1 items-center justify-center"
      >
        <View className="w-12 h-12 bg-primary rounded-full items-center justify-center">
          <Text className="text-xl font-bold text-primary-foreground">+</Text>
        </View>
        <Text className="text-xs text-muted-foreground mt-1">Create</Text>
      </TouchableOpacity>

      {/* Settings Button */}
      <TouchableOpacity 
        onPress={handleSettingsPress}
        className="flex-1 items-center justify-center"
      >
        <Text className="text-lg">⚙️</Text>
        <Text className="text-xs text-muted-foreground">Settings</Text>
      </TouchableOpacity>
    </View>
  );
}

function SplashScreenLoading() {
  useEffect(() => {
    return () => {
      void SplashScreen.hideAsync();
    };
  });

  return null;
}
