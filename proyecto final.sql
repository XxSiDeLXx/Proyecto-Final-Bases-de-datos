-- Creación de la base de datos 
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Proyecto_final')
BEGIN
    CREATE DATABASE Proyecto_final;
END
GO
USE Proyecto_final;
GO


-- 1. LIMPIEZA TOTAL (DROPS)


-- Tablas (Dependientes)
IF OBJECT_ID('dbo.Usuarios', 'U') IS NOT NULL DROP TABLE dbo.Usuarios;
IF OBJECT_ID('dbo.Auditoria', 'U') IS NOT NULL DROP TABLE dbo.Auditoria;
IF OBJECT_ID('dbo.Auditoria_Inscripciones', 'U') IS NOT NULL DROP TABLE dbo.Auditoria_Inscripciones;
IF OBJECT_ID('dbo.Auditoria_Cursos', 'U') IS NOT NULL DROP TABLE dbo.Auditoria_Cursos; 
IF OBJECT_ID('dbo.Auditoria_Instructores', 'U') IS NOT NULL DROP TABLE dbo.Auditoria_Instructores; 
IF OBJECT_ID('dbo.Detalle_Inscripciones', 'U') IS NOT NULL DROP TABLE dbo.Detalle_Inscripciones; 
IF OBJECT_ID('dbo.Inscripciones', 'U') IS NOT NULL DROP TABLE dbo.Inscripciones;
IF OBJECT_ID('dbo.Cupos', 'U') IS NOT NULL DROP TABLE dbo.Cupos;

-- Tablas  (Maestras)
IF OBJECT_ID('dbo.Alumnos', 'U') IS NOT NULL DROP TABLE dbo.Alumnos;
IF OBJECT_ID('dbo.Cursos', 'U') IS NOT NULL DROP TABLE dbo.Cursos;
IF OBJECT_ID('dbo.Instructores', 'U') IS NOT NULL DROP TABLE dbo.Instructores;

-- Procedures
IF OBJECT_ID('sp_RegistrarInscripcionCompleta', 'P') IS NOT NULL DROP PROCEDURE sp_RegistrarInscripcionCompleta;
IF OBJECT_ID('sp_CancelarInscripcion', 'P') IS NOT NULL DROP PROCEDURE sp_CancelarInscripcion;
GO


-- 2. CREACIÓN DE TABLAS


CREATE TABLE Alumnos (
    alumno_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo VARCHAR (100),
    email VARCHAR (100),
    telefono VARCHAR (100),
    direccion VARCHAR (100),
    tipo_documento VARCHAR (20),
    numero_documento VARCHAR (20),
    fecha_registro DATE
);
GO

CREATE TABLE Cursos (
    curso_id INT IDENTITY(100,1) PRIMARY KEY,
    nombre_curso VARCHAR(100),
    nivel VARCHAR(30),
    duracion_semanas INT,
    costo DECIMAL(10, 2),
    estado_curso VARCHAR(20) DEFAULT 'Activo',
    fecha_inicio DATE,
    fecha_fin DATE
);
GO

CREATE TABLE Instructores (
    instructor_id INT IDENTITY(200,1) PRIMARY KEY,
    nombre_completo VARCHAR (100),
    especialidad VARCHAR(50),
    usuario VARCHAR(50),
    contrasena VARCHAR(100),
    fecha_ingreso DATE,
    estado VARCHAR(20) DEFAULT 'Activo'
);
GO

-- TABLA DE USUARIOS (LOGIN)
CREATE TABLE Usuarios (
    usuario_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL, 
    rol VARCHAR(20) NOT NULL, 
    alumno_id INT NULL, 
    FOREIGN KEY (alumno_id) REFERENCES Alumnos(alumno_id)
);
GO

CREATE TABLE Cupos (
    cupo_id INT IDENTITY(1,1) PRIMARY KEY,
    curso_id INT NOT NULL UNIQUE,        
    cupos_maximos INT NOT NULL,
    cupos_disponibles INT NOT NULL,      
    FOREIGN KEY (curso_id) REFERENCES Cursos(curso_id)
);
GO

CREATE TABLE Inscripciones (
    inscripcion_id INT IDENTITY(1,1) PRIMARY KEY,
    alumno_id INT,
    curso_id INT,
    instructor_id INT,
    fecha_inscripcion DATE,
    metodo_pago VARCHAR(50),
    total_pago DECIMAL (10,2),
    estado_inscripcion VARCHAR (50) DEFAULT 'Activa',
    comprobante_pago VARCHAR(255) NULL,

    FOREIGN KEY (alumno_id) REFERENCES Alumnos(alumno_id),
    FOREIGN KEY (curso_id) REFERENCES Cursos(curso_id),
    FOREIGN KEY(instructor_id) REFERENCES Instructores(instructor_id)
);
GO

