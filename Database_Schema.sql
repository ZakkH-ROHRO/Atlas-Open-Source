-- ATLAS OPEN-SOURCE D1 SCHEMA
-- PLATFORM: CLOUDFLARE | DATABASE_PROVIDER: D1 (SQLite)
-- Apply once to a new D1 database before deploying Atlas.js.
-- This schema supports the current Worker implementation only.
-- It intentionally excludes code-generation, code-testing, and deployment tables.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS atlas_message_tracking (
  message_id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  status TEXT NOT NULL DEFAULT 'started'
    CHECK (status IN ('started', 'completed', 'failed')),
  has_image INTEGER NOT NULL DEFAULT 0,
  intent TEXT NOT NULL DEFAULT '',
  complexity TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS atlas_rate_limits (
  ip_hash TEXT PRIMARY KEY,
  hour_bucket INTEGER NOT NULL,
  text_count INTEGER NOT NULL DEFAULT 0,
  image_count INTEGER NOT NULL DEFAULT 0,
  burst_bucket INTEGER NOT NULL,
  burst_count INTEGER NOT NULL DEFAULT 0,
  active_token TEXT,
  active_until INTEGER,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS rsi_active_config (
  config_key TEXT PRIMARY KEY,
  config_value TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  version_id TEXT,
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_by TEXT NOT NULL DEFAULT 'system'
);

CREATE TABLE IF NOT EXISTS rsi_evaluations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL,
  model TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  confidence REAL NOT NULL CHECK (confidence BETWEEN 0 AND 1),
  summary TEXT NOT NULL DEFAULT '',
  strengths_json TEXT NOT NULL DEFAULT '[]',
  issue_tags_json TEXT NOT NULL DEFAULT '[]',
  improvement_suggestion TEXT NOT NULL DEFAULT '',
  safety_flag INTEGER NOT NULL DEFAULT 0,
  guide_count INTEGER NOT NULL DEFAULT 0,
  troubleshooting_mode INTEGER NOT NULL DEFAULT 0,
  guide_collection TEXT NOT NULL DEFAULT '',
  learning_pathway TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS rsi_evolution_jobs (
  id TEXT PRIMARY KEY,
  job_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  priority INTEGER NOT NULL DEFAULT 5,
  status TEXT NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'running', 'completed', 'failed', 'cancelled', 'paused')),
  input_json TEXT NOT NULL DEFAULT '{}',
  result_json TEXT NOT NULL DEFAULT '{}',
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  started_at TEXT,
  completed_at TEXT,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS rsi_extraction_usage (
  usage_date TEXT PRIMARY KEY,
  extraction_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS rsi_issue_patterns (
  issue_tag TEXT PRIMARY KEY,
  occurrences INTEGER NOT NULL DEFAULT 0,
  last_seen TEXT NOT NULL,
  latest_summary TEXT NOT NULL DEFAULT '',
  latest_suggestion TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS rsi_knowledge (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  topic TEXT NOT NULL,
  knowledge TEXT NOT NULL,
  classification TEXT NOT NULL DEFAULT 'unverified'
    CHECK (classification IN ('verified', 'supported', 'unverified', 'rejected', 'superseded')),
  source_type TEXT NOT NULL DEFAULT 'unknown',
  source_title TEXT NOT NULL DEFAULT '',
  source_url TEXT,
  evidence_json TEXT NOT NULL DEFAULT '[]',
  confidence REAL NOT NULL DEFAULT 0 CHECK (confidence BETWEEN 0 AND 1),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  reviewed_at TEXT,
  superseded_by TEXT
);

CREATE TABLE IF NOT EXISTS rsi_learning_events (
  id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  origin TEXT NOT NULL DEFAULT 'assistant',
  summary TEXT NOT NULL,
  details_json TEXT NOT NULL DEFAULT '{}',
  related_knowledge_id TEXT,
  processing_status TEXT NOT NULL DEFAULT 'new'
    CHECK (processing_status IN ('new', 'processed', 'ignored')),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS rsi_performance (
  id TEXT PRIMARY KEY,
  metric_name TEXT NOT NULL,
  metric_value REAL NOT NULL,
  sample_size INTEGER NOT NULL DEFAULT 0,
  period_start TEXT,
  period_end TEXT,
  dimensions_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS rsi_proposals (
  id TEXT PRIMARY KEY,
  issue_tag TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  recommendation TEXT NOT NULL,
  evidence_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TEXT NOT NULL,
  reviewed_at TEXT
);

CREATE TABLE IF NOT EXISTS rsi_versions (
  version_id TEXT PRIMARY KEY,
  version_number INTEGER NOT NULL UNIQUE,
  version_type TEXT NOT NULL DEFAULT 'configuration',
  config_snapshot TEXT NOT NULL,
  change_summary TEXT NOT NULL,
  proposal_id TEXT,
  code_commit TEXT,
  rollback_of TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT NOT NULL DEFAULT 'assistant'
);

CREATE INDEX IF NOT EXISTS idx_atlas_tracking_conversation
  ON atlas_message_tracking(conversation_id);
CREATE INDEX IF NOT EXISTS idx_atlas_tracking_created
  ON atlas_message_tracking(created_at);
CREATE INDEX IF NOT EXISTS idx_atlas_rate_limits_updated_at
  ON atlas_rate_limits(updated_at);
CREATE INDEX IF NOT EXISTS idx_rsi_evaluations_created_at
  ON rsi_evaluations(created_at);
CREATE INDEX IF NOT EXISTS idx_rsi_evaluations_score
  ON rsi_evaluations(score);
CREATE INDEX IF NOT EXISTS idx_rsi_jobs_status_priority
  ON rsi_evolution_jobs(status, priority, created_at);
CREATE INDEX IF NOT EXISTS idx_rsi_knowledge_category_topic
  ON rsi_knowledge(category, topic);
CREATE INDEX IF NOT EXISTS idx_rsi_knowledge_classification
  ON rsi_knowledge(classification);
CREATE INDEX IF NOT EXISTS idx_rsi_learning_created
  ON rsi_learning_events(created_at);
CREATE INDEX IF NOT EXISTS idx_rsi_learning_status
  ON rsi_learning_events(processing_status);
CREATE INDEX IF NOT EXISTS idx_rsi_performance_metric
  ON rsi_performance(metric_name, created_at);
CREATE INDEX IF NOT EXISTS idx_rsi_proposals_status
  ON rsi_proposals(status, evidence_count DESC);
CREATE INDEX IF NOT EXISTS idx_rsi_versions_number
  ON rsi_versions(version_number);

-- No visitor message text, assistant answer text, names, email addresses,
-- or raw IP addresses are stored by the RSI evaluation workflow.
