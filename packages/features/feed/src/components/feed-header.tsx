import React from 'react';
import { View } from 'react-native';
import { Button, Text } from '@kit/ui';
import { PlusIcon } from 'lucide-react-native';

interface FeedHeaderProps {
  onCreatePost: () => void;
}

export function FeedHeader({ onCreatePost }: FeedHeaderProps) {
  return (
    <View className="flex-row items-center justify-between p-4 border-b border-border">
      <View>
        <Text className="text-2xl font-bold text-foreground">Feed</Text>
        <Text className="text-sm text-muted-foreground">
          Share your activities with the community
        </Text>
      </View>
      
      <Button
        size="sm"
        onPress={onCreatePost}
        className="flex-row items-center gap-2"
      >
        <PlusIcon className="h-4 w-4" />
        <Text>Create Post</Text>
      </Button>
    </View>
  );
}
