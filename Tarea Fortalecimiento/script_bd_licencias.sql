-- =====================================================================
-- Sistema de emisión de licencias de conducir - Guatemala
-- 775 - Sistemas de Bases de Datos 2 - Tarea de Fortalecimiento Académico
-- Motor: MySQL 8.0 (compatible con MySQL Workbench)
-- Modelo normalizado hasta 3FN
-- =====================================================================

DROP DATABASE IF EXISTS licencias_guatemala;
CREATE DATABASE licencias_guatemala CHARACTER SET utf8mb4;
USE licencias_guatemala;

-- ---------------------------------------------------------------------
-- Catálogo: tipos de licencia (A, B, C, M)
-- ---------------------------------------------------------------------
CREATE TABLE tipo_licencia (
    id_tipo_licencia INT AUTO_INCREMENT PRIMARY KEY,
    codigo           CHAR(1)      NOT NULL,
    descripcion      VARCHAR(100) NOT NULL,
    CONSTRAINT uq_tipo_licencia_codigo UNIQUE (codigo)
);

-- ---------------------------------------------------------------------
-- Catálogo: tipos de examen (Teórico, Práctico, Vista)
-- ---------------------------------------------------------------------
CREATE TABLE tipo_examen (
    id_tipo_examen INT AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(50) NOT NULL,
    CONSTRAINT uq_tipo_examen_nombre UNIQUE (nombre)
);

-- ---------------------------------------------------------------------
-- Catálogo: tarifas de renovación según años renovados (1 a 5)
-- ---------------------------------------------------------------------
CREATE TABLE tarifa_renovacion (
    anios INT PRIMARY KEY,
    monto DECIMAL(8,2) NOT NULL,
    CONSTRAINT chk_anios_rango CHECK (anios BETWEEN 1 AND 5)
);

-- ---------------------------------------------------------------------
-- Persona (titular de la licencia)
-- ---------------------------------------------------------------------
CREATE TABLE persona (
    id_persona       INT AUTO_INCREMENT PRIMARY KEY,
    primer_nombre    VARCHAR(50)  NOT NULL,
    segundo_nombre   VARCHAR(50),
    primer_apellido  VARCHAR(50)  NOT NULL,
    segundo_apellido VARCHAR(50),
    fecha_nacimiento DATE         NOT NULL,
    dpi              CHAR(13)     NOT NULL,
    direccion        VARCHAR(150),
    telefono         VARCHAR(20),
    CONSTRAINT uq_persona_dpi UNIQUE (dpi)
);

-- ---------------------------------------------------------------------
-- Licencia
-- ---------------------------------------------------------------------
CREATE TABLE licencia (
    id_licencia       INT AUTO_INCREMENT PRIMARY KEY,
    id_persona        INT NOT NULL,
    id_tipo_licencia  INT NOT NULL,
    fecha_emision     DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado            ENUM('VIGENTE','VENCIDA','SUSPENDIDA') NOT NULL DEFAULT 'VIGENTE',
    CONSTRAINT fk_licencia_persona FOREIGN KEY (id_persona)
        REFERENCES persona (id_persona),
    CONSTRAINT fk_licencia_tipo FOREIGN KEY (id_tipo_licencia)
        REFERENCES tipo_licencia (id_tipo_licencia)
);

-- ---------------------------------------------------------------------
-- Exámenes realizados (teórico, práctico, vista) por licencia
-- ---------------------------------------------------------------------
CREATE TABLE examen_realizado (
    id_examen      INT AUTO_INCREMENT PRIMARY KEY,
    id_licencia    INT NOT NULL,
    id_tipo_examen INT NOT NULL,
    fecha_examen   DATE NOT NULL,
    resultado      ENUM('APROBADO','REPROBADO') NOT NULL,
    calificacion   DECIMAL(5,2),
    CONSTRAINT fk_examen_licencia FOREIGN KEY (id_licencia)
        REFERENCES licencia (id_licencia),
    CONSTRAINT fk_examen_tipo FOREIGN KEY (id_tipo_examen)
        REFERENCES tipo_examen (id_tipo_examen)
);

-- ---------------------------------------------------------------------
-- Autorización de padre/tutor (obligatoria si el titular es menor de edad)
-- ---------------------------------------------------------------------
CREATE TABLE autorizacion_menor (
    id_autorizacion    INT AUTO_INCREMENT PRIMARY KEY,
    id_licencia        INT NOT NULL,
    nombre_padre_tutor VARCHAR(100) NOT NULL,
    dpi_padre_tutor    CHAR(13) NOT NULL,
    parentesco         VARCHAR(30) NOT NULL,
    fecha_autorizacion DATE NOT NULL,
    CONSTRAINT fk_autorizacion_licencia FOREIGN KEY (id_licencia)
        REFERENCES licencia (id_licencia),
    CONSTRAINT uq_autorizacion_licencia UNIQUE (id_licencia)
);

