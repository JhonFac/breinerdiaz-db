-- ==============================================================================
-- Tabla de Suscriptores para Modo Construcción / Lanzamiento
-- ==============================================================================
CREATE TABLE IF NOT EXISTS suscriptores_lanzamiento (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    origen VARCHAR(100) DEFAULT 'modo_construccion',
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_suscriptores_email ON suscriptores_lanzamiento(email);
