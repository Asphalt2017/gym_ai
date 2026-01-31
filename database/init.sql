-- Database initialization script for Gym AI Helper
-- Creates tables for equipment, cache, and user tracking

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Equipment table: stores gym equipment information
CREATE TABLE IF NOT EXISTS equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL,
    muscle_groups TEXT[] NOT NULL DEFAULT '{}',
    instructions_text TEXT NOT NULL,
    video_urls TEXT[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for equipment
CREATE INDEX IF NOT EXISTS idx_equipment_name ON equipment(name);
CREATE INDEX IF NOT EXISTS idx_equipment_category ON equipment(category);

-- Equipment cache table: stores AI analysis results with image hashes
CREATE TABLE IF NOT EXISTS equipment_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    image_hash VARCHAR(100) NOT NULL UNIQUE,
    equipment_id UUID REFERENCES equipment(id) ON DELETE SET NULL,
    ai_response JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ttl_expires_at TIMESTAMP NOT NULL
);

-- Create indexes for cache lookups
CREATE INDEX IF NOT EXISTS idx_cache_image_hash ON equipment_cache(image_hash);
CREATE INDEX IF NOT EXISTS idx_cache_ttl ON equipment_cache(ttl_expires_at);
CREATE INDEX IF NOT EXISTS idx_cache_equipment_id ON equipment_cache(equipment_id);

-- User identifications table: tracks usage history
CREATE TABLE IF NOT EXISTS user_identifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(100),
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    image_url VARCHAR(500),
    confidence INTEGER CHECK (confidence >= 0 AND confidence <= 100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for user tracking
CREATE INDEX IF NOT EXISTS idx_user_id ON user_identifications(user_id);
CREATE INDEX IF NOT EXISTS idx_timestamp ON user_identifications(timestamp);
CREATE INDEX IF NOT EXISTS idx_equipment_id ON user_identifications(equipment_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for equipment table
CREATE TRIGGER update_equipment_updated_at BEFORE UPDATE ON equipment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE equipment IS 'Gym equipment library with usage instructions';
COMMENT ON TABLE equipment_cache IS 'AI analysis results cache using perceptual image hashing';
COMMENT ON TABLE user_identifications IS 'User query history for analytics';

COMMENT ON COLUMN equipment_cache.image_hash IS 'Perceptual hash (pHash) of analyzed image';
COMMENT ON COLUMN equipment_cache.ai_response IS 'Complete AI analysis result as JSON';
COMMENT ON COLUMN equipment_cache.ttl_expires_at IS 'Cache expiration timestamp (30-day TTL)';
