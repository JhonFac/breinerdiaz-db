-- ==============================================================================
-- 07-epayco-pagos-eventos.sql
-- Integración Pasarela de Pagos ePayco y Auditoría de Eventos (pagos_eventos)
-- ==============================================================================

BEGIN;

-- 1. Ampliar precisión de montos en orders y order_items para soportar COP y USD holgadamente
ALTER TABLE orders
  ALTER COLUMN subtotal TYPE NUMERIC(14, 2),
  ALTER COLUMN discount TYPE NUMERIC(14, 2),
  ALTER COLUMN shipping_cost TYPE NUMERIC(14, 2),
  ALTER COLUMN amount TYPE NUMERIC(14, 2);

ALTER TABLE order_items
  ALTER COLUMN unit_price TYPE NUMERIC(14, 2),
  ALTER COLUMN subtotal TYPE NUMERIC(14, 2);

-- 2. Columnas de trazabilidad de pago en orders
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS epayco_ref VARCHAR(100),
  ADD COLUMN IF NOT EXISTS payment_created_at TIMESTAMPTZ DEFAULT NOW();

-- 3. Tabla de auditoría de eventos de pago (webhooks ePayco)
CREATE TABLE IF NOT EXISTS pagos_eventos (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL,
    reference VARCHAR(100),
    x_ref_payco VARCHAR(100),
    x_transaction_id VARCHAR(100),
    x_cod_response INTEGER,
    x_response_reason_text TEXT,
    signature_valid BOOLEAN NOT NULL DEFAULT FALSE,
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pagos_eventos_reference ON pagos_eventos(reference);
CREATE INDEX IF NOT EXISTS idx_pagos_eventos_x_ref_payco ON pagos_eventos(x_ref_payco);
CREATE INDEX IF NOT EXISTS ix_orders_reference ON orders(reference);

COMMIT;
