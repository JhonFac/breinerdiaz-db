-- ==============================================================================
-- MIGRACIÓN 04: PRODUCTOS TIENDA, CARRITOS, CUPONES, ENVÍOS Y ÓRDENES MULTI-ÍTEM
-- ==============================================================================

-- 1. Tabla de Productos de la Tienda de Breiner
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(150) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'FISICO', -- 'FISICO' o 'DIGITAL'
    price NUMERIC(10, 2) NOT NULL,
    original_price NUMERIC(10, 2),
    image_url TEXT,
    stock INT NOT NULL DEFAULT 50,
    features JSONB DEFAULT '[]'::jsonb,
    badge VARCHAR(50),
    download_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_products_slug ON products(slug);
CREATE INDEX IF NOT EXISTS idx_products_type ON products(type);

-- Sembrar productos de la tienda
INSERT INTO products (id, name, slug, description, type, price, original_price, image_url, stock, features, badge, is_active)
VALUES 
(
    1,
    'Boina "Apoya el Arte"',
    'boina-apoya-el-arte',
    'Boina clásica de estilo pintor tradicional, diseñada con corte artesanal igual a la que usa Breiner Díaz en sus sesiones de creación en el taller.',
    'FISICO',
    35.00,
    45.00,
    '/img/tienda/boina-apoya-el-arte.webp',
    45,
    '["Lana de alta calidad", "Talla ajustable y cómoda", "Bordado exclusivo de firma"]'::jsonb,
    'Más vendido',
    TRUE
),
(
    2,
    'Delantal de pintor Breiner',
    'delantal-pintor-breiner',
    'Confeccionado en lona gruesa de máxima durabilidad para proteger tu ropa mientras pintas. Diseñado con compartimentos especiales para tus herramientas.',
    'FISICO',
    40.00,
    55.00,
    '/img/tienda/delantal-pintor-breiner.webp',
    30,
    '["Lona gruesa y resistente", "4 bolsillos para pinceles", "Correas ajustables cruzadas"]'::jsonb,
    NULL,
    TRUE
),
(
    3,
    'Set de pinceles profesionales',
    'set-pinceles-profesionales',
    'Selección completa de pinceles con cerda sintética de precisión, ideales para empastes al óleo, veladuras finas y detalles con acrílico.',
    'FISICO',
    30.00,
    42.00,
    '/img/tienda/set-pinceles-profesionales.png',
    50,
    '["Varias puntas (redonda, lengua de gato y plana)", "Cerda sintética premium elástica", "Estuche enrollable de regalo"]'::jsonb,
    'Nuevo',
    TRUE
),
(
    4,
    'Paleta de madera clásica',
    'paleta-madera-clasica',
    'Paleta tradicional de artista con orificio ergonómico para el pulgar y curvatura para el antebrazo. Acabado sellado que no absorbe los aceites.',
    'FISICO',
    25.00,
    32.00,
    '/img/tienda/paleta-madera-clasica.jpg',
    40,
    '["Madera pulida de grano fino", "Agarre anatómico para el pulgar", "Dimensiones 40 cm de ancho"]'::jsonb,
    NULL,
    TRUE
),
(
    5,
    'Kit Paleta Zorn',
    'kit-paleta-zorn',
    'Los 4 pigmentos primordiales para dominar la gama tonal humana del curso de Teoría del Color: Blanco de Titanio, Amarillo Ocre, Rojo Bermellón y Negro Marfil.',
    'FISICO',
    45.00,
    60.00,
    '/img/tienda/kit-paleta-zorn.jpg',
    25,
    '["4 óleos de grado profesional", "Guía visual de proporciones", "Fórmula ideal para el curso de retrato"]'::jsonb,
    'Más vendido',
    TRUE
),
(
    6,
    'Lámina firmada edición limitada',
    'lamina-firmada-edicion-limitada',
    'Reproducción giclée de museo sobre papel de algodón 100%, impresa con pigmentos de archivo. Cada copia está numerada y firmada personalmente por Breiner.',
    'FISICO',
    50.00,
    70.00,
    '/img/tienda/lamina-firmada-edicion-limitada.webp',
    15,
    '["Firmada y numerada a mano", "Marco negro mate de galería", "Formato 30 x 40 cm con paspartú"]'::jsonb,
    'Últimas unidades',
    TRUE
),
(
    7,
    'Cuaderno de bocetos Breiner',
    'cuaderno-bocetos-breiner',
    'Sketchbook de tapa dura creado especialmente para artistas que practican dibujo del natural, encajes de anatomía y bocetos previos de cuadros.',
    'FISICO',
    18.00,
    25.00,
    '/img/tienda/cuaderno-bocetos-breiner.webp',
    60,
    '["100 páginas de textura natural", "Papel grueso de 180 g/m² libre de ácido", "Tamaño práctico 18 x 25 cm con elástico"]'::jsonb,
    NULL,
    TRUE
),
(
    8,
    'Guía Maestra de Veladuras y Mezclas (E-Book Digital)',
    'guia-maestra-veladuras-digital',
    'Guía digital descargable en PDF de alta resolución con fórmulas exactas de dilución, tiempos de secado y paleta cromática paso a paso.',
    'DIGITAL',
    15.00,
    25.00,
    'https://images.unsplash.com/photo-1544717302-de2939b7ef71?auto=format&fit=crop&w=690&q=80',
    9999,
    '["PDF 120 páginas a todo color", "Fórmulas de veladura clásicas", "Descarga inmediata tras el pago"]'::jsonb,
    'Digital',
    TRUE
)
ON CONFLICT (id) DO NOTHING;

