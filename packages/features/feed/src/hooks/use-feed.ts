import { useInfiniteQuery } from '@tanstack/react-query';
import { useSupabase } from '@kit/supabase';
import type { FeedQueryParams, FeedResponse } from '../lib/types';

const FEED_QUERY_KEY = ['feed'];

export function useFeed(params: FeedQueryParams = {}) {
  const supabase = useSupabase();
  const { page = 1, limit = 10 } = params;

  const fetchFeed = async ({ pageParam = 0 }) => {
    const from = pageParam * limit;
    const to = from + limit - 1;

    const { data, error, count } = await supabase
      .from('log_activites')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) {
      throw new Error(error.message);
    }

    const hasMore = count ? from + limit < count : false;

    return {
      data: data || [],
      hasMore,
      totalCount: count || 0,
    } as FeedResponse;
  };

  return useInfiniteQuery({
    queryKey: [...FEED_QUERY_KEY, params],
    queryFn: fetchFeed,
    getNextPageParam: (lastPage, pages) => {
      return lastPage.hasMore ? pages.length : undefined;
    },
    initialPageParam: 0,
  });
}
