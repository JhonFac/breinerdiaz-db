-- ==============================================================================
-- DDL Y SEMILLA DE DATOS - PLATAFORMA BREINER DIAZ
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tabla de Usuarios
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'estudiante', -- 'estudiante', 'profesor', 'administrador'
    avatar_url TEXT,
    phone VARCHAR(50),
    country VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    auth_provider VARCHAR(50) NOT NULL DEFAULT 'credentials', -- 'credentials', 'google', 'both'
    google_id VARCHAR(255),
    courses_enrolled INT NOT NULL DEFAULT 0,
    courses_teaching INT NOT NULL DEFAULT 0,
    completed_classes INT NOT NULL DEFAULT 0,
    pending_reviews INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Tabla de Suscriptores al Boletín de Noticias
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    source VARCHAR(100) NOT NULL DEFAULT 'web_home',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_newsletter_email ON newsletter_subscribers(email);

-- Semilla de usuarios iniciales (Si no existen)
-- Se guardan con hash bcrypt o texto de compatibilidad
INSERT INTO users (id, email, password_hash, full_name, role, avatar_url, phone, country, is_active, auth_provider, courses_enrolled, courses_teaching, pending_reviews, completed_classes)
VALUES 
(
    'usr-admin-001',
    'admin@breinerdiaz.com',
    'Admin123!',
    'Breiner Díaz',
    'administrador',
    '/images/breiner-diaz.png',
    '+57 312 456 7890',
    'Colombia',
    TRUE,
    'credentials',
    12,
    8,
    3,
    0
),
(
    'usr-profesor-001',
    'profesor@breinerdiaz.com',
    'Profe123!',
    'Mtro. Ricardo Celma',
    'profesor',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    '+54 9 11 5555 4321',
    'Argentina',
    TRUE,
    'credentials',
    0,
    5,
    8,
    0
),
(
    'usr-estudiante-001',
    'estudiante@breinerdiaz.com',
    'Alumno123!',
    'Camila Restrepo',
    'estudiante',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
    '+57 300 123 4567',
    'Colombia',
    TRUE,
    'credentials',
    4,
    0,
    0,
    28
),
(
    'usr-estudiante-002',
    'mateo.gomez@gmail.com',
    'Alumno123!',
    'Mateo Gómez Peña',
    'estudiante',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    '+52 55 9876 5432',
    'México',
    TRUE,
    'credentials',
    2,
    0,
    0,
    14
),
(
    'usr-estudiante-003',
    'valeria.art@hotmail.com',
    'Alumno123!',
    'Valeria Morales',
    'estudiante',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    '+34 612 345 678',
    'España',
    TRUE,
    'credentials',
    3,
    0,
    0,
    31
)
ON CONFLICT (email) DO NOTHING;
