import type { Tables } from '@kit/supabase';

// Feed types
export type LogActivite = Tables<'log_activites'>;
export type LogActiviteInsert = {
  account_id: string;
  title: string;
  body?: string | null;
  image_url?: string | null;
  challenge_id: string;
};
export type LogActiviteUpdate = {
  title?: string;
  body?: string | null;
  image_url?: string | null;
};

// Feed query parameters
export interface FeedQueryParams {
  page?: number;
  limit?: number;
  userId?: string;
}

// Feed response
export interface FeedResponse {
  data: LogActivite[];
  hasMore: boolean;
  totalCount: number;
}

// Create post form data
export interface CreatePostFormData {
  title: string;
  body?: string;
  image_url?: string;
  challenge_id?: string;
}
