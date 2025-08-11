import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useSupabase } from '@kit/supabase';
import { useUser } from '@kit/supabase';
import type { CreatePostFormData, LogActiviteInsert } from '../lib/types';

const FEED_QUERY_KEY = ['feed'];

export function useCreatePost() {
  const supabase = useSupabase();
  const { data: user } = useUser();
  const queryClient = useQueryClient();

  const createPost = async (formData: CreatePostFormData) => {
    if (!user) {
      throw new Error('User not authenticated');
    }

    const postData: LogActiviteInsert = {
      account_id: user.id,
      title: formData.title,
      body: formData.body || null,
      image_url: formData.image_url || null,
      challenge_id: formData.challenge_id || '73722bf4-4213-4feb-8848-bbb5ef422989', // Default challenge ID
    };

    const { data, error } = await supabase
      .from('log_activites')
      .insert(postData)
      .select()
      .single();

    if (error) {
      throw new Error(error.message);
    }

    return data;
  };

  return useMutation({
    mutationFn: createPost,
    onSuccess: () => {
      // Invalidate and refetch feed queries
      queryClient.invalidateQueries({ queryKey: FEED_QUERY_KEY });
    },
  });
}
