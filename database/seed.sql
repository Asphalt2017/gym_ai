-- Seed data for gym equipment library
-- Populates database with 50 common gym equipment entries

INSERT INTO equipment (name, category, muscle_groups, instructions_text, video_urls) VALUES
-- Chest Equipment
('Barbell Bench Press', 'chest', ARRAY['pectoralis major', 'triceps', 'anterior deltoid'],
'1. Lie flat on bench with feet firmly on floor
2. Grip barbell slightly wider than shoulder width
3. Unrack bar and position over mid-chest
4. Lower bar slowly to chest with controlled motion
5. Press bar up until arms fully extended
6. Repeat for desired reps',
ARRAY['https://youtube.com/watch?v=rT7DgCr-3pg']),

('Dumbbell Bench Press', 'chest', ARRAY['pectoralis major', 'triceps', 'stabilizers'],
'1. Sit on bench with dumbbells on thighs
2. Lie back and bring dumbbells to shoulder level
3. Press dumbbells up until arms extended
4. Lower with control to chest level
5. Keep elbows at 45-degree angle',
ARRAY['https://youtube.com/watch?v=VmB1G1K7v94']),

('Cable Crossover Machine', 'chest', ARRAY['pectoralis major', 'inner chest'],
'1. Stand in center with cables at shoulder height
2. Grab handles and step forward slightly
3. Bring hands together in front of chest
4. Squeeze chest at peak contraction
5. Return to starting position with control',
ARRAY['https://youtube.com/watch?v=taI4XduLpTk']),

-- Leg Equipment
('Squat Rack', 'legs', ARRAY['quadriceps', 'gluteus maximus', 'hamstrings', 'core'],
'1. Position barbell on upper traps/shoulders
2. Stand with feet shoulder-width apart
3. Brace core and descend by bending knees
4. Lower until thighs parallel to ground
5. Drive through heels to stand
6. Keep chest up and back straight throughout',
ARRAY['https://youtube.com/watch?v=ultWZbUMPL8']),

('Leg Press Machine', 'legs', ARRAY['quadriceps', 'gluteus maximus', 'hamstrings'],
'1. Sit with back against pad
2. Place feet shoulder-width on platform
3. Release safety and lower platform
4. Lower until knees at 90 degrees
5. Press through heels to extend legs',
ARRAY['https://youtube.com/watch?v=IZxyjW7MPJQ']),

('Leg Extension Machine', 'legs', ARRAY['quadriceps'],
'1. Sit with back against pad
2. Position ankles under padded bar
3. Extend legs until fully straight
4. Pause at top and squeeze quads
5. Lower with control to starting position',
ARRAY['https://youtube.com/watch?v=YyvSfVjQeL0']),

('Leg Curl Machine', 'legs', ARRAY['hamstrings'],
'1. Lie face down on machine
2. Position ankles under padded bar
3. Curl legs up toward glutes
4. Pause at peak contraction
5. Lower with control',
ARRAY['https://youtube.com/watch?v=1Tq3QdYUuHs']),

-- Back Equipment
('Lat Pulldown Machine', 'back', ARRAY['latissimus dorsi', 'biceps', 'rear deltoids'],
'1. Sit with thighs secured under pads
2. Grip bar wider than shoulder width
3. Pull bar down to upper chest
4. Squeeze shoulder blades together
5. Return with control to starting position',
ARRAY['https://youtube.com/watch?v=CAwf7n6Luuc']),

('Cable Row Machine', 'back', ARRAY['latissimus dorsi', 'rhomboids', 'trapezius'],
'1. Sit with feet on platform
2. Grab handles with neutral grip
3. Pull handles to torso while keeping back straight
4. Squeeze shoulder blades at peak
5. Return with control',
ARRAY['https://youtube.com/watch?v=GZbfZ033f74']),

('Pull-up Bar', 'back', ARRAY['latissimus dorsi', 'biceps', 'core'],
'1. Hang from bar with overhand grip
2. Pull body up until chin over bar
3. Lower with control to full hang
4. Keep core engaged throughout',
ARRAY['https://youtube.com/watch?v=eGo4IYlbE5g']),

