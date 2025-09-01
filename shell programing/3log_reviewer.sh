#!/bin/bash

# Script: log_reviewer.sh
# Descripción: Revisa archivos de log del sistema
# Autor: [esteban muñoz]
# Fecha: $(2025-08-29)
# Función para limpiar pantalla
clear_screen() {
    clear
}

# Definir archivos de log comunes en diferentes ubicaciones
LOG_FILES=(
    "/var/log/messages"
    "/var/log/syslog" 
    "/var/log/kern.log"
    "/var/log/auth.log"
    "/var/log/daemon.log"
    "/var/log/user.log"
    "/var/log/mail.log"
    "/var/log/cron.log"
    "/var/log/debug"
    "/var/log/secure"
)

# Función para encontrar archivos de log existentes
find_log_files() {
    local found_logs=()
    
    echo "Buscando archivos de log en el sistema..."
    echo
    
    for log_file in "${LOG_FILES[@]}"; do
        if [ -f "$log_file" ] && [ -r "$log_file" ]; then
            found_logs+=("$log_file")
        fi
    done
    
    # También buscar archivos .log en /var/log/
    while IFS= read -r -d '' log_file; do
        if [[ ! " ${found_logs[@]} " =~ " ${log_file} " ]]; then
            found_logs+=("$log_file")
        fi
    done < <(find /var/log -name "*.log" -type f -readable 2>/dev/null | head -10 | tr '\n' '\0')
    
    echo "${found_logs[@]}"
}

# Función para mostrar las últimas 15 líneas de 3 archivos de log
show_recent_logs() {
    local log_files=($1)
    
    echo "=== ÚLTIMAS 15 LÍNEAS DE ARCHIVOS DE LOG ==="
    echo
    
    local count=0
    for log_file in "${log_files[@]}"; do
        if [ $count -ge 3 ]; then
            break
        fi
        
        if [ -f "$log_file" ] && [ -r "$log_file" ]; then
            echo "--- Archivo: $log_file ---"
            echo
            
            # Verificar si el archivo tiene contenido
            if [ -s "$log_file" ]; then
                tail -n 15 "$log_file" 2>/dev/null
            else
                echo "(Archivo vacío)"
            fi
            
            echo
            echo "================================================"
            echo
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo "No se encontraron archivos de log accesibles."
        echo
        echo "Archivos de log típicos que podrían existir:"
        for log_file in "${LOG_FILES[@]}"; do
            echo "  - $log_file"
        done
        echo
        echo "Nota: Es posible que necesite permisos de superusuario para acceder a algunos logs."
    fi
}

# Función para filtrar logs por palabra clave
filter_logs_by_word() {
    local log_files=($1)
    local keyword="$2"
    
    echo "=== LÍNEAS DE LOG QUE CONTIENEN: '$keyword' ==="
    echo
    
    local count=0
    local total_matches=0
    
    for log_file in "${log_files[@]}"; do
        if [ $count -ge 3 ]; then
            break
        fi
        
        if [ -f "$log_file" ] && [ -r "$log_file" ]; then
            echo "--- Archivo: $log_file ---"
            echo
            
            local matches=0
            
            # Obtener las últimas 15 líneas y filtrar por palabra clave
            local filtered_lines=$(tail -n 15 "$log_file" 2>/dev/null | grep -i "$keyword")
            
            if [ -n "$filtered_lines" ]; then
                echo "$filtered_lines"
                matches=$(echo "$filtered_lines" | wc -l)
                total_matches=$((total_matches + matches))
                echo
                echo "Coincidencias en este archivo: $matches"
            else
                echo "(No se encontraron coincidencias en las últimas 15 líneas)"
            fi
            
            echo
            echo "================================================"
            echo
            count=$((count + 1))
        fi
    done
    
    echo "Total de líneas que contienen '$keyword': $total_matches"
    
    if [ $count -eq 0 ]; then
        echo "No se encontraron archivos de log accesibles."
    fi
}

# Función para mostrar información sobre logs
show_log_info() {
    clear_screen
    echo "=== INFORMACIÓN SOBRE ARCHIVOS DE LOG ==="
    echo
    echo "¿Qué son los archivos de log?"
    echo "============================"
    echo "Los archivos de log (registros) son archivos de texto que contienen información"
    echo "sobre eventos, actividades y errores que ocurren en el sistema operativo y"
    echo "aplicaciones. Son fundamentales para:"
    echo "- Monitoreo del sistema"
    echo "- Diagnóstico de problemas" 
    echo "- Auditoría de seguridad"
    echo "- Análisis de rendimiento"
    echo
    
    echo "Tipos de logs comunes en Linux:"
    echo "==============================="
    echo "-