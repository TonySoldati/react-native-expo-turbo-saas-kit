import React, { useState } from 'react';
import { View, Modal, Alert, ScrollView, Image, Text, TouchableOpacity } from 'react-native';
import { FeedList, CreatePostForm } from '@kit/feed';
import { CustomTabBar } from './_layout';
import { useSupabase } from '@kit/supabase';
import { useQuery } from '@tanstack/react-query';
import type { LogActivite } from '@kit/feed';

type StoryData = {
  id: string;
  title: string;
  image_url: string;
  accounts: {
    name: string;
    picture_url: string | null;
  } | null;
};

// Stories Component
function Stories() {
  const supabase = useSupabase();

  // Fetch log activities for stories
  const { data: stories, isLoading, error } = useQuery({
    queryKey: ['stories'],
    queryFn: async () => {
      try {
        const { data, error } = await supabase
          .from('log_activites')
          .select(`
            id,
            title,
            image_url,
            accounts!log_activites_account_id_fkey (
              name,
              picture_url
            )
          `)
          .not('image_url', 'is', null)
          .order('created_at', { ascending: false })
          .limit(10);

        if (error) {
          console.error('Stories query error:', error);
          return [];
        }
        return data as StoryData[] || [];
      } catch (err) {
        console.error('Stories fetch error:', err);
        return [];
      }
    },
  });

  const handleStoryPress = (story: StoryData) => {
    console.log('Story pressed:', story.title);
    // TODO: Navigate to story view or open story modal
  };

  if (isLoading) {
    return (
      <View className="py-4 bg-background">
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          {[1, 2, 3, 4, 5].map((i) => (
            <View key={i} className="w-32 h-48 mx-2 bg-gray-200 rounded-lg animate-pulse" />
          ))}
        </ScrollView>
      </View>
    );
  }

  if (error) {
    console.error('Stories error:', error);
    return (
      <View className="py-4 bg-background">
        <Text className="text-center text-muted-foreground">Failed to load stories</Text>
      </View>
    );
  }

  return (
    <View className="py-4 bg-background">
      <ScrollView 
        horizontal 
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ paddingHorizontal: 16 }}
      >
        {stories && stories.length > 0 ? stories.map((story) => (
          <TouchableOpacity
            key={story.id}
            onPress={() => handleStoryPress(story)}
            className="mr-4"
          >
            {/* Story Card */}
            <View className="w-32 h-48 bg-white rounded-lg shadow-sm overflow-hidden">
              {/* Full Height Image */}
              <View className="w-full h-full">
                <Image
                  source={{ uri: story.image_url }}
                  className="w-full h-full"
                  resizeMode="cover"
                />
              </View>
              
              {/* Profile Picture Overlay */}
              <View className="absolute top-2 left-2">
                <View className="w-8 h-8 rounded-full border-2 border-white overflow-hidden">
                  <Image
                    source={{ 
                      uri: story.accounts?.picture_url || 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face'
                    }}
                    className="w-full h-full"
                    resizeMode="cover"
                  />
                </View>
              </View>
            </View>
          </TouchableOpacity>
        )) : (
          <View className="w-32 h-48 bg-gray-100 rounded-lg items-center justify-center">
            <Text className="text-muted-foreground text-center">No stories</Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

export default function HomePage() {
  const [showCreateModal, setShowCreateModal] = useState(false);

  const handleCreatePost = () => {
    setShowCreateModal(true);
  };

  const handlePostCreated = () => {
    setShowCreateModal(false);
    Alert.alert('Success', 'Post created successfully!');
  };

  const handleCancelCreate = () => {
    setShowCreateModal(false);
  };

  const handlePostPress = (post: LogActivite) => {
    // TODO: Navigate to post detail view
    Alert.alert('Post Details', `Title: ${post.title}\nBody: ${post.body || 'No content'}`);
  };

  return (
    <View className="flex-1 bg-background">
      {/* Main Scrollable Content */}
      <ScrollView className="flex-1" showsVerticalScrollIndicator={false}>
        {/* Stories */}
        <Stories />

        {/* Feed List */}
        <FeedList 
          onPostPress={handlePostPress}
          onRefresh={() => {
            // Refresh is handled internally by the FeedList component
            console.log('Feed refreshed');
          }}
        />
      </ScrollView>

      {/* Custom Tab Bar */}
      <CustomTabBar onCreatePost={handleCreatePost} />

      {/* Create Post Modal */}
      <Modal
        visible={showCreateModal}
        animationType="slide"
        presentationStyle="pageSheet"
      >
        <View className="flex-1 bg-background">
          <CreatePostForm
            onSuccess={handlePostCreated}
            onCancel={handleCancelCreate}
          />
        </View>
      </Modal>
    </View>
  );
}
