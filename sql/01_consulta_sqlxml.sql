-- =====================================================================
-- Laboratorio 1 - Almacenamiento y validación de ficheros XML en Oracle
-- Fichero 01: Recuperación de datos del esquema HR en formato XML (SQL/XML)
-- Autor: Juan Diego Zambrano Guerrero (223179011)
-- Ejecutar conectado como HR en SQL Developer.
--
-- Tablas combinadas (5): DEPARTMENTS, LOCATIONS, COUNTRIES, EMPLOYEES, JOBS
-- Funciones SQL/XML usadas: XMLELEMENT, XMLATTRIBUTES, XMLFOREST, XMLAGG
--                           (+ XMLROOT y XMLSERIALIZE para dar formato)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. (Opcional) Comprobar que las tablas tienen datos
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS departamentos FROM departments;
SELECT COUNT(*) AS empleados     FROM employees;

-- ---------------------------------------------------------------------
-- 1. Consulta SQL/XML: un documento <Departamentos> con cada
--    departamento que tiene empleados, su ubicación y sus empleados.
--    Devuelve UNA fila de tipo XMLTYPE.
-- ---------------------------------------------------------------------
SELECT XMLELEMENT("Departamentos",
         -- Referencia al esquema (necesaria luego para insertar en Oracle)
         XMLATTRIBUTES(
           'http://www.w3.org/2001/XMLSchema-instance'   AS "xmlns:xsi",
           'http://localhost/hr/departamentos.xsd'        AS "xsi:noNamespaceSchemaLocation"),
         XMLAGG(
           XMLELEMENT("Departamento",
             XMLATTRIBUTES(d.department_id   AS "id",
                           d.department_name AS "nombre"),
             -- Ubicación: LOCATIONS + COUNTRIES
             XMLELEMENT("Ubicacion",
               XMLFOREST(l.city         AS "Ciudad",
                         c.country_name AS "Pais")),
             -- Empleados del departamento: EMPLOYEES + JOBS
             XMLELEMENT("Empleados",
               (SELECT XMLAGG(
                         XMLELEMENT("Empleado",
                           XMLATTRIBUTES(e.employee_id AS "id"),
                           XMLFOREST(e.first_name                       AS "Nombre",
                                     e.last_name                        AS "Apellido",
                                     e.email                            AS "Email",
                                     TO_CHAR(e.hire_date, 'YYYY-MM-DD') AS "FechaContratacion",
                                     j.job_title                        AS "Puesto",
                                     e.salary                           AS "Salario",
                                     e.commission_pct                   AS "Comision"))
                         ORDER BY e.employee_id)
                  FROM employees e
                  JOIN jobs j ON j.job_id = e.job_id
                 WHERE e.department_id = d.department_id))
           )
           ORDER BY d.department_id)
       ) AS xml_departamentos
  FROM departments d
  JOIN locations  l ON l.location_id = d.location_id
  JOIN countries  c ON c.country_id  = l.country_id
 WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department_id = d.department_id);

-- ---------------------------------------------------------------------
-- 2. Misma consulta, pero serializada con prólogo e indentación para
--    copiar el resultado a un fichero (departamentos.xml) y validarlo
--    en la herramienta web. En SQL Developer: ejecutar con F5 (script)
--    o hacer doble clic en la celda del resultado y copiar.
-- ---------------------------------------------------------------------
SELECT XMLSERIALIZE(DOCUMENT
         XMLROOT(
           XMLELEMENT("Departamentos",
             XMLATTRIBUTES(
               'http://www.w3.org/2001/XMLSchema-instance' AS "xmlns:xsi",
               'http://localhost/hr/departamentos.xsd'      AS "xsi:noNamespaceSchemaLocation"),
             XMLAGG(
               XMLELEMENT("Departamento",
                 XMLATTRIBUTES(d.department_id AS "id", d.department_name AS "nombre"),
                 XMLELEMENT("Ubicacion",
                   XMLFOREST(l.city AS "Ciudad", c.country_name AS "Pais")),
                 XMLELEMENT("Empleados",
                   (SELECT XMLAGG(
                             XMLELEMENT("Empleado",
                               XMLATTRIBUTES(e.employee_id AS "id"),
                               XMLFOREST(e.first_name                       AS "Nombre",
                                         e.last_name                        AS "Apellido",
                                         e.email                            AS "Email",
                                         TO_CHAR(e.hire_date, 'YYYY-MM-DD') AS "FechaContratacion",
                                         j.job_title                        AS "Puesto",
                                         e.salary                           AS "Salario",
                                         e.commission_pct                   AS "Comision"))
                             ORDER BY e.employee_id)
                      FROM employees e
                      JOIN jobs j ON j.job_id = e.job_id
                     WHERE e.department_id = d.department_id)))
               ORDER BY d.department_id)),
           VERSION '1.0')
         AS CLOB INDENT SIZE = 2) AS xml_departamentos
  FROM departments d
  JOIN locations  l ON l.location_id = d.location_id
  JOIN countries  c ON c.country_id  = l.country_id
 WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department_id = d.department_id);

-- ---------------------------------------------------------------------
-- 3. (Opcional) Versión reducida a 3 departamentos, útil para las
--    capturas de la memoria (resultado corto y legible).
-- ---------------------------------------------------------------------
SELECT XMLSERIALIZE(DOCUMENT
         XMLELEMENT("Departamentos",
           XMLAGG(
             XMLELEMENT("Departamento",
               XMLATTRIBUTES(d.department_id AS "id", d.department_name AS "nombre"),
               XMLELEMENT("Ubicacion",
                 XMLFOREST(l.city AS "Ciudad", c.country_name AS "Pais")),
               XMLELEMENT("Empleados",
                 (SELECT XMLAGG(
                           XMLELEMENT("Empleado",
                             XMLATTRIBUTES(e.employee_id AS "id"),
                             XMLFOREST(e.first_name AS "Nombre", e.last_name AS "Apellido",
                                       e.email AS "Email",
                                       TO_CHAR(e.hire_date, 'YYYY-MM-DD') AS "FechaContratacion",
                                       j.job_title AS "Puesto", e.salary AS "Salario",
                                       e.commission_pct AS "Comision"))
                           ORDER BY e.employee_id)
                    FROM employees e JOIN jobs j ON j.job_id = e.job_id
                   WHERE e.department_id = d.department_id)))
             ORDER BY d.department_id))
         AS CLOB INDENT SIZE = 2) AS xml_departamentos
  FROM departments d
  JOIN locations  l ON l.location_id = d.location_id
  JOIN countries  c ON c.country_id  = l.country_id
 WHERE d.department_id IN (10, 20, 90);
