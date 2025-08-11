import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useSupabase } from '@kit/supabase';
import type { LogActiviteUpdate } from '../lib/types';

const FEED_QUERY_KEY = ['feed'];

export function usePost() {
  const supabase = useSupabase();
  const queryClient = useQueryClient();

  const updatePost = async ({ id, ...data }: { id: string } & LogActiviteUpdate) => {
    const { data: updatedPost, error } = await supabase
      .from('log_activite')
      .update(data)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      throw new Error(error.message);
    }

    return updatedPost;
  };

  const deletePost = async (id: string) => {
    const { error } = await supabase
      .from('log_activite')
      .delete()
      .eq('id', id);

    if (error) {
      throw new Error(error.message);
    }

    return { success: true };
  };

  return {
    updatePost: useMutation({
      mutationFn: updatePost,
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: FEED_QUERY_KEY });
      },
    }),
    deletePost: useMutation({
      mutationFn: deletePost,
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: FEED_QUERY_KEY });
      },
    }),
  };
}
