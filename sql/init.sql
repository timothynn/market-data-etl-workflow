-- Initialize database with optimized configuration

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create schema for market data
CREATE SCHEMA IF NOT EXISTS market;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA market TO etl_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA market TO etl_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA market TO etl_user;

-- Configure PostgreSQL for better performance
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = '0.9';
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = '100';
ALTER SYSTEM SET random_page_cost = '1.1';
ALTER SYSTEM SET effective_io_concurrency = '200';
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';

-- Log configuration
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_duration = 'on';
ALTER SYSTEM SET log_min_duration_statement = '1000';

-- Create audit log table
CREATE TABLE IF NOT EXISTS etl_audit_log (
    id SERIAL PRIMARY KEY,
    pipeline_run_id UUID DEFAULT uuid_generate_v4(),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(20),
    records_processed INTEGER,
    error_message TEXT,
    duration_seconds NUMERIC
);

-- Create data quality check table
CREATE TABLE IF NOT EXISTS data_quality_checks (
    id SERIAL PRIMARY KEY,
    check_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    check_name VARCHAR(100),
    check_status VARCHAR(20),
    records_checked INTEGER,
    issues_found INTEGER,
    details JSONB
);

-- Create index on audit log
CREATE INDEX idx_audit_pipeline_run ON etl_audit_log(pipeline_run_id);
CREATE INDEX idx_audit_start_time ON etl_audit_log(start_time DESC);
