import React from 'react';
import { FlatList, RefreshControl, View } from 'react-native';
import { Text, Spinner, Button } from '@kit/ui';
import { useFeed } from '../hooks/use-feed';
import { PostCard } from './post-card';
import type { LogActivite } from '../lib/types';

interface FeedListProps {
  onPostPress?: (post: LogActivite) => void;
  onRefresh?: () => void;
}

export function FeedList({ onPostPress, onRefresh }: FeedListProps) {
  const {
    data,
    isLoading,
    isError,
    error,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    refetch,
  } = useFeed();

  const allPosts = data?.pages.flatMap(page => page.data) || [];

  const handleLoadMore = () => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  };

  const handleRefresh = () => {
    refetch();
    onRefresh?.();
  };

  const renderPost = ({ item }: { item: LogActivite }) => (
    <PostCard
      post={item}
      onPress={() => onPostPress?.(item)}
    />
  );

  const renderFooter = () => {
    if (!isFetchingNextPage) return null;
    
    return (
      <View className="p-4 items-center">
        <Spinner size="small" />
        <Text className="text-sm text-muted-foreground mt-2">
          Loading more posts...
        </Text>
      </View>
    );
  };

  const renderEmpty = () => (
    <View className="flex-1 items-center justify-center p-8">
      <Text className="text-lg font-semibold text-foreground mb-2">
        No posts yet
      </Text>
      <Text className="text-sm text-muted-foreground text-center">
        Be the first to share your activity with the community!
      </Text>
    </View>
  );

  if (isLoading) {
    return (
      <View className="flex-1 items-center justify-center">
        <Spinner size="large" />
        <Text className="text-sm text-muted-foreground mt-2">
          Loading feed...
        </Text>
      </View>
    );
  }

  if (isError) {
    return (
      <View className="flex-1 items-center justify-center p-8">
        <Text className="text-lg font-semibold text-foreground mb-2">
          Error loading feed
        </Text>
        <Text className="text-sm text-muted-foreground text-center mb-4">
          {error?.message || 'Something went wrong'}
        </Text>
        <Button onPress={() => refetch()}>
          <Text>Try Again</Text>
        </Button>
      </View>
    );
  }

  return (
    <FlatList
      data={allPosts}
      renderItem={renderPost}
      keyExtractor={(item) => item.id}
      onEndReached={handleLoadMore}
      onEndReachedThreshold={0.1}
      ListFooterComponent={renderFooter}
      ListEmptyComponent={renderEmpty}
      refreshControl={
        <RefreshControl
          refreshing={isLoading}
          onRefresh={handleRefresh}
        />
      }
      showsVerticalScrollIndicator={false}
      contentContainerStyle={{ flexGrow: 1 }}
    />
  );
}
