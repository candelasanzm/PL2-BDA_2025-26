-- Todo lo que ejecutemos relativo a este fichero se ejecuta en la base de datos matriculas

---------- Cuestión 0
SELECT pg_reload_conf();

---------- Cuestión 2

-- Borramos las tablas para en caso de necesidad relanzarlos sin problemas
DROP TABLE IF EXISTS public.matriculas;
DROP TABLE IF EXISTS public.asignaturas;
DROP TABLE IF EXISTS public.estudiantes;

-- Creamos las tablas pedidas
CREATE TABLE public.estudiantes(
    carnet NUMERIC PRIMARY KEY,
    nombre TEXT,
    apellidos TEXT,
    creditos NUMERIC
);

CREATE TABLE public.asignaturas(
    codigo NUMERIC PRIMARY KEY,
    nombre TEXT,
    caracter TEXT,
    creditos NUMERIC
);

CREATE TABLE public.matriculas(
    carnet_estu NUMERIC,
    codigo_asig NUMERIC,
    nota NUMERIC,

    CONSTRAINT pk_matriculas PRIMARY KEY (carnet_estu, codigo_asig),

    CONSTRAINT fk_matriculas_estudiantes FOREIGN KEY (carnet_estu) REFERENCES public.estudiantes(carnet) ON DELETE RESTRICT ON UPDATE RESTRICT,

    CONSTRAINT fk_matriculas_asignaturas FOREIGN KEY (codigo_asig) REFERENCES public.asignaturas(codigo) ON DELETE RESTRICT ON UPDATE RESTRICT
);

-- Importamos los datos en las tablas
COPY public.estudiantes(carnet, nombre, apellidos, creditos)
FROM 'C:\database_UAH\BD\PL2\datos_estudiantes.csv'
WITH (FORMAT csv, HEADER false, DELIMITER ',');

COPY public.asignaturas(codigo, nombre, caracter, creditos)
FROM 'C:\database_UAH\BD\PL2\datos_asignaturas.csv'
WITH (FORMAT csv, HEADER false, DELIMITER ',');

COPY public.matriculas(carnet_estu, codigo_asig, nota)
FROM 'C:\database_UAH\BD\PL2\datos_matriculas.csv'
WITH (FORMAT csv, HEADER false, DELIMITER ',');

-- Actualizamos estadísticas
ANALYZE public.estudiantes;
ANALYZE public.asignaturas;
ANALYZE public.matriculas;

---------- Cuestión 3

-- Veamos las estadísticas de cada tabla
SELECT * FROM pg_stats WHERE tablename IN ('estudiantes', 'asignaturas', 'matriculas');

---------- Cuestión 4

-- Aplicar Explain a la consulta

EXPLAIN SELECT COUNT(*)
FROM public.estudiantes
WHERE creditos < 100;

-- Para poder comparar con la teoría necesito:

    -- Valor real
SELECT COUNT(*)
FROM public.estudiantes
WHERE creditos < 100;

    -- El total de filas
SELECT reltuples FROM pg_class WHERE relname = 'estudiantes';

---------- Cuestión 5

-- Aplico el comando EXPLAIN a la consulta
EXPLAIN SELECT nombre
FROM public.estudiantes
WHERE creditos = 150 AND carnet IN (
    SELECT carnet_estu
    FROM public.matriculas
    WHERE nota >= 5
    GROUP BY carnet_estu
    HAVING COUNT(*) >= 3
);

-- Para poder comparar con la teoría necesito:

    -- Valor real
SELECT nombre
FROM public.estudiantes
WHERE creditos = 150 AND carnet IN (
    SELECT carnet_estu
    FROM public.matriculas
    WHERE nota >= 5
    GROUP BY carnet_estu
    HAVING COUNT(*) >= 3
);

    -- Estadísticas de créditos=150
SELECT most_common_vals, most_common_freqs
FROM pg_stats
WHERE tablename = 'estudiantes' AND attname = 'creditos';

    -- Estadísticas de nota>=5
SELECT most_common_vals, most_common_freqs
FROM pg_stats
WHERE tablename = 'matriculas' AND attname = 'nota';

    -- El total de filas
SELECT reltuples FROM pg_class WHERE relname = 'estudiantes';
SELECT reltuples FROM pg_class WHERE relname = 'matriculas';

---------- Cuestión 6

-- Aplico EXPLAIN
EXPLAIN SELECT DISTINCT a.nombre
FROM public.asignaturas a
JOIN public.matriculas m ON a.codigo = m.codigo_asig
JOIN public.estudiantes e ON m.carnet_estu = e.carnet
WHERE a.creditos = 10 AND m.nota = 7 AND e.creditos = 50;

-- Valor real
SELECT COUNT(DISTINCT a.nombre)
FROM public.asignaturas a
JOIN public.matriculas m ON a.codigo = m.codigo_asig
JOIN public.estudiantes e ON m.carnet_estu = e.carnet
WHERE a.creditos = 10 AND m.nota = 7 AND e.creditos = 50;