-- TABLAS DE AUDITORIA (Resumidas para brevedad, funcionan igual)
CREATE TABLE Auditoria_Inscripciones (auditoria_ins_id INT IDENTITY(1,1) PRIMARY KEY, inscripcion_id INT, accion VARCHAR(20), estado_anterior VARCHAR(50), estado_nuevo VARCHAR(50), usuario VARCHAR(50), fecha_evento DATETIME DEFAULT GETDATE());
CREATE TABLE Auditoria_Cursos (aud_curso_id INT IDENTITY(1,1) PRIMARY KEY, curso_id INT, accion VARCHAR(20), costo_anterior DECIMAL(10,2), costo_nuevo DECIMAL(10,2), usuario VARCHAR(50), fecha_evento DATETIME DEFAULT GETDATE());
CREATE TABLE Auditoria_Instructores (aud_inst_id INT IDENTITY(1,1) PRIMARY KEY, instructor_id INT, accion VARCHAR(20), especialidad_anterior VARCHAR(50), especialidad_nueva VARCHAR(50), usuario VARCHAR(50), fecha_evento DATETIME DEFAULT GETDATE());
CREATE TABLE Auditoria (auditoria_id INT IDENTITY(1,1) PRIMARY KEY, tabla_afectada VARCHAR(50), accion VARCHAR(50), usuario VARCHAR(50), descripcion VARCHAR(MAX), fecha_error DATETIME DEFAULT GETDATE());
GO

-- INDICES
CREATE INDEX IX_Alumnos_Email ON Alumnos(email);
CREATE INDEX IX_Cursos_Nombre ON Cursos(nombre_curso);
GO

-- 3. TRIGGERS

CREATE TRIGGER trg_ValidarYRegistrarInscripcion ON Inscripciones INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON; 
    IF EXISTS (SELECT i.curso_id FROM inserted i INNER JOIN Cupos c ON i.curso_id = c.curso_id WHERE c.cupos_disponibles < (SELECT COUNT(*) FROM inserted WHERE curso_id = i.curso_id))
    BEGIN RAISERROR ('Se excedieron los cupos', 16, 1); RETURN; END

    INSERT INTO Inscripciones (alumno_id, curso_id, instructor_id, fecha_inscripcion, metodo_pago, total_pago, estado_inscripcion, comprobante_pago)
    SELECT alumno_id, curso_id, instructor_id, fecha_inscripcion, metodo_pago, total_pago, estado_inscripcion, comprobante_pago FROM inserted; 

    UPDATE Cupos SET cupos_disponibles = Cupos.cupos_disponibles - Conteo.total_nuevos
    FROM Cupos INNER JOIN (SELECT curso_id, COUNT(*) AS total_nuevos FROM inserted GROUP BY curso_id) AS Conteo ON Cupos.curso_id = Conteo.curso_id;
END;
GO
-- 4. INSERCIÓN DE DATOS

-- Insertamos Alumnos 
INSERT INTO Alumnos (nombre_completo, email, telefono, direccion, tipo_documento, numero_documento, fecha_registro) VALUES
('Fabián Valencia', 'fabian.valencia@musica.com', '5512345678', 'Jaca 914', 'INE', 'FABC0123456789', GETDATE()),
('Ronaldo Rodriguez', 'ronaldo.rodriguez@musica.com', '5510090906', 'Av. Central', 'Pasaporte', 'PASP11940', GETDATE()),
('Elva Lazo', 'elva.lazo@musica.com', '5577889900', 'Calle Tulipán 45', 'INE', 'ELAZO9988776654', GETDATE()),
('Alan Brito', 'alanbrito@musica.com', '8852146752', 'Av Torres 11', 'INE', '0101029823', GETDATE()),
('Guadalupe Reyes','guadalupe.reyez@musica.com','123103134','Jacaranda 14','INE','GDLP1231HNC101',GETDATE());
GO

--  Insertamos USUARIOS 
-- Esto crea al ADMIN 
INSERT INTO Usuarios (username, password_hash, rol, alumno_id)
VALUES 
('admin', '123456', 'admin', NULL),
('fabian', 'praderas3', 'admin', NULL);
GO

