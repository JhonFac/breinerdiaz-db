-- ==============================================================================
-- MIGRACIÓN 06: TASAS DE CAMBIO (TRM) Y CONVERSIÓN DE PRECIOS A COP (Sin decimales)
-- Tasa de conversión base acordada: $3.000 COP / USD
-- Redondeo cerrado a valores terminados en 900
-- ==============================================================================

-- 1. Tabla de tasas de cambio históricas
CREATE TABLE IF NOT EXISTS tasas_cambio (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    valor NUMERIC(10, 2) NOT NULL,
    fuente VARCHAR(100) NOT NULL DEFAULT 'datos.gov.co',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tasas_cambio_fecha ON tasas_cambio(fecha DESC);

-- Inserción de la tasa actual base ($3.000 COP)
INSERT INTO tasas_cambio (fecha, valor, fuente)
VALUES (CURRENT_DATE, 3000.00, 'datos.gov.co')
ON CONFLICT (fecha) DO UPDATE SET valor = EXCLUDED.valor;

-- 2. Actualización de precios en cursos a COP redondeados a 900
UPDATE courses
SET 
    price = (ROUND((price * 3000) / 1000) * 1000 - 100),
    original_price = CASE 
        WHEN original_price IS NOT NULL THEN (ROUND((original_price * 3000) / 1000) * 1000 - 100)
        ELSE NULL 
    END;

-- Modificar tipo de columna a BIGINT en courses
ALTER TABLE courses 
    ALTER COLUMN price TYPE BIGINT USING price::BIGINT,
    ALTER COLUMN original_price TYPE BIGINT USING original_price::BIGINT;

-- 3. Actualización de precios en productos de la tienda a COP redondeados a 900
UPDATE products
SET 
    price = (ROUND((price * 3000) / 1000) * 1000 - 100),
    original_price = CASE 
        WHEN original_price IS NOT NULL THEN (ROUND((original_price * 3000) / 1000) * 1000 - 100)
        ELSE NULL 
    END;

-- Modificar tipo de columna a BIGINT en products
ALTER TABLE products 
    ALTER COLUMN price TYPE BIGINT USING price::BIGINT,
    ALTER COLUMN original_price TYPE BIGINT USING original_price::BIGINT;
