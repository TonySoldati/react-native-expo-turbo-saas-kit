import React from 'react';
import { View, Image, TouchableOpacity } from 'react-native';
import { Text } from '@kit/ui';
import type { LogActivite } from '../lib/types';

interface PostCardProps {
  post: LogActivite;
  onPress?: () => void;
}

export function PostCard({ post, onPress }: PostCardProps) {

  return (
    <TouchableOpacity onPress={onPress} className="bg-background mb-8">
      {/* Header */}
      <View className="flex-row items-center px-4 py-3">
        <View className="w-10 h-10 rounded-full overflow-hidden mr-3 bg-gray-200">
          <Image
            source={{ uri: post.image_url || undefined }}
            className="w-full h-full"
            resizeMode="cover"
          />
        </View>
        
        <View className="flex-1">
          <Text className="font-semibold text-foreground">
            {post.title}
          </Text>
          <Text className="text-xs text-muted-foreground">
            {123}
          </Text>
        </View>
      </View>

      {/* Body Text */}
      {post.body && (
        <Text className="text-foreground px-4 pb-3 leading-5">
          {post.body}
        </Text>
      )}

      {/* Full Width Image */}
      {post.image_url && (
        <View className="w-full">
          <Image
            source={{ uri: post.image_url }}
            className="w-full h-80"
            resizeMode="cover"
          />
        </View>
      )}

      {/* Footer with Like and Comment Buttons */}
      <View className="flex-row items-center px-4 py-3 border-t border-border">
        <TouchableOpacity className="flex-row items-center mr-4 bg-gray-100 rounded-lg px-3 py-2 border border-gray-200">
          <Text className="text-lg mr-2">👏</Text>
          <Text className="text-foreground font-medium">2</Text>
        </TouchableOpacity>
        
        <TouchableOpacity className="flex-row items-center bg-gray-100 rounded-lg px-3 py-2 border border-gray-200">
          <Text className="text-lg mr-2">💬</Text>
          <Text className="text-foreground font-medium">2</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );
}
