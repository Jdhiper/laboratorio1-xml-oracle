-- =====================================================================
-- Laboratorio 1 - Almacenamiento y validación de ficheros XML en Oracle
-- Fichero 02: Registro del esquema XML en la base de datos
-- Autor: Juan Diego Zambrano Guerrero (223179011)
-- Ejecutar conectado como HR (F5 - "Ejecutar script" en SQL Developer).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. SOLO si la cuenta HR está bloqueada (Oracle 11g XE la trae así).
--    Ejecutar conectado como SYSTEM o SYS, y luego conectarse como HR:
--
--    ALTER USER hr ACCOUNT UNLOCK IDENTIFIED BY hr;
--    (En Oracle 21c XE, HR se instala con hr_install.sql en XEPDB1; ver README)
-- ---------------------------------------------------------------------

SET SERVEROUTPUT ON

-- ---------------------------------------------------------------------
-- 1. Limpieza (permite volver a ejecutar el script sin errores)
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE xml_departamentos PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_XMLSCHEMA.deleteSchema(
    schemaURL     => 'http://localhost/hr/departamentos.xsd',
    delete_option => DBMS_XMLSCHEMA.DELETE_CASCADE_FORCE);
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ---------------------------------------------------------------------
-- 2. Registro del esquema XSD (mismo contenido que departamentos.xsd)
-- ---------------------------------------------------------------------
DECLARE
  l_xsd VARCHAR2(32767) := q'[<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
           elementFormDefault="qualified">

  <xs:simpleType name="tTexto20">
    <xs:restriction base="xs:string">
      <xs:minLength value="1"/>
      <xs:maxLength value="20"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="tTexto25">
    <xs:restriction base="xs:string">
      <xs:minLength value="1"/>
      <xs:maxLength value="25"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="tTexto40">
    <xs:restriction base="xs:string">
      <xs:minLength value="1"/>
      <xs:maxLength value="40"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="tTexto60">
    <xs:restriction base="xs:string">
      <xs:minLength value="1"/>
      <xs:maxLength value="60"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="tEmail">
    <xs:restriction base="xs:string">
      <xs:pattern value="[A-Z0-9_]{1,25}"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="tSalario">
    <xs:restriction base="xs:decimal">
      <xs:minExclusive value="0"/>
      <xs:totalDigits value="8"/>
      <xs:fractionDigits value="2"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="tComision">
    <xs:restriction base="xs:decimal">
      <xs:minInclusive value="0"/>
      <xs:maxExclusive value="1"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:complexType name="tUbicacion">
    <xs:sequence>
      <xs:element name="Ciudad" type="tTexto40"/>
      <xs:element name="Pais"   type="tTexto60"/>
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="tEmpleado">
    <xs:sequence>
      <xs:element name="Nombre"            type="tTexto20" minOccurs="0"/>
      <xs:element name="Apellido"          type="tTexto25"/>
      <xs:element name="Email"             type="tEmail"/>
      <xs:element name="FechaContratacion" type="xs:date"/>
      <xs:element name="Puesto"            type="tTexto40"/>
      <xs:element name="Salario"           type="tSalario"/>
      <xs:element name="Comision"          type="tComision" minOccurs="0"/>
    </xs:sequence>
    <xs:attribute name="id" type="xs:positiveInteger" use="required"/>
  </xs:complexType>

  <xs:complexType name="tEmpleados">
    <xs:sequence>
      <xs:element name="Empleado" type="tEmpleado" maxOccurs="unbounded"/>
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="tDepartamento">
    <xs:sequence>
      <xs:element name="Ubicacion" type="tUbicacion"/>
      <xs:element name="Empleados" type="tEmpleados"/>
    </xs:sequence>
    <xs:attribute name="id"     type="xs:positiveInteger" use="required"/>
    <xs:attribute name="nombre" type="tTexto40"           use="required"/>
  </xs:complexType>

  <xs:element name="Departamentos">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="Departamento" type="tDepartamento" maxOccurs="unbounded"/>
      </xs:sequence>
    </xs:complexType>
    <xs:unique name="uqDepartamento">
      <xs:selector xpath="Departamento"/>
      <xs:field xpath="@id"/>
    </xs:unique>
    <xs:unique name="uqEmpleado">
      <xs:selector xpath="Departamento/Empleados/Empleado"/>
      <xs:field xpath="@id"/>
    </xs:unique>
  </xs:element>

</xs:schema>]';
BEGIN
  DBMS_XMLSCHEMA.registerSchema(
    schemaURL => 'http://localhost/hr/departamentos.xsd',
    schemaDoc => XMLTYPE(l_xsd),
    local     => TRUE,    -- visible solo para el usuario HR
    genTypes  => TRUE,    -- genera tipos objeto (almacenamiento estructurado)
    genTables => FALSE);  -- la tabla la creamos nosotros (paso 3)
  DBMS_OUTPUT.put_line('Esquema registrado correctamente.');
END;
/

-- Comprobación: el esquema aparece en el diccionario de datos
SELECT schema_url, local, qual_schema_url
  FROM user_xml_schemas
 WHERE schema_url = 'http://localhost/hr/departamentos.xsd';

-- ---------------------------------------------------------------------
-- 3. Tabla XMLType ligada al esquema registrado
-- ---------------------------------------------------------------------
CREATE TABLE xml_departamentos OF XMLTYPE
  XMLSCHEMA "http://localhost/hr/departamentos.xsd"
  ELEMENT   "Departamentos";

-- ---------------------------------------------------------------------
-- 4. Validación completa en cada inserción.
--    Con almacenamiento estructurado Oracle comprueba la estructura
--    (elementos y su orden), pero NO todas las restricciones (pattern,
--    minExclusive, maxLength...). El trigger llama a schemaValidate()
--    para forzar la validación completa contra el XSD.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_valida_departamentos
  BEFORE INSERT OR UPDATE ON xml_departamentos
  FOR EACH ROW
BEGIN
  IF :NEW.OBJECT_VALUE IS NOT NULL THEN
    :NEW.OBJECT_VALUE.schemaValidate();
  END IF;
END;
/

SELECT table_name, xmlschema, element_name
  FROM user_xml_tables
 WHERE table_name = 'XML_DEPARTAMENTOS';