-- Sincronizar secuencia de products
SELECT setval('products_id_seq', (SELECT COALESCE(MAX(id), 1) FROM products));

-- 2. Tabla de Cupones de Descuento
CREATE TABLE IF NOT EXISTS coupons (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) NOT NULL DEFAULT 'PERCENTAGE', -- 'PERCENTAGE', 'FIXED'
    discount_value NUMERIC(10, 2) NOT NULL,
    min_spend NUMERIC(10, 2) DEFAULT 0.00,
    max_uses INT DEFAULT 100,
    current_uses INT DEFAULT 0,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO coupons (code, discount_type, discount_value, min_spend, max_uses, current_uses, is_active)
VALUES 
('ARTE10', 'PERCENTAGE', 10.00, 0.00, 500, 0, TRUE),
('BREINER20', 'FIXED', 20.00, 100.00, 100, 0, TRUE)
ON CONFLICT (code) DO NOTHING;

-- 3. Tabla de Configuración de Envíos
CREATE TABLE IF NOT EXISTS shipping_config (
    id SERIAL PRIMARY KEY,
    base_shipping_cost NUMERIC(10, 2) NOT NULL DEFAULT 15.00,
    free_shipping_threshold NUMERIC(10, 2) NOT NULL DEFAULT 120.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO shipping_config (id, base_shipping_cost, free_shipping_threshold, is_active)
VALUES (1, 15.00, 120.00, TRUE)
ON CONFLICT (id) DO UPDATE SET 
    base_shipping_cost = EXCLUDED.base_shipping_cost,
    free_shipping_threshold = EXCLUDED.free_shipping_threshold;

-- 4. Tablas de Carrito y Persistencia
CREATE TABLE IF NOT EXISTS carts (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    visitor_id VARCHAR(100) UNIQUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cart_items (
    id SERIAL PRIMARY KEY,
    cart_id INT NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL, -- 'CURSO' o 'PRODUCTO'
    item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cart_item UNIQUE (cart_id, item_type, item_id)
);

CREATE INDEX IF NOT EXISTS idx_cart_items_cart ON cart_items(cart_id);

-- 5. Adaptar Tabla de Órdenes a Múltiples Ítems
DO $$
BEGIN
    -- Hacer course_id opcional
    ALTER TABLE orders ALTER COLUMN course_id DROP NOT NULL;

    -- Agregar subtotal si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'subtotal') THEN
        ALTER TABLE orders ADD COLUMN subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0.00;
    END IF;

    -- Agregar discount si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'discount') THEN
        ALTER TABLE orders ADD COLUMN discount NUMERIC(10, 2) NOT NULL DEFAULT 0.00;
    END IF;

    -- Agregar coupon_code si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'coupon_code') THEN
        ALTER TABLE orders ADD COLUMN coupon_code VARCHAR(50);
    END IF;

    -- Agregar shipping_cost si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_cost') THEN
        ALTER TABLE orders ADD COLUMN shipping_cost NUMERIC(10, 2) NOT NULL DEFAULT 0.00;
    END IF;

    -- Agregar shipping_address si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_address') THEN
        ALTER TABLE orders ADD COLUMN shipping_address JSONB;
    END IF;

    -- Agregar shipping_status si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'shipping_status') THEN
        ALTER TABLE orders ADD COLUMN shipping_status VARCHAR(50) NOT NULL DEFAULT 'NO_APLICA';
    END IF;
END $$;

-- 6. Tabla de Ítems de la Orden (Order Items)
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL, -- 'CURSO' o 'PRODUCTO'
    item_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    subtotal NUMERIC(10, 2) NOT NULL,
    download_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);

-- 7. Migración de órdenes previas al nuevo formato multi-ítem
DO $$
DECLARE
    r RECORD;
    c_title VARCHAR(255);
BEGIN
    FOR r IN SELECT * FROM orders WHERE id NOT IN (SELECT DISTINCT order_id FROM order_items) LOOP
        -- Obtener título del curso si existe
        SELECT title INTO c_title FROM courses WHERE id = r.course_id;
        IF c_title IS NULL THEN
            c_title := 'Curso de Arte #' || COALESCE(r.course_id::text, '1');
        END IF;

        -- Insertar en order_items
        INSERT INTO order_items (order_id, item_type, item_id, name, unit_price, quantity, subtotal)
        VALUES (r.id, 'CURSO', COALESCE(r.course_id, 1), c_title, r.amount, 1, r.amount);

        -- Actualizar columnas subtotal y shipping_status en orden
        UPDATE orders 
        SET subtotal = r.amount,
            discount = 0.00,
            shipping_cost = 0.00,
            shipping_status = 'NO_APLICA'
        WHERE id = r.id;
    END LOOP;
END $$;
