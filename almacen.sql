DROP DATABASE IF EXISTS almacen;

CREATE DATABASE almacen;
USE almacen;

-- -----------------------------------------------------
-- Tabla de Categoria
-- -----------------------------------------------------
CREATE TABLE categoria
(
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    descripcion varchar(255) NOT NULL
);

-- -----------------------------------------------------
-- Tabla de Producto
-- -----------------------------------------------------

CREATE TABLE producto
(
    id                INT AUTO_INCREMENT PRIMARY KEY,
    codigo_unico      VARCHAR(50)    NOT NULL UNIQUE,
    nombre            VARCHAR(100)   NOT NULL,
    fecha_vencimiento DATE,
    precio            DECIMAL(10, 2) NOT NULL,
    cantidad_en_stock INT            NOT NULL,
    categoria_id      INT,
    is_active         BOOLEAN        NOT NULL DEFAULT TRUE,
    FOREIGN KEY (categoria_id) REFERENCES categoria (id)
);

-- -----------------------------------------------------
-- Tabla de Puesto
-- -----------------------------------------------------
CREATE TABLE puesto
(
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    descripcion varchar(255) NOT NULL
);

-- -----------------------------------------------------
-- Tabla de Empleado
-- -----------------------------------------------------
CREATE TABLE empleado
(
    id               INT AUTO_INCREMENT PRIMARY KEY,
    dni              VARCHAR(20)  NOT NULL UNIQUE,
    primer_nombre    VARCHAR(50)  NOT NULL,
    segundo_nombre   VARCHAR(50),
    apellido         VARCHAR(50)  NOT NULL,
    email            VARCHAR(100) NOT NULL,
    telefono         VARCHAR(20),
    fecha_nacimiento DATE         NOT NULL,
    puesto_id        INT          NOT NULL,
    calle            VARCHAR(100) NOT NULL,
    numero_calle     VARCHAR(10)  NOT NULL,
    piso             VARCHAR(10),
    departamento     VARCHAR(10),
    codigo_postal    VARCHAR(10),
    FOREIGN KEY (puesto_id) REFERENCES puesto (id)
);

-- -----------------------------------------------------
-- Tabla de Historial de Ingresos
-- -----------------------------------------------------
CREATE TABLE historial_ingresos
(
    id            INT AUTO_INCREMENT PRIMARY KEY,
    producto_id   INT,
    fecha_ingreso DATETIME NOT NULL,
    usuario   VARCHAR(50)    NOT NULL,
    FOREIGN KEY (producto_id) REFERENCES producto (id)
);

-- -----------------------------------------------------
-- Tabla de Historial de Precios
-- -----------------------------------------------------
CREATE TABLE historial_precios
(
    id              INT AUTO_INCREMENT PRIMARY KEY,
    producto_id     INT            NOT NULL,
    fecha_cambio    DATETIME       NOT NULL,
    precio_anterior DECIMAL(10, 2) NOT NULL,
    precio_nuevo    DECIMAL(10, 2) NOT NULL,
    usuario         VARCHAR(50)    NOT NULL,
    FOREIGN KEY (producto_id) REFERENCES producto (id)
);

-- -----------------------------------------------------
-- Tabla de Productos Eliminados
-- -----------------------------------------------------
CREATE TABLE producto_eliminado
(
    id                INT AUTO_INCREMENT PRIMARY KEY,
    producto_id       INT          NOT NULL,
    fecha_eliminacion DATETIME     NOT NULL,
    usuario           VARCHAR(100) NOT NULL,
    FOREIGN KEY (producto_id) REFERENCES producto (id)
);

-- -----------------------------------------------------
-- Procedimiento de Insertar Producto
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS insertar_producto;

DELIMITER //

CREATE PROCEDURE insertar_producto(
    IN p_codigo_unico VARCHAR(50),
    IN p_nombre VARCHAR(100),
    IN p_fecha_vencimiento DATE,
    IN p_precio DECIMAL(10, 2),
    IN p_cantidad_en_stock INT,
    IN p_categoria_id INT,
    OUT p_id_producto INT
)
BEGIN
    INSERT INTO producto (codigo_unico, nombre, fecha_vencimiento, precio, cantidad_en_stock, categoria_id)
    VALUES (p_codigo_unico,
            p_nombre,
            p_fecha_vencimiento,
            p_precio,
            p_cantidad_en_stock,
            p_categoria_id);
    SELECT LAST_INSERT_ID()
    INTO p_id_producto;
