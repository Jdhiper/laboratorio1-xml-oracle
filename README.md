# Laboratorio 1 – Almacenamiento y validación de ficheros XML en Oracle

**Estudiante:** Juan Diego Zambrano Guerrero (223179011)
**Asignatura:** Bases de datos – Ingeniería Informática

Recuperación de datos del esquema **HR** de Oracle Database 21c XE (PDB `XEPDB1`) en formato XML con SQL/XML,
validación contra un esquema XSD propio, registro del esquema en Oracle e
inserciones válidas y no válidas.

## Estructura

```
.
├── sql/
│   ├── 00_instalar_hr.sql        # Crea el usuario HR con sus tablas y datos (ejecutar como SYSTEM en XEPDB1)
│   ├── 01_consulta_sqlxml.sql    # Consulta SQL/XML (XMLELEMENT, XMLATTRIBUTES, XMLFOREST, XMLAGG)
│   ├── 02_registro_esquema.sql   # DBMS_XMLSCHEMA.registerSchema + tabla XMLType + trigger de validación
│   └── 03_inserciones.sql        # Inserción válida, inserción desde la consulta e inserciones no válidas
├── xsd/
│   └── departamentos.xsd         # Esquema XML
└── xml/
    ├── departamentos_ejemplo.xml # XML que genera la consulta con los datos de HR (válido)
    └── departamentos_invalido.xml# Documento que incumple el esquema (para la prueba web)
```

## Tablas de HR combinadas

`DEPARTMENTS`, `LOCATIONS`, `COUNTRIES`, `EMPLOYEES`, `JOBS`

## Orden de ejecución (SQL Developer, conectado como HR)

0. `sql/00_instalar_hr.sql` – como SYSTEM en XEPDB1.
1. `sql/01_consulta_sqlxml.sql` – genera el XML (copiar el resultado a `departamentos.xml`).
2. Validar `departamentos.xml` contra `xsd/departamentos.xsd` en
   <https://www.freeformatter.com/xml-validator-xsd.html>.
3. `sql/02_registro_esquema.sql` – registra el esquema y crea la tabla `XML_DEPARTAMENTOS`.
4. `sql/03_inserciones.sql` – inserciones válidas (se aceptan) y no válidas (Oracle las rechaza con ORA-31154 / LSX).

## Requisito previo: esquema HR en Oracle 21c XE

Oracle 21c no trae HR. Abrir `sql/00_instalar_hr.sql` en SQL Developer con la
conexión SYSTEM apuntando al servicio `xepdb1` y ejecutar con F5. Crea el usuario
`hr` (contraseña `hr`) con las tablas y datos oficiales de
<https://github.com/oracle-samples/db-sample-schemas>.

## Validación local (opcional)

```bash
xmllint --noout --schema xsd/departamentos.xsd xml/departamentos_ejemplo.xml
xmllint --noout --schema xsd/departamentos.xsd xml/departamentos_invalido.xml
```
# laboratorio1-xml-oracle