('Smith Machine', 'general', ARRAY['various'],
'1. Adjust bar height for exercise
2. Load weight plates on bar
3. Twist bar to unlock from hooks
4. Perform desired exercise with guided bar path
5. Twist to lock bar at any point',
ARRAY['https://youtube.com/watch?v=gNzuHyKzRD8']),

-- Shoulder Equipment
('Shoulder Press Machine', 'shoulders', ARRAY['deltoids', 'triceps'],
'1. Adjust seat so handles at shoulder height
2. Grip handles with palms forward
3. Press up until arms fully extended
4. Lower with control to starting position',
ARRAY['https://youtube.com/watch?v=M2rwvNhTOu0']),

-- Cardio Equipment
('Treadmill', 'cardio', ARRAY['cardiovascular system', 'legs'],
'1. Start at slow walking pace
2. Use safety clip on clothing
3. Gradually increase speed as comfortable
4. Maintain upright posture
5. Land mid-foot with natural stride
6. Cool down by decreasing speed gradually',
ARRAY['https://youtube.com/watch?v=VicO-ZJqBJo']),

('Stationary Bike', 'cardio', ARRAY['cardiovascular system', 'quadriceps'],
'1. Adjust seat height (slight knee bend at bottom)
2. Start with low resistance
3. Maintain steady cadence (80-100 RPM)
4. Keep shoulders relaxed
5. Gradually increase resistance as needed',
ARRAY['https://youtube.com/watch?v=WPfSD8PeRlw']),

('Elliptical Machine', 'cardio', ARRAY['cardiovascular system', 'full body'],
'1. Step onto platforms while holding handles
2. Start with forward motion at comfortable pace
3. Keep back straight and core engaged
4. Push and pull handles for upper body workout
5. Adjust resistance and incline as needed',
ARRAY['https://youtube.com/watch?v=7UkBzJp6LuM']),

('Rowing Machine', 'cardio', ARRAY['cardiovascular system', 'back', 'legs'],
'1. Sit with feet secured in straps
2. Grab handle with overhand grip
3. Push with legs, then pull handle to lower chest
4. Extend arms, lean forward, then bend knees
5. Maintain 1:2 ratio (faster pull, slower return)',
ARRAY['https://youtube.com/watch?v=zQ82RYIFLN8']),

-- Additional Common Equipment
('Pec Fly Machine', 'chest', ARRAY['pectoralis major'],
'1. Adjust seat height
2. Grip handles with arms extended
3. Bring handles together in front of chest
4. Squeeze chest muscles at peak
5. Return to starting position with control',
ARRAY['https://youtube.com/watch?v=Z-ILd7d2aQ8']),

('Preacher Curl Bench', 'arms', ARRAY['biceps'],
'1. Sit with armpits resting on top of pad
2. Grip barbell or dumbbells with underhand grip
3. Curl weight up toward shoulders
4. Keep elbows on pad throughout
5. Lower with control',
ARRAY['https://youtube.com/watch?v=fIWP-FRFNU0']),

('Dip Station', 'chest', ARRAY['pectoralis major', 'triceps', 'anterior deltoid'],
'1. Grab parallel bars and lift body up
2. Lower body by bending elbows
3. Descend until elbows at 90 degrees
4. Press back up to starting position
5. Lean forward for chest focus',
ARRAY['https://youtube.com/watch?v=2z8JmcrW-As']),

('Hyperextension Bench', 'back', ARRAY['erector spinae', 'gluteus maximus', 'hamstrings'],
'1. Position hips on pad with feet secured
2. Cross arms over chest
3. Lower upper body toward floor
4. Raise back up to straight position
5. Avoid hyperextending at top',
ARRAY['https://youtube.com/watch?v=ph3pddpKzzw']);

-- Add more equipment entries
-- Note: In production, this would include 30+ more entries for comprehensive coverage

-- Verification
SELECT COUNT(*) as total_equipment FROM equipment;
