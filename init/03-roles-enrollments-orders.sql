-- ==============================================================================
-- MIGRACIÓN 03: ROLES, CURSOS, INSCRIPCIONES, ÓRDENES Y AUDITORÍA
-- ==============================================================================

-- 1. Actualizar tabla users con los nuevos campos de negocio
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'status') THEN
        ALTER TABLE users ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'ACTIVO';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'doc_type') THEN
        ALTER TABLE users ADD COLUMN doc_type VARCHAR(50) DEFAULT 'CC';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'doc_number') THEN
        ALTER TABLE users ADD COLUMN doc_number VARCHAR(100);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'created_by') THEN
        ALTER TABLE users ADD COLUMN created_by VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Normalizar roles a mayúsculas estándar (manteniendo compatibilidad)
UPDATE users SET role = 'ADMIN' WHERE LOWER(role) IN ('administrador', 'admin');
UPDATE users SET role = 'PROFESOR' WHERE LOWER(role) IN ('profesor', 'teacher');
UPDATE users SET role = 'ESTUDIANTE' WHERE LOWER(role) IN ('estudiante', 'student');

-- 2. Tabla de Cursos Oficiales
CREATE TABLE IF NOT EXISTS courses (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(150) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    description TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    original_price NUMERIC(10, 2),
    image_url TEXT,
    instructor_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    instructor_name VARCHAR(255) NOT NULL DEFAULT 'Breiner Díaz',
    level VARCHAR(50) DEFAULT 'Todos los niveles',
    features JSONB DEFAULT '[]'::jsonb,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_courses_slug ON courses(slug);

-- 3. Módulos y Lecciones de Cursos
CREATE TABLE IF NOT EXISTS course_modules (
    id SERIAL PRIMARY KEY,
    course_id INT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    order_index INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS course_lessons (
    id SERIAL PRIMARY KEY,
    module_id INT NOT NULL REFERENCES course_modules(id) ON DELETE CASCADE,
    course_id INT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 15,
    video_url TEXT,
    material_url TEXT,
    order_index INT NOT NULL DEFAULT 0,
    is_free_preview BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla de Inscripciones a Cursos
CREATE TABLE IF NOT EXISTS enrollments (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_id INT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE, ACTIVA, CANCELADA, EXPIRADA
    origin VARCHAR(50) NOT NULL DEFAULT 'COMPRA',    -- COMPRA, ASIGNADA_POR_ADMIN
    start_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_course UNIQUE (user_id, course_id)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_user ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON enrollments(status);

-- 5. Tabla de Órdenes de Pago
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    reference VARCHAR(100) UNIQUE NOT NULL, -- ORD-2026-XXXXX
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_id INT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    status VARCHAR(50) NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE, APROBADA, RECHAZADA, ERROR
    payment_provider VARCHAR(50) NOT NULL DEFAULT 'SIMULADO',
    provider_tx_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_reference ON orders(reference);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- 6. Tabla de Auditoría (Audit Logs)
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    actor_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- 7. Semilla de Cursos Iniciales
INSERT INTO courses (id, slug, title, subtitle, description, price, original_price, image_url, instructor_name, features)
VALUES 
(
    1,
    'academia-oleo',
    'Academia de Óleo Clásico',
    'De cero al hiperrealismo con óleo',
    'Aprende la técnica clásica del óleo desde la preparación del soporte, grisalla, veladuras transparentes y empastes luminosos con correcciones personalizadas.',
    147.40,
    220.00,
    'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=690&q=80',
    'Breiner Díaz',
    '["4 cursos de óleo por 1", "Revisiones personalizadas", "Acceso de por vida", "Certificación incluida"]'::jsonb
),
(
    2,
    'academia-retrato',
    'Academia de Retrato y Veladuras',
    'Domina el parecido fisonómico y los tonos de piel',
    'Desarrolla el retrato artístico al óleo dominando la paleta de tonos carnaciones, encaje anatómico y sutiles capas de veladuras luminosas.',
    147.40,
    220.00,
    'https://images.unsplash.com/photo-1508193638397-1c4234db14d8?auto=format&fit=crop&w=690&q=80',
    'Breiner Díaz',
    '["3 cursos de retrato en 1", "Revisiones personalizadas", "Acceso de por vida", "Certificación incluida"]'::jsonb
),
(
    3,
    'retrato-alla-prima',
    'Retrato Alla Prima al Óleo',
    'Pintura húmedo sobre húmedo en una sola sesión',
    'Aprende a capturar la frescura, soltura de pincelada y volumen directo trabajando húmedo sobre húmedo con modelos en vivo.',
    60.30,
    90.00,
    'https://images.unsplash.com/photo-1544717302-de2939b7ef71?auto=format&fit=crop&w=690&q=80',
    'Breiner Díaz',
    '["Técnica húmedo sobre húmedo", "Demostraciones paso a paso", "Acceso de por vida", "Certificado de finalización"]'::jsonb
),
(
    4,
    'acrilico',
    'Hiperrealismo con Acrílico',
    'Mezclas, degradados y empastes rápidos',
    'Domina el secado rápido del acrílico para crear texturas, reflejos hiperrealistas y acabados profesionales en lienzo y madera.',
    167.50,
    250.00,
    'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=690&q=80',
    'Mtro. Ricardo Celma',
    '["Técnicas de mezcla rápida", "Texturas hiperrealistas", "Acceso de por vida", "Certificación incluida"]'::jsonb
)
ON CONFLICT (id) DO UPDATE SET 
    price = EXCLUDED.price,
    original_price = EXCLUDED.original_price,
    title = EXCLUDED.title,
    description = EXCLUDED.description;

SELECT setval('courses_id_seq', (SELECT MAX(id) FROM courses));

-- 8. Semilla de Módulos y Clases de Ejemplo para Acceso Protegido
INSERT INTO course_modules (id, course_id, title, order_index)
VALUES 
    (1, 1, 'Módulo 1: Fundamentos y Preparación del Soporte', 1),
    (2, 1, 'Módulo 2: Grisalla y Volumen Inicial', 2),
    (3, 1, 'Módulo 3: Color, Veladuras y Empastes Finales', 3),
    (4, 2, 'Módulo 1: Anatomía Facial y Proporciones', 1),
    (5, 2, 'Módulo 2: Paleta de Tonos de Piel y Veladuras', 2)
ON CONFLICT (id) DO NOTHING;

SELECT setval('course_modules_id_seq', (SELECT MAX(id) FROM course_modules));

INSERT INTO course_lessons (id, module_id, course_id, title, duration_minutes, video_url, material_url, order_index, is_free_preview)
VALUES
    (1, 1, 1, 'Clase 1: Elección de Lienzos, Imprimación y Materiales Esenciales', 22, 'https://www.youtube.com/watch?v=pR8IFJJIN-Y', 'https://example.com/materiales-oleo-m1.pdf', 1, TRUE),
    (2, 1, 1, 'Clase 2: Preparación del Imprimado Gesso y Aceites de Linaza', 35, 'https://www.youtube.com/watch?v=pR8IFJJIN-Y', 'https://example.com/guia-imprimacion.pdf', 2, FALSE),
    (3, 2, 1, 'Clase 3: Bloqueo de Luces y Sombras con Sombra Tostada', 40, 'https://www.youtube.com/watch?v=pR8IFJJIN-Y', 'https://example.com/plantilla-esfera.pdf', 1, FALSE),
    (4, 3, 1, 'Clase 4: Aplicación de Capas Finas de Veladura Translúcida', 48, 'https://www.youtube.com/watch?v=pR8IFJJIN-Y', 'https://example.com/receta-medio-veladura.pdf', 1, FALSE),
    (5, 4, 2, 'Clase 1: Encaje de las Facciones y Puntos Craneales Clave', 30, 'https://www.youtube.com/watch?v=pR8IFJJIN-Y', 'https://example.com/guia-anatomia-rostro.pdf', 1, TRUE),
    (6, 5, 2, 'Clase 2: Mezcla de Carnaciones Claras y Sombras Cálidas', 45, 'https://www.youtube.com/watch?v=pR8IFJJIN-Y', 'https://example.com/rueda-color-piel.pdf', 1, FALSE)
ON CONFLICT (id) DO NOTHING;

SELECT setval('course_lessons_id_seq', (SELECT MAX(id) FROM course_lessons));

-- 9. Semilla de Usuarios para Pruebas Obligatorias:
--   - 1 Admin: admin@breinerdiaz.com (ACTIVO)
--   - 1 Profesor: profesor@breinerdiaz.com (ACTIVO)
--   - 1 Estudiante con Inscripción ACTIVA: estudiante@breinerdiaz.com (ACTIVO, con acceso a Academia de Óleo)
--   - 1 Estudiante con Pago PENDIENTE: mateo.gomez@gmail.com (PENDIENTE_PAGO, orden e inscripción pendientes)

UPDATE users SET 
    role = 'ADMIN',
    status = 'ACTIVO',
    doc_type = 'CC',
    doc_number = '1098765432'
WHERE email = 'admin@breinerdiaz.com';

UPDATE users SET 
    role = 'PROFESOR',
    status = 'ACTIVO',
    doc_type = 'CE',
    doc_number = 'CE-987654'
WHERE email = 'profesor@breinerdiaz.com';

UPDATE users SET 
    role = 'ESTUDIANTE',
    status = 'ACTIVO',
    doc_type = 'CC',
    doc_number = '1020304050'
WHERE email = 'estudiante@breinerdiaz.com';

UPDATE users SET 
    role = 'ESTUDIANTE',
    status = 'PENDIENTE_PAGO',
    doc_type = 'CC',
    doc_number = '1030405060'
WHERE email = 'mateo.gomez@gmail.com';

-- Inscripción ACTIVA para estudiante@breinerdiaz.com en Curso 1 (Academia de Óleo)
INSERT INTO enrollments (user_id, course_id, status, origin, start_date)
VALUES ('usr-estudiante-001', 1, 'ACTIVA', 'COMPRA', CURRENT_TIMESTAMP)
ON CONFLICT (user_id, course_id) DO UPDATE SET status = 'ACTIVA';

-- Orden APROBADA para estudiante@breinerdiaz.com
INSERT INTO orders (reference, user_id, course_id, amount, currency, status, payment_provider, provider_tx_id)
VALUES ('ORD-2026-INIT001', 'usr-estudiante-001', 1, 147.40, 'USD', 'APROBADA', 'SIMULADO', 'SIM-TX-888999')
ON CONFLICT (reference) DO UPDATE SET status = 'APROBADA';

-- Inscripción PENDIENTE para mateo.gomez@gmail.com en Curso 1 (Academia de Óleo)
INSERT INTO enrollments (user_id, course_id, status, origin, start_date)
VALUES ('usr-estudiante-002', 1, 'PENDIENTE', 'COMPRA', CURRENT_TIMESTAMP)
ON CONFLICT (user_id, course_id) DO UPDATE SET status = 'PENDIENTE';

-- Orden PENDIENTE para mateo.gomez@gmail.com
INSERT INTO orders (reference, user_id, course_id, amount, currency, status, payment_provider, provider_tx_id)
VALUES ('ORD-2026-PEND002', 'usr-estudiante-002', 1, 147.40, 'USD', 'PENDIENTE', 'SIMULADO', NULL)
ON CONFLICT (reference) DO UPDATE SET status = 'PENDIENTE';
