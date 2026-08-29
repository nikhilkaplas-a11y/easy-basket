CREATE TABLE IF NOT EXISTS support_requests (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,
    order_id INT NULL,

    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,

    status VARCHAR(50) NOT NULL DEFAULT 'open',

    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3),

    CONSTRAINT fk_support_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_support_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE SET NULL
);

CREATE INDEX idx_support_requests_user_id
    ON support_requests(user_id);

CREATE INDEX idx_support_requests_order_id
    ON support_requests(order_id);

CREATE INDEX idx_support_requests_status
    ON support_requests(status);