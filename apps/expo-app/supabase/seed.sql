-- Seed data for the application
-- This file is executed after all migrations

-- Insert dummy posts with images
INSERT INTO public.log_activites (
    id,
    account_id,
    title,
    body,
    image_url,
    challenge_id,
    privacy,
    created_at,
    updated_at,
    created_by,
    updated_by
) VALUES 
-- Post 1: Running activity
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001', -- Default account ID
    'Morning Run in the Park',
    'Started my day with a refreshing 5km run through the local park. The weather was perfect and I felt great!',
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop',
    '73722bf4-4213-4feb-8848-bbb5ef422989',
    'public',
    now() - interval '2 hours',
    now() - interval '2 hours',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
),
-- Post 2: Gym workout
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    'Strength Training Session',
    'Hit the gym for a solid upper body workout. Focused on bench press, pull-ups, and shoulder exercises.',
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop',
    '73722bf4-4213-4feb-8848-bbb5ef422989',
    'public',
    now() - interval '1 day',
    now() - interval '1 day',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
),
-- Post 3: Yoga session
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    'Evening Yoga Flow',
    'Perfect way to unwind after a busy day. 30 minutes of gentle yoga stretches and meditation.',
    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&h=600&fit=crop',
    '73722bf4-4213-4feb-8848-bbb5ef422989',
    'public',
    now() - interval '3 days',
    now() - interval '3 days',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
),
-- Post 4: Cycling adventure
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    'Weekend Cycling Trip',
    'Explored the countryside on my bike today. Covered 25km with beautiful scenic views!',
    'https://images.unsplash.com/photo-1541625602330-2277a4c46182?w=800&h=600&fit=crop',
    '73722bf4-4213-4feb-8848-bbb5ef422989',
    'public',
    now() - interval '5 days',
    now() - interval '5 days',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
),
-- Post 5: Swimming
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    'Pool Swimming Session',
    'Swam 20 laps today focusing on freestyle technique. The water was perfect temperature.',
    'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=800&h=600&fit=crop',
    '73722bf4-4213-4feb-8848-bbb5ef422989',
    'public',
    now() - interval '1 week',
    now() - interval '1 week',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
),
-- Post 6: Hiking
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    'Mountain Hiking Adventure',
    'Hiked to the summit today! 8km trail with amazing panoramic views from the top.',
    'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800&h=600&fit=crop',
    '73722bf4-4213-4feb-8848-bbb5ef422989',
    'public',
    now() - interval '10 days',
    now() - interval '10 days',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
),
-- Post 7: Basketball
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    'Pickup Basketball Game',
    'Played 2 hours of pickup basketball with friends. Great cardio and team sport!',
    'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&h=600&fit=crop',
    '73722bf4-4213-4feb-8848-bbb5ef422989',
    'public',
    now() - interval '2 weeks',
    now() - interval '2 weeks',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
),
-- Post 8: Tennis
(
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    'Tennis Match',
    'Played a competitive tennis match today. Won in straight sets!',
    'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800&h=600&fit=crop',
    '73722bf4-4213-4feb-8848-bbb5ef422989',
    'public',
    now() - interval '3 weeks',
    now() - interval '3 weeks',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
);
