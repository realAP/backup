CREATE TABLE IF NOT EXISTS example_table (
                                             id SERIAL PRIMARY KEY,
                                             name TEXT NOT NULL,
                                             created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO example_table (name) VALUES ('Sample Data');
