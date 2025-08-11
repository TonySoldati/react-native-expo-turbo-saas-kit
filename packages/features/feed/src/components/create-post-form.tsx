import React from 'react';
import { View, ScrollView } from 'react-native';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button, Input, Text, Card } from '@kit/ui';
import { useCreatePost } from '../hooks/use-create-post';
import type { CreatePostFormData } from '../lib/types';

const createPostSchema = z.object({
  title: z.string().min(1, 'Title is required').max(255, 'Title too long'),
  body: z.string().max(1000, 'Description too long').optional(),
  image_url: z.string().url('Invalid URL').optional().or(z.literal('')),
  challenge_id: z.string().optional(),
});

interface CreatePostFormProps {
  onSuccess?: () => void;
  onCancel?: () => void;
}

export function CreatePostForm({ onSuccess, onCancel }: CreatePostFormProps) {
  const createPost = useCreatePost();

  const form = useForm<CreatePostFormData>({
    resolver: zodResolver(createPostSchema),
    defaultValues: {
      title: '',
      body: '',
      image_url: '',
    },
  });

  const onSubmit = async (data: CreatePostFormData) => {
    try {
      await createPost.mutateAsync({
        title: data.title,
        body: data.body || undefined,
        image_url: data.image_url || undefined,
        challenge_id: data.challenge_id,
      });
      
      form.reset();
      onSuccess?.();
    } catch (error) {
      console.error('Failed to create post:', error);
    }
  };

  return (
    <ScrollView className="flex-1 p-4">
      <Card className="p-4">
        <Text className="text-xl font-semibold text-foreground mb-4">
          Create New Post
        </Text>

        <View className="space-y-4">
          <View>
            <Text className="text-sm font-medium text-foreground mb-2">
              Title *
            </Text>
            <Controller
              control={form.control}
              name="title"
              render={({ field, fieldState }) => (
                <Input
                  placeholder="Enter your post title"
                  value={field.value}
                  onChangeText={field.onChange}
                  onBlur={field.onBlur}
                  error={fieldState.error?.message}
                />
              )}
            />
          </View>

          <View>
            <Text className="text-sm font-medium text-foreground mb-2">
              Description
            </Text>
            <Controller
              control={form.control}
              name="body"
              render={({ field, fieldState }) => (
                <Input
                  placeholder="Describe your activity (optional)"
                  value={field.value}
                  onChangeText={field.onChange}
                  onBlur={field.onBlur}
                  error={fieldState.error?.message}
                  multiline
                  numberOfLines={4}
                />
              )}
            />
          </View>

          <View>
            <Text className="text-sm font-medium text-foreground mb-2">
              Image URL
            </Text>
            <Controller
              control={form.control}
              name="image_url"
              render={({ field, fieldState }) => (
                <Input
                  placeholder="https://example.com/image.jpg (optional)"
                  value={field.value}
                  onChangeText={field.onChange}
                  onBlur={field.onBlur}
                  error={fieldState.error?.message}
                />
              )}
            />
          </View>

          <View className="flex-row gap-3 pt-4">
            <Button
              variant="outline"
              onPress={onCancel}
              className="flex-1"
              disabled={createPost.isPending}
            >
              <Text>Cancel</Text>
            </Button>
            
            <Button
              onPress={form.handleSubmit(onSubmit)}
              className="flex-1"
              disabled={createPost.isPending || !form.formState.isValid}
            >
              <Text>
                {createPost.isPending ? 'Creating...' : 'Create Post'}
              </Text>
            </Button>
          </View>
        </View>
      </Card>
    </ScrollView>
  );
}
