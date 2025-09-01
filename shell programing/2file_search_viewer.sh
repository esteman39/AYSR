#!/bin/bash

# Script: file_search_viewer.sh
# Descripción: Búsqueda de archivos y palabras, visualización de contenido

# Función para limpiar pantalla
clear_screen() {
    clear
}

# Función para paginar salida
paginate_output() {
    if [ -t 1 ]; then
        less
    else
        cat
    fi
}

# Función 1: Buscar archivo o parte del nombre en directorio
search_files() {
    local directory="$1"
    local pattern="$2"
    
    echo "=== Buscando archivos con patrón: '$pattern' en '$directory' ==="
    echo
    
    local count=0
    local results=""
    
    # Buscar archivos recursivamente
    while IFS= read -r -d '' file; do
        count=$((count + 1))
        results="$results$count. $(realpath "$file")\n"
    done < <(find "$directory" -name "*$pattern*" -type f -print0 2>/dev/null)
    
    if [ $count -eq 0 ]; then
        echo "No se encontraron archivos que coincidan con el patrón."
    else
        echo "Archivos encontrados:"
        echo "===================="
        echo -e "$results"
        echo "===================="
        echo "Total de archivos encontrados: $count"
    fi
}

# Función 2: Buscar palabra en archivo
search_word_in_file() {
    local file="$1"
    local word="$2"
    
    echo "=== Buscando palabra: '$word' en archivo: '$file' ==="
    echo
    
    if [ ! -f "$file" ]; then
        echo "Error: El archivo '$file' no existe o no es un archivo regular."
        return 1
    fi
    
    local count=0
    local line_num=1
    
    echo "Líneas que contienen '$word':"
    echo "============================"
    
    while IFS= read -r line; do
        if [[ "$line" == *"$word"* ]]; then
            count=$((count + 1))
            echo "Línea $line_num: $line"
        fi
        line_num=$((line_num + 1))
    done < "$file"
    
    echo "============================"
    echo "Total de ocurrencias: $count"
}

# Función 3: Buscar archivos y luego palabras dentro de ellos
search_files_and_words() {
    local directory="$1"
    local file_pattern="$2"
    local word="$3"
    
    echo "=== Buscando palabra '$word' en archivos que contienen '$file_pattern' ==="
    echo "Directorio: $directory"
    echo
    
    local files_found=0
    local total_occurrences=0
    
    while IFS= read -r -d '' file; do
        files_found=$((files_found + 1))
        echo "--- Archivo: $(realpath "$file") ---"
        
        local count=0
        local line_num=1
        
        while IFS= read -r line; do
            if [[ "$line" == *"$word"* ]]; then
                count=$((count + 1))
                total_occurrences=$((total_occurrences + 1))
                echo "  Línea $line_num: $line"
            fi
            line_num=$((line_num + 1))
        done < "$file"
        
        echo "  Ocurrencias en este archivo: $count"
        echo
    done < <(find "$directory" -name "*$file_pattern*" -type f -print0 2>/dev/null)
    
    echo "================================"
    echo "Archivos procesados: $files_found"
    echo "Total de ocurrencias: $total_occurrences"
}

# Función 4: Contar líneas en archivo
count_lines() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "Error: El archivo '$file' no existe o no es un archivo regular."
        return 1
    fi
    
    local lines=$(wc -l < "$file")
    echo "=== Conteo de líneas ==="
    echo "Archivo: $(realpath "$file")"
    echo "Número total de líneas: $lines"
}

# Función 5: Mostrar primeras n líneas
show_first_lines() {
    local file="$1"
    local n="$2"
    
    if [ ! -f "$file" ]; then
        echo "Error: El archivo '$file' no existe o no es un archivo regular."
        return 1
    fi
    
    echo "=== Primeras $n líneas de: $(realpath "$file") ==="
    echo
    head -n "$n" "$file"
}

# Función 6: Mostrar últimas n líneas
show_last_lines() {
    local file="$1"
    local n="$2"
    
    if [ ! -f "$file" ]; then
        echo "Error: El archivo '$file' no existe o no es un archivo regular."
        return 1
    fi
    
    echo "=== Últimas $n líneas de: $(realpath "$file") ==="
    echo
    tail -n "$n" "$file"
}