END;

-- -----------------------------------------------------
-- Procedimiento ALTA_EMPLEADO
-- -----------------------------------------------------
DELIMITER //

CREATE PROCEDURE alta_empleado(
    IN p_dni VARCHAR(20),
    IN p_primer_nombre VARCHAR(50),
    IN p_segundo_nombre VARCHAR(50),
    IN p_apellido VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_telefono VARCHAR(20),
    IN p_fecha_nacimiento DATE,
    IN p_puesto_id INT,
    IN p_calle VARCHAR(100),
    IN p_numero_calle VARCHAR(10),
    IN p_piso VARCHAR(10),
    IN p_departamento VARCHAR(10),
    IN p_codigo_postal VARCHAR(10),
    OUT resultado INT
)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            SET resultado = 0;
        END;

    INSERT INTO empleado (dni, primer_nombre, segundo_nombre, apellido, email, telefono, fecha_nacimiento, puesto_id,
                          calle, numero_calle,
                          piso, departamento, codigo_postal)
    VALUES (p_dni, p_primer_nombre, IF(p_segundo_nombre = '', NULL, p_segundo_nombre), p_apellido, p_email, p_telefono,
            p_fecha_nacimiento, p_puesto_id, p_calle, p_numero_calle,
            p_piso, p_departamento, p_codigo_postal);

    SET resultado = 1;
END //

DELIMITER ;


-- -----------------------------------------------------
-- Procedimiento MODIFICAR_DOMICILIO
-- -----------------------------------------------------
DELIMITER //

CREATE PROCEDURE modificar_domicilio(
    IN p_dni VARCHAR(20),
    IN p_calle VARCHAR(100),
    IN p_numero_calle VARCHAR(10),
    IN p_piso VARCHAR(10),
    IN p_departamento VARCHAR(10),
    IN p_codigo_postal VARCHAR(10),
    OUT p_nombre_completo VARCHAR(101),
    OUT p_direccion_nueva VARCHAR(151)
)
BEGIN
    UPDATE empleado
    SET calle         = p_calle,
        numero_calle  = p_numero_calle,
        piso          = p_piso,
        departamento  = p_departamento,
        codigo_postal = p_codigo_postal
    WHERE dni = p_dni;

    SELECT CONCAT(primer_nombre, ' ', IFNULL(segundo_nombre, ''), ' ', apellido)
    INTO p_nombre_completo
    FROM empleado
    WHERE dni = p_dni;

    SELECT CONCAT(calle, ' ', numero_calle, ' Piso: ', IFNULL(piso, ''), ' Depto: ', IFNULL(departamento, ''), ' CP: ',
                  codigo_postal)
    INTO p_direccion_nueva
    FROM empleado
    WHERE dni = p_dni;
END //

DELIMITER ;

-- -----------------------------------------------------
-- Trigger TRG_INGRESO_PRODUCTO
-- -----------------------------------------------------
DELIMITER //

CREATE TRIGGER trg_ingreso_producto
    AFTER INSERT
    ON producto
    FOR EACH ROW
BEGIN
    INSERT INTO historial_ingresos (producto_id, fecha_ingreso, usuario)
    VALUES (NEW.id, NOW(), USER());
END //

DELIMITER ;

-- -----------------------------------------------------
-- Trigger TRG_CAMBIO_PRECIO
-- -----------------------------------------------------
DELIMITER //

CREATE TRIGGER trg_cambio_precio
    BEFORE UPDATE
    ON producto
    FOR EACH ROW
BEGIN
    IF OLD.precio <> NEW.precio THEN
        INSERT INTO historial_precios (producto_id, fecha_cambio, precio_anterior, precio_nuevo, usuario)
        VALUES (OLD.id, NOW(), OLD.precio, NEW.precio, USER());
    END IF;
END //

DELIMITER ;

-- -----------------------------------------------------
-- Trigger TRG_ELIMINAR_PRODUCTO
-- -----------------------------------------------------
DELIMITER //

CREATE TRIGGER trg_eliminar_producto
    BEFORE DELETE
    ON producto
    FOR EACH ROW
