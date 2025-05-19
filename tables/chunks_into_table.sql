CREATE TABLE masas_agua AS
SELECT * FROM chunk_1;

INSERT INTO masas_agua
SELECT * FROM chunk_3;

SELECT column_name
FROM information_schema.columns
WHERE table_name = 'masas_agua'
  AND table_schema = 'public';
  
ALTER TABLE masas_agua
ALTER COLUMN tipocalib TYPE VARCHAR(255);

INSERT INTO masas_agua
SELECT * FROM chunk_4;

INSERT INTO masas_agua
SELECT * FROM chunk_6;

ALTER TABLE masas_agua
ALTER COLUMN nombreint TYPE VARCHAR(255);

INSERT INTO masas_agua
SELECT * FROM chunk_5;

INSERT INTO masas_agua
SELECT * FROM chunk_2_1;

INSERT INTO masas_agua
SELECT * FROM chunk_2_2;

INSERT INTO masas_agua
SELECT * FROM chunk_2_3;

INSERT INTO masas_agua
SELECT * FROM chunk_2_4;

DROP TABLE IF EXISTS chunk_1;
DROP TABLE IF EXISTS chunk_3;
DROP TABLE IF EXISTS chunk_4;
DROP TABLE IF EXISTS chunk_5;
DROP TABLE IF EXISTS chunk_6;
DROP TABLE IF EXISTS chunk_2_1;
DROP TABLE IF EXISTS chunk_2_2;
DROP TABLE IF EXISTS chunk_2_3;
DROP TABLE IF EXISTS chunk_2_4;