# Función para mostrar menú
show_menu() {
    echo "========================================================"
    echo "         BÚSQUEDA Y VISUALIZACIÓN DE ARCHIVOS"
    echo "========================================================"
    echo "1. Buscar archivos por nombre en directorio"
    echo "2. Buscar palabra en archivo específico"
    echo "3. Buscar archivos y palabras dentro de ellos"
    echo "4. Contar líneas de un archivo"
    echo "5. Mostrar primeras n líneas de un archivo"
    echo "6. Mostrar últimas n líneas de un archivo"
    echo "0. Salir"
    echo "========================================================"
}

# Función para validar número
validate_number() {
    local input="$1"
    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Función principal
main() {
    local choice
    local directory
    local file
    local pattern
    local word
    local n
    
    while true; do
        clear_screen
        show_menu
        echo -n "Seleccione una opción: "
        read choice
        
        case "$choice" in
            1)
                clear_screen
                echo "=== BUSCAR ARCHIVOS POR NOMBRE ==="
                echo -n "Ingrese el directorio donde buscar: "
                read directory
                
                if [ ! -d "$directory" ]; then
                    echo "Error: El directorio '$directory' no existe."
                else
                    echo -n "Ingrese el patrón de búsqueda: "
                    read pattern
                    search_files "$directory" "$pattern" | paginate_output
                fi
                
                echo -n "Presione Enter para continuar..."
                read
                ;;
            2)
                clear_screen
                echo "=== BUSCAR PALABRA EN ARCHIVO ==="
                echo -n "Ingrese la ruta del archivo: "
                read file
                echo -n "Ingrese la palabra a buscar: "
                read word
                
                search_word_in_file "$file" "$word" | paginate_output
                
                echo -n "Presione Enter para continuar..."
                read
                ;;
            3)
                clear_screen
                echo "=== BUSCAR ARCHIVOS Y PALABRAS ==="
                echo -n "Ingrese el directorio donde buscar: "
                read directory
                
                if [ ! -d "$directory" ]; then
                    echo "Error: El directorio '$directory' no existe."
                else
                    echo -n "Ingrese el patrón para nombres de archivo: "
                    read pattern
                    echo -n "Ingrese la palabra a buscar dentro de los archivos: "
                    read word
                    
                    search_files_and_words "$directory" "$pattern" "$word" | paginate_output
                fi
                
                echo -n "Presione Enter para continuar..."
                read
                ;;
            4)
                clear_screen
                echo "=== CONTAR LÍNEAS ==="
                echo -n "Ingrese la ruta del archivo: "
                read file
                
                count_lines "$file"
                
                echo -n "Presione Enter para continuar..."
                read
                ;;
            5)
                clear_screen
                echo "=== MOSTRAR PRIMERAS LÍNEAS ==="
                echo -n "Ingrese la ruta del archivo: "
                read file
                echo -n "Ingrese el número de líneas a mostrar: "
                read n
                
                if validate_number "$n"; then
                    show_first_lines "$file" "$n" | paginate_output
                else
                    echo "Error: Debe ingresar un número válido mayor que 0."
                fi
                
                echo -n "Presione Enter para continuar..."
                read
                ;;
            6)
                clear_screen
                echo "=== MOSTRAR ÚLTIMAS LÍNEAS ==="
                echo -n "Ingrese la ruta del archivo: "
                read file
                echo -n "Ingrese el número de líneas a mostrar: "
                read n
                
                if validate_number "$n"; then
                    show_last_lines "$file" "$n" | paginate_output
                else
                    echo "Error: Debe ingresar un número válido mayor que 0."
                fi
                
                echo -n "Presione Enter para continuar..."
                read
                ;;
            0)
                echo "¡Hasta luego!"
                exit 0
                ;;
            *)
                echo "Opción inválida. Presione Enter para continuar..."
                read
                ;;
        esac
    done
}

# Ejecutar programa principal
main "$@"