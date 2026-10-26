-- ==============================================================================
-- TABLAS PARA CONTENIDO DINÁMICO DEL HOME - BREINER DIAZ
-- ==============================================================================

-- 1. Diapositivas del Carrusel del Home
CREATE TABLE IF NOT EXISTS home_slides (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    highlight VARCHAR(255),
    subtitle TEXT NOT NULL,
    button_text VARCHAR(100) DEFAULT 'Ver Cursos',
    button_link VARCHAR(255) DEFAULT '#cursos',
    image_url TEXT NOT NULL,
    image_filename VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    order_index INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_home_slides_order ON home_slides(order_index, is_active);

-- 2. Configuración Global del Home: Video Destacado y Textos
CREATE TABLE IF NOT EXISTS home_config (
    id INT PRIMARY KEY DEFAULT 1,
    video_type VARCHAR(50) DEFAULT 'youtube',
    video_url TEXT DEFAULT 'https://www.youtube.com/watch?v=pR8IFJJIN-Y',
    video_filename VARCHAR(255),
    video_title VARCHAR(255) DEFAULT 'Aprende Pintura al Óleo con Breiner Díaz',
    video_description TEXT DEFAULT 'Conoce la técnica clásica de pintura al óleo, preparación del soporte y aplicación de capas de veladuras.',
    is_video_active BOOLEAN DEFAULT TRUE,

    courses_title VARCHAR(255) DEFAULT 'Cursos más populares',
    courses_subtitle TEXT DEFAULT 'Técnicas tradicionales explicadas con metodología moderna para artistas contemporáneos.',
    community_title VARCHAR(255) DEFAULT 'Comunidad de Artistas',
    community_subtitle TEXT DEFAULT 'Comparte tus avances, recibe retroalimentación de maestros y conecta con pintores de todo el mundo.',
    newsletter_title VARCHAR(255) DEFAULT '¡Suscríbete al boletín!',
    newsletter_subtitle TEXT DEFAULT 'Y entérate de los nuevos cursos, blogs y descuentos especiales.',
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Semilla de datos iniciales
INSERT INTO home_config (id, video_type, video_url, video_title, video_description, is_video_active)
VALUES (
    1,
    'youtube',
    'https://www.youtube.com/watch?v=pR8IFJJIN-Y',
    'Aprende Pintura al Óleo con Breiner Díaz',
    'Conoce la técnica clásica de pintura al óleo, preparación del soporte y aplicación de capas de veladuras.',
    TRUE
)
ON CONFLICT (id) DO UPDATE SET
    video_url = EXCLUDED.video_url,
    video_type = EXCLUDED.video_type;

-- Insertar las 3 diapositivas iniciales si la tabla está vacía
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM home_slides) THEN
        INSERT INTO home_slides (title, highlight, subtitle, button_text, button_link, image_url, order_index, is_active)
        VALUES 
        (
            'Aprende a pintar al óleo',
            'de cero al realismo',
            'Academias online paso a paso. Únete a miles de estudiantes en Latinoamérica, España y EE.UU.',
            'Ver catálogo de cursos',
            '#cursos',
            'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1920&q=80',
            0,
            TRUE
        ),
        (
            'Tu primera obra original de autor',
            'lista para concursos',
            'Desarrolla tu primera obra al óleo con una narrativa potente basada en tu propio contexto.',
            'Ver más información',
            '#cursos',
            'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=1920&q=80',
            1,
            TRUE
        ),
        (
            'Masterclass en Vivo de Veladuras',
            'Con Breiner',
            'Aprende en directo por Google Meet privado. Correcciones personalizadas paso a paso.',
            'Ver curso en vivo',
            '#en-vivo',
            'https://images.unsplash.com/photo-1577083552431-6e5fd01aa342?auto=format&fit=crop&w=1920&q=80',
            2,
            TRUE
        );
    END IF;
END $$;