-- 3. Maestros
INSERT INTO Instructores (nombre_completo, especialidad, usuario, contrasena) VALUES
('Reynaldo Nacarrete', 'Guitarra', 'reynaldo', '030398'),
('Susana Oria', 'Teclado', 'susan', '123456'),
('Ana Lisa', 'Bateria', 'analisa', '101099');
GO
--Nivel de curso y precio
INSERT INTO Cursos (nombre_curso, nivel, duracion_semanas, costo) VALUES
('Curso Básico', 'Básico', 8, 1200.00),
('Curso Intermedio', 'Intermedio', 4, 1800.00), 
('Curso Avanzado', 'Avanzado', 6, 2400.00);
GO

INSERT INTO Cupos (curso_id, cupos_maximos, cupos_disponibles) VALUES (100, 5, 5), (101, 5, 5), (102, 5, 5);
GO

-- 5. PROCEDIMIENTOS 

CREATE PROCEDURE sp_RegistrarInscripcionCompleta
    @alumno_id INT, @curso_id INT, @instructor_id INT, @metodo_pago VARCHAR(50), 
    @costo DECIMAL(10,2), @estado_inicial VARCHAR(50), @ruta_comprobante VARCHAR(255) = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO Inscripciones (alumno_id, curso_id, instructor_id, fecha_inscripcion, metodo_pago, total_pago, estado_inscripcion, comprobante_pago)
        VALUES (@alumno_id, @curso_id, @instructor_id, GETDATE(), @metodo_pago, @costo, @estado_inicial, @ruta_comprobante);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

--Generar correo institucional
IF OBJECT_ID('sp_RegistrarAlumnoConEmailAuto', 'P') IS NOT NULL DROP PROCEDURE sp_RegistrarAlumnoConEmailAuto;
GO

CREATE PROCEDURE sp_RegistrarAlumnoConEmailAuto
    @nombre_completo VARCHAR(100),
    @telefono VARCHAR(100),
    @direccion VARCHAR(100),
    @tipo_doc VARCHAR(20),
    @num_doc VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NombreLimpio VARCHAR(100);
    DECLARE @PrimerNombre VARCHAR(50);
    DECLARE @PrimerApellido VARCHAR(50);
    DECLARE @BaseEmail VARCHAR(100);
    DECLARE @EmailFinal VARCHAR(100);
    DECLARE @Contador INT = 1;
    DECLARE @EspacioIndex INT;


    --Eliminar usuario
    IF OBJECT_ID('sp_EliminarAlumnoCompleto', 'P') IS NOT NULL DROP PROCEDURE sp_EliminarAlumnoCompleto;
GO

CREATE PROCEDURE sp_EliminarAlumnoCompleto
    @alumno_id INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Borrar usuario de login asociado
        DELETE FROM Usuarios WHERE alumno_id = @alumno_id;

        -- 2. Borrar sus inscripciones 
        DELETE FROM Inscripciones WHERE alumno_id = @alumno_id;

        -- 3. Finalmente, borrar al alumno
        DELETE FROM Alumnos WHERE alumno_id = @alumno_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
    

    -- 3. Separar Primer Nombre y Primer Apellido
    SET @EspacioIndex = CHARINDEX(' ', @NombreLimpio);

    IF @EspacioIndex > 0 
    BEGIN
        SET @PrimerNombre = SUBSTRING(@NombreLimpio, 1, @EspacioIndex - 1);
        -- Buscamos donde termina el apellido (o tomamos el resto si no hay más espacios)
        DECLARE @RestoNombre VARCHAR(100) = SUBSTRING(@NombreLimpio, @EspacioIndex + 1, LEN(@NombreLimpio));
        DECLARE @EspacioIndex2 INT = CHARINDEX(' ', @RestoNombre);
        
        IF @EspacioIndex2 > 0
            SET @PrimerApellido = SUBSTRING(@RestoNombre, 1, @EspacioIndex2 - 1);
        ELSE
            SET @PrimerApellido = @RestoNombre;
    END
    ELSE
    BEGIN
        -- Si solo puso un nombre sin apellidos
        SET @PrimerNombre = @NombreLimpio;
        SET @PrimerApellido = 'Macho';
    END

    -- 4. Construir la base (nombre.apellido@musica.com)
    SET @BaseEmail = @PrimerNombre + '.' + @PrimerApellido + '@musica.com';
    SET @EmailFinal = @BaseEmail;

    -- 5. Bucle para verificar duplicados
    WHILE EXISTS (SELECT 1 FROM Alumnos WHERE email = @EmailFinal)
    BEGIN
        SET @Contador = @Contador + 1;
        -- Genera: juan.perez2@musica.com
        SET @EmailFinal = @PrimerNombre + '.' + @PrimerApellido + CAST(@Contador AS VARCHAR) + '@musica.com';
    END

    -- 6. Insertar el registro
    INSERT INTO Alumnos (nombre_completo, email, telefono, direccion, tipo_documento, numero_documento, fecha_registro)
    VALUES (@nombre_completo, @EmailFinal, @telefono, @direccion, @tipo_doc, @num_doc, GETDATE());

    -- 7. Devolver el email generado para mostrarlo en la web
    SELECT @EmailFinal AS EmailGenerado;
