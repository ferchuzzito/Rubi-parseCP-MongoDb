#!/usr/bin/env ruby
#encoding: utf-8

require 'csv'
require 'pp'
require 'mongo'

begin
  # Conexión a MongoDB
  client = Mongo::Client.new('mongodb://mongoRuby:27017/codigos_postales')
rescue Mongo::Error => e
  puts "Error al conectar a MongoDB: #{e.message}"
  exit(1)
end

# Acceso a las colecciones
db = client.database
estados_collection = client[:estados]
municipios_collection = client[:municipios]
colonias_collection = client[:colonias]
cp_collection = client[:cp]

# Crear índices en las colecciones para optimizar consultas
cp_collection.indexes.create_one({ _id: 1 }) # Índice para el campo _id (código postal)
cp_collection.indexes.create_one({ estado_id: 1 }) # Índice para el campo estado_id
cp_collection.indexes.create_one({ municipio_id: 1 }) # Índice para el campo municipio_id
colonias_collection.indexes.create_one({ tipo: 1 }) # Índice para el campo tipo
colonias_collection.indexes.create_one({ zona: 1 }) # Índice para el campo zona

# Hashes para evitar duplicados
estados = {}
municipios = {}
colonias = {}
codigos_postales = {}

input_file = "CPdescarga.txt"
output_file = "CPdescarga-utf8.txt"

unless File.exist?(input_file)
  puts "El archivo #{input_file} no existe. Por favor, verifica."
  exit(1)
end

# Limpiamos el archivo de ingesta
`iconv -f ISO-8859-15 -t UTF-8 #{input_file} | sed '1d' > #{output_file}`

total_rows = `wc -l #{output_file}`.split.first.to_i - 1
processed_rows = 0

CSV.foreach(output_file, headers: true, encoding: "UTF-8", col_sep: '|', quote_char: '|') do |row|
  processed_rows += 1
  puts "Procesando fila #{processed_rows} de #{total_rows}" if processed_rows % 1000 == 0

  # Validar datos esenciales
  if row['d_codigo'].nil? || row['id_asenta_cpcons'].nil? || row['c_estado'].nil?
    puts "Fila inválida: #{row.to_hash}"
    next
  end

  estado = row['c_estado'].to_i

  # Insertar estados
  unless estados.key?(estado)
    puts "Agregando estado #{row['d_estado']}: #{row['c_estado']}"
    estados[estado] = row['d_estado'].strip
    estados_collection.insert_one({ _id: estado, nombre: row['d_estado'] })
  end

  # Insertar municipios
  municipio_id = "#{estado}-#{row['c_mnpio']}"
  unless municipios.key?(municipio_id)
    puts "Agregando municipio #{row['D_mnpio']} al estado #{row['d_estado']}"
    municipios[municipio_id] = row['D_mnpio'].strip
    municipios_collection.insert_one({
      _id: municipio_id,
      nombre: row['D_mnpio'].strip,
      estado_id: estado
    })
  end

  # Insertar colonias
  colonia_id = "#{row['d_codigo']}-#{row['id_asenta_cpcons']}"
  unless colonias.key?(colonia_id)
    puts "Agregando colonia #{row['d_asenta']} al municipio #{row['D_mnpio']}"
    colonias[colonia_id] = row['d_asenta'].strip
    colonias_collection.insert_one({
      _id: colonia_id,
      nombre: row['d_asenta'].strip,
      municipio_id: municipio_id,
      tipo: row['d_tipo_asenta'].downcase.strip,
      zona: row['d_zona'].downcase.strip
    })
  end

  # Insertar códigos postales
  unless codigos_postales.key?(row['d_codigo'])
    puts "Agregando código postal #{row['d_codigo']}"
    codigos_postales[row['d_codigo']] = true
    cp_collection.insert_one({
      _id: row['d_codigo'],
      estado_id: estado,
      municipio_id: municipio_id,
      colonias: [colonia_id]
    })
  else
    # Agregar colonia al código postal existente
    cp_collection.update_one(
      { _id: row['d_codigo'] },
      { "$addToSet": { colonias: colonia_id } }
    )
  end
end

client.close
puts "Conexión a MongoDB cerrada."