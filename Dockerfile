# Usa una imagen base de Ruby
FROM ruby:3.1

# Instala las dependencias necesarias
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  git \
  && rm -rf /var/lib/apt/lists/*

# Crea y establece el directorio de trabajo
WORKDIR /usr/src/app

# Copia el archivo del script Ruby y el archivo de entrada (CSV) en el contenedor
COPY . .

# Instala las gemas necesarias (mongo y csv)
RUN gem install mongo csv pp

# Expone el puerto 27017 para la base de datos de MongoDB si se va a usar dentro de Docker (opcional)
EXPOSE 27017

# Comando por defecto para ejecutar el script Ruby
CMD ["ruby", "parse_cp.rb"]