BEGIN
    INSERT INTO producto_eliminado (producto_id, fecha_eliminacion, usuario)
    VALUES (OLD.id, NOW(), USER());
END //

DELIMITER ;


-- -----------------------------------------------------
-- Inserts de Categoria
-- -----------------------------------------------------
INSERT INTO categoria (nombre, descripcion)
VALUES ('Electrónica', 'Dispositivos electrónicos');
INSERT INTO categoria (nombre, descripcion)
VALUES ('Limpieza', 'Artículos de limpieza');
INSERT INTO categoria (nombre, descripcion)
VALUES ('Cosmetica', 'Productos de cosmética');
INSERT INTO categoria (nombre, descripcion)
VALUES ('Alimentos', 'Productos alimenticios');
INSERT INTO categoria (nombre, descripcion)
VALUES ('Bebidas', 'Productos de bebidas');
INSERT INTO categoria (nombre, descripcion)
VALUES ('Artículos de vestir', 'Productos de vestir');

-- -----------------------------------------------------
-- Inserts de Puesto
-- -----------------------------------------------------
INSERT INTO puesto (nombre, descripcion)
VALUES ('Gerente', 'Responsable de la gestión del almacén');
INSERT INTO puesto (nombre, descripcion)
VALUES ('Administrador', 'Responsable de la gestión de los productos');
INSERT INTO puesto (nombre, descripcion)
VALUES ('Vendedor', 'Responsable de Venta');

-- -----------------------------------------------------
-- Inserts de Empleado
-- -----------------------------------------------------
SET @resultado = 0;
CALL alta_empleado(
        '12345678',
        'Juan',
        '',
        'Pérez',
        'juan.perez@example.com',
        '123456789',
        '1985-04-23',
        1,
        'Calle Falsa',
        '123',
        '3',
        'B',
        '4567',
        @resultado);
SELECT @resultado;
SET @resultado = 0;
CALL alta_empleado(
        '11223344',
        'Carlos',
        '',
        'González',
        'carlos.gonzalez@example.com',
        '123456789',
        '1989-08-21',
        2,
        ' Otra Calle Falsa',
        '345',
        '',
        '',
        '1234',
        @resultado);
SELECT @resultado;

-- -----------------------------------------------------
-- Inserts de Producto
-- -----------------------------------------------------
SET @resultado = 0;
CALL insertar_producto(
        '12345678',
        'Televisor LED 40\"',
        '2030-01-01',
        500.00,
        10,
        1,
        @resultado
     );
SELECT @resultado;

SET @resultado = 0;
CALL insertar_producto(
        '23456789',
        'Pan Lactal Bimbo',
        '2024-07-01',
        10.00,
        10,
        1,
        @resultado
     );
SELECT @resultado;

-- -----------------------------------------------------
-- Update de precios
-- -----------------------------------------------------
UPDATE producto
SET precio = 1000.00
WHERE codigo_unico = '12345678';

SELECT * FROM producto WHERE codigo_unico = '12345678';

UPDATE producto
SET precio = 100.00
WHERE codigo_unico = '23456789';

SELECT * FROM producto WHERE codigo_unico = '23456789';

-- -----------------------------------------------------
-- Eliminar producto
-- -----------------------------------------------------
SELECT * FROM producto WHERE is_active = TRUE;

UPDATE producto
SET is_active = FALSE
WHERE codigo_unico = '23456789';

SELECT * FROM producto WHERE is_active = TRUE;

-- -----------------------------------------------------
-- MODIFICAR DOMICILIO
-- -----------------------------------------------------
/*
    IN p_dni VARCHAR(20),
    IN p_calle VARCHAR(100),
    IN p_numero_calle VARCHAR(10),
    IN p_piso VARCHAR(10),
    IN p_departamento VARCHAR(10),
    IN p_codigo_postal VARCHAR(10),
    OUT p_nombre_completo VARCHAR(101),
    OUT p_direccion_nueva VARCHAR(151)
*/
SET @nombre_completo = '';
SET @direccion_nueva = '';
CALL modificar_domicilio(
        '11223344',
        'Calle Real',
        '555',
        '3',
        'B',
        '4567',
        @nombre_completo,
        @direccion_nueva
     );
SELECT @nombre_completo, @direccion_nueva;