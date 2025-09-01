#!/bin/bash

# Script:ls_cmd.sh
# Descripción: Lista archivos con opciones de ordenamiento y filtrado
# Autor: [esteban muñoz]
# Fecha: $(2025-08-29)
# Función para limpiar pantalla
clear_screen() {
    clear
}

# Función para paginar salida
paginate_output() {
    if [ -t 1 ]; then  # Si la salida es a terminal
        less
    else
        cat
    fi
}

# Función para contar archivos por fecha
count_by_date() {
    local directory="$1"
    local subdirs="$2"
    local oldest="$3"
    
    echo "=== Archivos ordenados por fecha $([ "$oldest" = "true" ] && echo "(más antiguos primero)" || echo "(más recientes primero)") ==="
    echo
    
    if [ "$subdirs" = "true" ]; then
        find "$directory" -type f -exec stat -c "%Y %n" {} \; 2>/dev/null | \
        sort $([ "$oldest" = "true" ] && echo "-n" || echo "-nr") | \
        while read timestamp file; do
            date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" | tr '\n' ' '
            echo "$file"
        done | \
        awk '{
            date_time = $1 " " $2
            if (dates[date_time]) {
                dates[date_time]++
            } else {
                dates[date_time] = 1
                order[++count] = date_time
            }
            files[date_time] = files[date_time] $3 "\n"
        }
        END {
            for (i=1; i<=count; i++) {
                dt = order[i]
                printf "\n--- Fecha: %s (Total: %d archivos) ---\n", dt, dates[dt]
                printf "%s", files[dt]
            }
        }'
    else
        ls -la "$directory" 2>/dev/null | grep -v "^total" | tail -n +2 | \
        awk -v dir="$directory" -v oldest="$oldest" '
        {
            # Extraer información del archivo
            permissions = $1
            size = $5
            month = $6
            day = $7
            time_year = $8
            filename = ""
            for(i=9; i<=NF; i++) filename = filename $i " "
            filename = substr(filename, 1, length(filename)-1)
            
            date_key = month " " day " " time_year
            dates[date_key]++
            files[date_key] = files[date_key] permissions " " size " " date_key " " filename "\n"
        }
        END {
            n = asorti(dates, sorted_dates)
            if (oldest == "false") {
                # Invertir orden para más recientes primero
                for (i = 1; i <= n/2; i++) {
                    temp = sorted_dates[i]
                    sorted_dates[i] = sorted_dates[n-i+1]
                    sorted_dates[n-i+1] = temp
                }
            }
            
            for (i = 1; i <= n; i++) {
                dt = sorted_dates[i]
                printf "\n--- Fecha: %s (Total: %d archivos) ---\n", dt, dates[dt]
                printf "%s", files[dt]
            }
        }'
    fi
}

# Función para contar archivos por tamaño
count_by_size() {
    local directory="$1"
    local subdirs="$2"
    local largest_first="$3"
    
    echo "=== Archivos ordenados por tamaño $([ "$largest_first" = "true" ] && echo "(mayor a menor)" || echo "(menor a mayor)") ==="
    echo
    
    if [ "$subdirs" = "true" ]; then
        find "$directory" -type f -exec ls -la {} \; 2>/dev/null | \
        awk -v largest="$largest_first" '
        {
            size = $5
            filename = ""
            for(i=9; i<=NF; i++) filename = filename $i " "
            filename = substr(filename, 1, length(filename)-1)
            
            sizes[size]++
            files[size] = files[size] $0 "\n"
        }
        END {
            n = asorti(sizes, sorted_sizes, "@val_num_asc")
            if (largest == "true") {
                for (i = 1; i <= n/2; i++) {
                    temp = sorted_sizes[i]
                    sorted_sizes[i] = sorted_sizes[n-i+1]
                    sorted_sizes[n-i+1] = temp
                }
            }
            
            for (i = 1; i <= n; i++) {
                sz = sorted_sizes[i]
                printf "\n--- Tamaño: %s bytes (Total: %d archivos) ---\n", sz, sizes[sz]
                printf "%s", files[sz]
            }
        }'
    else
        ls -la "$directory" 2>/dev/null | grep -v "^total" | tail -n +2 | \
        awk -v largest="$largest_first" '
        {
            size = $5
            sizes[size]++
            files[size] = files[size] $0 "\n"
        }
        END {
            n = asorti(sizes, sorted_sizes, "@val_num_asc")
            if (largest == "true") {
                for (i = 1; i <= n/2; i++) {
                    temp = sorted_sizes[i]
                    sorted_sizes[i] = sorted_sizes[n-i+1]
                    sorted_sizes[n-i+1] = temp
                }
            }
            
            for (i = 1; i <= n; i++) {
                sz = sorted_sizes[i]
                printf "\n--- Tamaño: %s bytes (Total: %d archivos) ---\n", sz, sizes[sz]
                printf "%s", files[sz]
            }
        }'
    fi
}

# Función para contar archivos por tipo
count_by_type() {
    local directory="$1"
    local subdirs="$2"
    
    echo "=== Archivos agrupados por tipo ==="
    echo
    
    if [ "$subdirs" = "true" ]; then
        find "$directory" -exec ls -ld {} \; 2>/dev/null | \
        awk '
        {
            if (substr($1, 1, 1) == "d") {
                type = "Directory"
                directories++
                dir_files = dir_files $0 "\n"
            } else {
                type = "File"
                files++
                reg_files = reg_files $0 "\n"
            }
        }
        END {
            if (files > 0) {
                printf "\n--- Archivos regulares (Total: %d) ---\n", files
                printf "%s", reg_files
            }
            if (directories > 0) {
                printf "\n--- Directorios (Total: %d) ---\n", directories
                printf "%s", dir_files
            }
        }'
    else
        ls -la "$directory" 2>/dev/null | grep -v "^total" | tail -n +2 | \
        awk '
        {
            if (substr($1, 1, 1) == "d") {
                directories++
                dir_files = dir_files $0 "\n"
            } else {
                files++
                reg_files = reg_files $0 "\n"
            }
        }
        END {
            if (files > 0) {
                printf "\n--- Archivos regulares (Total: %d) ---\n", files
                printf "%s", reg_files
            }
            if (directories > 0) {
                printf "\n--- Directorios (Total: %d) ---\n", directories
                printf "%s", dir_files
            }
        }'
    fi
}

