-- =====================================================================
-- Laboratorio 1 - Almacenamiento y validación de ficheros XML en Oracle
-- Fichero 03: Inserciones en la tabla ligada al esquema registrado
-- Autor: Juan Diego Zambrano Guerrero (223179011)
-- Requisito: haber ejecutado 02_registro_esquema.sql
-- Ejecutar como script (F5) en SQL Developer.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. INSERCIÓN VÁLIDA (documento escrito a mano, conforme al XSD)
--    Resultado esperado: "1 fila insertadas."
-- ---------------------------------------------------------------------
INSERT INTO xml_departamentos VALUES (XMLTYPE(
'<Departamentos xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="http://localhost/hr/departamentos.xsd">
  <Departamento id="10" nombre="Administration">
    <Ubicacion>
      <Ciudad>Seattle</Ciudad>
      <Pais>United States of America</Pais>
    </Ubicacion>
    <Empleados>
      <Empleado id="200">
        <Nombre>Jennifer</Nombre>
        <Apellido>Whalen</Apellido>
        <Email>JWHALEN</Email>
        <FechaContratacion>1987-09-17</FechaContratacion>
        <Puesto>Administration Assistant</Puesto>
        <Salario>4400</Salario>
      </Empleado>
    </Empleados>
  </Departamento>
  <Departamento id="80" nombre="Sales">
    <Ubicacion>
      <Ciudad>Oxford</Ciudad>
      <Pais>United Kingdom</Pais>
    </Ubicacion>
    <Empleados>
      <Empleado id="145">
        <Nombre>John</Nombre>
        <Apellido>Russell</Apellido>
        <Email>JRUSSEL</Email>
        <FechaContratacion>1996-10-01</FechaContratacion>
        <Puesto>Sales Manager</Puesto>
        <Salario>14000</Salario>
        <Comision>.4</Comision>
      </Empleado>
    </Empleados>
  </Departamento>
</Departamentos>'));

-- ---------------------------------------------------------------------
-- 2. INSERCIÓN VÁLIDA a partir de la propia consulta SQL/XML
--    (demuestra que el XML generado desde HR cumple el esquema)
--    Resultado esperado: "1 fila insertadas."
-- ---------------------------------------------------------------------
INSERT INTO xml_departamentos
SELECT XMLELEMENT("Departamentos",
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
                           XMLFOREST(e.first_name AS "Nombre", e.last_name AS "Apellido",
                                     e.email AS "Email",
                                     TO_CHAR(e.hire_date, 'YYYY-MM-DD') AS "FechaContratacion",
                                     j.job_title AS "Puesto", e.salary AS "Salario",
                                     e.commission_pct AS "Comision"))
                         ORDER BY e.employee_id)
                  FROM employees e JOIN jobs j ON j.job_id = e.job_id
                 WHERE e.department_id = d.department_id)))
           ORDER BY d.department_id))
  FROM departments d
  JOIN locations  l ON l.location_id = d.location_id
  JOIN countries  c ON c.country_id  = l.country_id
 WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department_id = d.department_id);

COMMIT;

-- Comprobación de lo insertado
SELECT COUNT(*) AS documentos FROM xml_departamentos;

SELECT x.dep_id, x.dep_nombre, x.num_empleados
  FROM xml_departamentos t,
       XMLTABLE('/Departamentos/Departamento' PASSING t.OBJECT_VALUE
                COLUMNS dep_id        NUMBER        PATH '@id',
                        dep_nombre    VARCHAR2(40)  PATH '@nombre',
                        num_empleados NUMBER        PATH 'count(Empleados/Empleado)') x;

-- ---------------------------------------------------------------------
-- 3. INSERCIÓN NO VÁLIDA (incumple el esquema en varios puntos)
--    - Falta el elemento obligatorio <Apellido>
--    - <Email> en minúsculas (no cumple el pattern [A-Z0-9_])
--    - <FechaContratacion> no es una fecha xs:date
--    - <Salario> negativo (minExclusive = 0)
--    - <Departamento> sin el atributo obligatorio "nombre"
--    Resultado esperado: error ORA-31154 / ORA-19202 / LSX-00xxx
--    y la fila NO se inserta.
-- ---------------------------------------------------------------------
INSERT INTO xml_departamentos VALUES (XMLTYPE(
'<Departamentos xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="http://localhost/hr/departamentos.xsd">
  <Departamento id="999">
    <Ubicacion>
      <Ciudad>Pasto</Ciudad>
      <Pais>Colombia</Pais>
    </Ubicacion>
    <Empleados>
      <Empleado id="9001">
        <Nombre>Juan</Nombre>
        <Email>juan.zambrano</Email>
        <FechaContratacion>09/11/2026</FechaContratacion>
        <Puesto>Analista</Puesto>
        <Salario>-1500</Salario>
      </Empleado>
    </Empleados>
  </Departamento>
</Departamentos>'));

-- ---------------------------------------------------------------------
-- 4. (Opcional) Inserciones no válidas con UN solo error cada una,
--    para mostrar en la memoria qué restricción detecta Oracle.
-- ---------------------------------------------------------------------

-- 4a. Salario negativo -> viola minExclusive
INSERT INTO xml_departamentos VALUES (XMLTYPE(
'<Departamentos xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="http://localhost/hr/departamentos.xsd">
  <Departamento id="998" nombre="Pruebas">
    <Ubicacion><Ciudad>Pasto</Ciudad><Pais>Colombia</Pais></Ubicacion>
    <Empleados>
      <Empleado id="9002">
        <Nombre>Ana</Nombre><Apellido>Ruiz</Apellido><Email>ARUIZ</Email>
        <FechaContratacion>2020-01-15</FechaContratacion>
        <Puesto>Analista</Puesto><Salario>-1500</Salario>
      </Empleado>
    </Empleados>
  </Departamento>
</Departamentos>'));

-- 4b. Elementos en orden incorrecto (<Email> antes de <Apellido>)
INSERT INTO xml_departamentos VALUES (XMLTYPE(
'<Departamentos xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="http://localhost/hr/departamentos.xsd">
  <Departamento id="997" nombre="Pruebas">
    <Ubicacion><Ciudad>Pasto</Ciudad><Pais>Colombia</Pais></Ubicacion>
    <Empleados>
      <Empleado id="9003">
        <Nombre>Luis</Nombre><Email>LPEREZ</Email><Apellido>Perez</Apellido>
        <FechaContratacion>2021-03-01</FechaContratacion>
        <Puesto>Analista</Puesto><Salario>2500</Salario>
      </Empleado>
    </Empleados>
  </Departamento>
</Departamentos>'));

-- Comprobación final: siguen solo los documentos válidos
SELECT COUNT(*) AS documentos FROM xml_departamentos;