-- ---------------------------------------------------------------------
-- Renovación de licencia (1 a 5 años; vencimiento cae en el cumpleaños)
-- ---------------------------------------------------------------------
CREATE TABLE renovacion (
    id_renovacion              INT AUTO_INCREMENT PRIMARY KEY,
    id_licencia                INT NOT NULL,
    anios_renovados            INT NOT NULL,
    fecha_renovacion           DATE NOT NULL,
    fecha_vencimiento_anterior DATE NOT NULL,
    fecha_vencimiento_nueva    DATE NOT NULL,
    CONSTRAINT fk_renovacion_licencia FOREIGN KEY (id_licencia)
        REFERENCES licencia (id_licencia),
    CONSTRAINT fk_renovacion_tarifa FOREIGN KEY (anios_renovados)
        REFERENCES tarifa_renovacion (anios)
);

-- ---------------------------------------------------------------------
-- Pago asociado a una renovación
-- ---------------------------------------------------------------------
CREATE TABLE pago (
    id_pago      INT AUTO_INCREMENT PRIMARY KEY,
    id_renovacion INT NOT NULL,
    monto        DECIMAL(8,2) NOT NULL,
    fecha_pago   DATE NOT NULL,
    metodo_pago  ENUM('EFECTIVO','TARJETA','TRANSFERENCIA') NOT NULL,
    CONSTRAINT fk_pago_renovacion FOREIGN KEY (id_renovacion)
        REFERENCES renovacion (id_renovacion),
    CONSTRAINT uq_pago_renovacion UNIQUE (id_renovacion)
);

-- =====================================================================
-- DATOS DE CATÁLOGO
-- =====================================================================
INSERT INTO tipo_licencia (codigo, descripcion) VALUES
('A', 'Motocicletas'),
('M', 'Motocicletas de baja cilindrada'),
('B', 'Vehículos livianos particulares'),
('C', 'Vehículos pesados y de transporte');

INSERT INTO tipo_examen (nombre) VALUES
('Teorico'), ('Practico'), ('Vista');

INSERT INTO tarifa_renovacion (anios, monto) VALUES
(1, 100.00), (2, 190.00), (3, 270.00), (4, 340.00), (5, 400.00);

-- =====================================================================
-- DATOS DE EJEMPLO
-- =====================================================================
INSERT INTO persona (primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, fecha_nacimiento, dpi, direccion, telefono) VALUES
('Joshua', NULL, 'Vasquez', 'Ramirez', '2005-07-15', '1234567890101', 'Zona 1, Guatemala', '55551111'),
('Ana', 'Lucia', 'Perez', 'Gomez', '1990-03-22', '2234567890101', 'Zona 10, Guatemala', '55552222'),
('Carlos', NULL, 'Lopez', 'Diaz', '1985-11-05', '3234567890101', 'Mixco', '55553333');

INSERT INTO licencia (id_persona, id_tipo_licencia, fecha_emision, fecha_vencimiento, estado) VALUES
(1, 2, '2023-07-15', '2024-07-15', 'VENCIDA'),
(2, 3, '2020-03-22', '2025-03-22', 'VIGENTE'),
(3, 4, '2019-11-05', '2024-11-05', 'VIGENTE');

INSERT INTO examen_realizado (id_licencia, id_tipo_examen, fecha_examen, resultado, calificacion) VALUES
(1, 1, '2023-07-01', 'APROBADO', 85.00),
(1, 2, '2023-07-05', 'APROBADO', 90.00),
(1, 3, '2023-07-10', 'APROBADO', 100.00),
(2, 1, '2020-03-10', 'APROBADO', 78.00),
(2, 2, '2020-03-15', 'APROBADO', 88.00),
(2, 3, '2020-03-20', 'APROBADO', 100.00);

INSERT INTO autorizacion_menor (id_licencia, nombre_padre_tutor, dpi_padre_tutor, parentesco, fecha_autorizacion) VALUES
(1, 'Mario Vasquez', '9998887776665', 'Padre', '2023-07-01');

INSERT INTO renovacion (id_licencia, anios_renovados, fecha_renovacion, fecha_vencimiento_anterior, fecha_vencimiento_nueva) VALUES
(2, 5, '2025-02-20', '2025-03-22', '2030-03-22');

INSERT INTO pago (id_renovacion, monto, fecha_pago, metodo_pago) VALUES
(1, 400.00, '2025-02-20', 'TARJETA');