# Función para filtrar archivos
filter_files() {
    local directory="$1"
    local subdirs="$2"
    local filter_type="$3"
    local pattern="$4"
    
    echo "=== Archivos filtrados: $filter_type '$pattern' ==="
    echo
    
    if [ "$subdirs" = "true" ]; then
        case "$filter_type" in
            "starts_with")
                find "$directory" -name "$pattern*" -exec ls -la {} \; 2>/dev/null
                ;;
            "ends_with")
                find "$directory" -name "*$pattern" -exec ls -la {} \; 2>/dev/null
                ;;
            "contains")
                find "$directory" -name "*$pattern*" -exec ls -la {} \; 2>/dev/null
                ;;
        esac
    else
        case "$filter_type" in
            "starts_with")
                ls -la "$directory"/$pattern* 2>/dev/null
                ;;
            "ends_with")
                ls -la "$directory"/*$pattern 2>/dev/null
                ;;
            "contains")
                ls -la "$directory"/*$pattern* 2>/dev/null
                ;;
        esac
    fi
}

# Función para mostrar menú principal
show_menu() {
    echo "================================================"
    echo "           LISTADO AVANZADO DE ARCHIVOS"
    echo "================================================"
    echo "1. Ordenar por fecha (más recientes)"
    echo "2. Ordenar por fecha (más antiguos)"
    echo "3. Ordenar por tamaño (mayor a menor)"
    echo "4. Ordenar por tamaño (menor a mayor)"
    echo "5. Agrupar por tipo de archivo"
    echo "6. Filtrar: empieza con..."
    echo "7. Filtrar: termina con..."
    echo "8. Filtrar: contiene..."
    echo "9. Cambiar directorio"
    echo "0. Salir"
    echo "================================================"
}

# Función para preguntar si incluir subdirectorios
ask_subdirs() {
    echo -n "¿Incluir subdirectorios? (s/n): "
    read response
    case "$response" in
        [sS]|[sS][íi]) echo "true" ;;
        *) echo "false" ;;
    esac
}

# Función principal
main() {
    local directory
    local choice
    local include_subdirs
    local pattern
    
    # Solicitar directorio inicial
    echo -n "Ingrese el directorio a analizar (por defecto: directorio actual): "
    read directory
    
    if [ -z "$directory" ]; then
        directory="."
    fi
    
    # Verificar que el directorio existe
    if [ ! -d "$directory" ]; then
        echo "Error: El directorio '$directory' no existe."
        exit 1
    fi
    
    # Bucle principal del menú
    while true; do
        clear_screen
        echo "Directorio actual: $(realpath "$directory")"
        echo
        show_menu
        echo -n "Seleccione una opción: "
        read choice
        
        case "$choice" in
            1)
                clear_screen
                include_subdirs=$(ask_subdirs)
                count_by_date "$directory" "$include_subdirs" "false" | paginate_output
                echo -n "Presione Enter para continuar..."
                read
                ;;
            2)
                clear_screen
                include_subdirs=$(ask_subdirs)
                count_by_date "$directory" "$include_subdirs" "true" | paginate_output
                echo -n "Presione Enter para continuar..."
                read
                ;;
            3)
                clear_screen
                include_subdirs=$(ask_subdirs)
                count_by_size "$directory" "$include_subdirs" "true" | paginate_output
                echo -n "Presione Enter para continuar..."
                read
                ;;
            4)
                clear_screen
                include_subdirs=$(ask_subdirs)
                count_by_size "$directory" "$include_subdirs" "false" | paginate_output
                echo -n "Presione Enter para continuar..."
                read
                ;;
            5)
                clear_screen
                include_subdirs=$(ask_subdirs)
                count_by_type "$directory" "$include_subdirs" | paginate_output
                echo -n "Presione Enter para continuar..."
                read
                ;;
            6)
                clear_screen
                include_subdirs=$(ask_subdirs)
                echo -n "Ingrese el texto con el que debe empezar: "
                read pattern
                filter_files "$directory" "$include_subdirs" "starts_with" "$pattern" | paginate_output
                echo -n "Presione Enter para continuar..."
                read
                ;;
            7)
                clear_screen
                include_subdirs=$(ask_subdirs)
                echo -n "Ingrese el texto con el que debe terminar: "
                read pattern
                filter_files "$directory" "$include_subdirs" "ends_with" "$pattern" | paginate_output
                echo -n "Presione Enter para continuar..."
                read
                ;;
            8)
                clear_screen
                include_subdirs=$(ask_subdirs)
                echo -n "Ingrese el texto que debe contener: "
                read pattern
                filter_files "$directory" "$include_subdirs" "contains" "$pattern" | paginate_output
                echo -n "Presione Enter para continuar..."
                read
                ;;
            9)
                echo -n "Ingrese el nuevo directorio: "
                read directory
                if [ ! -d "$directory" ]; then
                    echo "Error: El directorio '$directory' no existe."
                    echo -n "Presione Enter para continuar..."
                    read
                fi
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
