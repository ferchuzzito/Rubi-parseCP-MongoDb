# Proyecto: Procesamiento de Códigos Postales con Ruby y MongoDB

Este proyecto procesa un archivo de texto con información de códigos postales y los organiza en una base de datos MongoDB. Los datos se estructuran en colecciones separadas para **estados**, **municipios**, **colonias** y **códigos postales**, siguiendo principios de normalización para evitar redundancia y facilitar consultas.

## Características

- **Procesamiento de datos**: Convierte un archivo de texto en formato ISO-8859-15 a UTF-8 y elimina la primera línea.
- **Inserción en MongoDB**: Los datos se dividen en las siguientes colecciones:
  - `estados`: Contiene información de los estados.
  - `municipios`: Contiene información de los municipios, relacionados con los estados.
  - `colonias`: Contiene información de las colonias, relacionadas con los municipios.
  - `cp`: Contiene información de los códigos postales, relacionados con las colonias, municipios y estados.
- **Evita duplicados**: Utiliza hashes en memoria para evitar insertar datos duplicados en las colecciones.
- **Mensajes de progreso**: Muestra el progreso del procesamiento de las filas del archivo.

## Requisitos

- **Ruby**: Versión 3.1 o superior.
- **MongoDB**: Base de datos MongoDB en ejecución.
- **Docker** (opcional): Para ejecutar el proyecto en contenedores.
- **Dependencias de Ruby**:
  - `mongo`
  - `csv`
  - `pp`

## Instalación

1. Clona este repositorio:
   ```bash
   git clone https://github.com/tu-usuario/ruby_mongo_cp.git
   cd ruby_mongo_cp
   ```
2. Instala las dependencias de Ruby:
   ```bash
   gem install mongo csv pp
   ```
3. Asegúrate de que MongoDB esté en ejecución. Si usas Docker, puedes iniciar un contenedor de MongoDB:
   ```bash
   docker run -d --name mongoRuby -p 27017:27017 mongo:latest
   ```
4. Coloca el archivo de entrada `CPdescarga.txt` en el directorio raíz del proyecto.

## Uso

1. Ejecuta el script principal:
   ```bash
   ruby parse_cp.rb
   ```
2. El script procesará el archivo `CPdescarga.txt`, limpiará los datos y los insertará en MongoDB.

## Estructura de las colecciones

### `estados`
Contiene información de los estados.

Ejemplo:
```json
{
  "_id": 1,
  "nombre": "Ciudad de México"
}
```

### `municipios`
Contiene información de los municipios, relacionados con los estados.

Ejemplo:
```json
{
  "_id": "1-001",
  "nombre": "Álvaro Obregón",
  "estado_id": 1
}
```

### `colonias`
Contiene información de las colonias, relacionadas con los municipios.

Ejemplo:
```json
{
  "_id": "01000-001",
  "nombre": "San Ángel",
  "municipio_id": "1-001",
  "tipo": "urbano",
  "zona": "metropolitana"
}
```

### `cp`
Contiene información de los códigos postales, relacionados con las colonias, municipios y estados.

Ejemplo:
```json
{
  "_id": "01000",
  "estado_id": 1,
  "municipio_id": "1-001",
  "colonias": ["01000-001", "01000-002"]
}
```

## Personalización

- Si necesitas cambiar el archivo de entrada, actualiza la variable `input_file` en el script `parse_cp.rb`.
- Si MongoDB está en un host o puerto diferente, actualiza la URI de conexión en el script:
  ```ruby
  client = Mongo::Client.new('mongodb://<host>:<puerto>/codigos_postales')
  ```

## Ejecución con Docker Compose

Este proyecto incluye un archivo `docker-compose.yml` para ejecutar tanto la aplicación como MongoDB en contenedores.

1. Construye y ejecuta los servicios:
   ```bash
   docker-compose up --build
   ```
2. El script se ejecutará automáticamente y procesará los datos.
3. Para detener los servicios:
   ```bash
   docker-compose down
   ```

## Índices

Para optimizar las consultas, se crean los siguientes índices en las colecciones:

- **Códigos Postales (`cp`)**:
  - Índice en `_id` (código postal).
  - Índice en `estado_id` (referencia al estado).
  - Índice en `municipio_id` (referencia al municipio).

- **Colonias (`colonias`)**:
  - Índice en `tipo` (tipo de colonia).
  - Índice en `zona` (zona de la colonia).

## Consultas de Agregación

### Tipos de Zonas
```javascript
db.colonias.aggregate([
  { $project: { zona: 1 } },
  { $group: { _id: "$zona" } }
])
```
### Tipos de Colonias
```javascript
db.colonias.aggregate([
  { $project: { tipo: 1 } },
  { $group: { _id: "$tipo" } }
])
```


## Contribuciones

¡Las contribuciones son bienvenidas! Si encuentras un problema o tienes una mejora, abre un *issue* o envía un *pull request*.

## Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.