END;
GO

 

-- 1. REQUISITO: RANKING (Curso + Profesor + Instrumento)
-- Muestra la combinación más popular de Clase y Maestro
PRINT '>>> 1. REPORTE DE RANKING DE POPULARIDAD (DETALLADO) <<<';

SELECT 
    C.nombre_curso AS Curso,
    Inst.nombre_completo AS Profesor,
    Inst.especialidad AS Instrumento,
    COUNT(I.inscripcion_id) AS Total_Inscritos,
    DENSE_RANK() OVER (ORDER BY COUNT(I.inscripcion_id) DESC) AS Ranking
FROM Cursos C
INNER JOIN Inscripciones I ON C.curso_id = I.curso_id
INNER JOIN Instructores Inst ON I.instructor_id = Inst.instructor_id
GROUP BY C.nombre_curso, Inst.nombre_completo, Inst.especialidad;
GO
-- 2.  CASE (Clasificación de Alumnos)
-- Clasifica a los alumnos como Premium o Básico según su inversión

PRINT '>>> 2. CLASIFICACIÓN DE ALUMNOS (CASE) <<<';

SELECT DISTINCT 
    A.nombre_completo,
    SUM(I.total_pago) OVER(PARTITION BY A.alumno_id) AS Total_Invertido,
    CASE 
        WHEN SUM(I.total_pago) OVER(PARTITION BY A.alumno_id) >= 3000 THEN 'Alumno Premium'
        WHEN SUM(I.total_pago) OVER(PARTITION BY A.alumno_id) BETWEEN 2000 AND 2999 THEN 'Alumno Estándar'
        ELSE 'Alumno Básico'
    END AS Categoria_Cliente
FROM Alumnos A
JOIN Inscripciones I ON A.alumno_id = I.alumno_id
ORDER BY Total_Invertido DESC;
GO

-- 3. INNER JOIN
-- Une las 4 tablas principales para ver el detalle total

SELECT 
    A.alumno_id,
    A.nombre_completo AS Alumno,
    
    -- Usamos ISNULL para que se vea mejor si no tiene curso
    ISNULL(C.nombre_curso, ' Sin Inscripción') AS Curso,
    ISNULL(INST.nombre_completo, 'No valido') AS Instructor,
    
    I.metodo_pago,
    I.estado_inscripcion,
    I.fecha_inscripcion
FROM Alumnos A
LEFT JOIN Inscripciones I ON A.alumno_id = I.alumno_id
LEFT JOIN Cursos C ON I.curso_id = C.curso_id
LEFT JOIN Instructores INST ON I.instructor_id = INST.instructor_id
ORDER BY A.nombre_completo;
GO


-- 4. :SUBCONSULTAS (Cursos con Demanda Alta) 
-- Encuentra cursos que tienen más alumnos que el promedio general


SELECT 
    C.nombre_curso,
    COUNT(I.inscripcion_id) AS Inscritos
FROM Cursos C
JOIN Inscripciones I ON C.curso_id = I.curso_id
GROUP BY C.nombre_curso
HAVING COUNT(I.inscripcion_id) >= (
    -- Subconsulta: Calcula el promedio de alumnos por curso
    SELECT AVG(Conteo) 
    FROM (SELECT COUNT(*) as Conteo FROM Inscripciones GROUP BY curso_id) as Promedios
);
GO

-- 5 PIVOT (Inscripciones por Mes)
-- Muestra cuántos alumnos se inscribieron en cada mes

SELECT * FROM (
    SELECT 
        C.nombre_curso,
        DATENAME(MONTH, I.fecha_inscripcion) AS Mes_Inscripcion
    FROM Inscripciones I
    JOIN Cursos C ON I.curso_id = C.curso_id
) AS Fuente
PIVOT (
    COUNT(Mes_Inscripcion)
    FOR Mes_Inscripcion IN ([Noviembre], [Diciembre], [Enero], [Febrero]) 
) AS TablaPivote;
GO


--Manualmente eliminar usuario
-- 1. Borrar usuario
DELETE FROM Usuarios WHERE alumno_id = 1;

-- 2. Borrar inscripciones
DELETE FROM Inscripciones WHERE alumno_id = 1;

-- 3. Borrar alumno
DELETE FROM Alumnos WHERE alumno_id = 1;
GO

-- Verificación final
SELECT * FROM Alumnos;