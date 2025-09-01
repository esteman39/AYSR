#!/bin/bash

# Script: newuser.sh y newgroup.sh
# Descripción: Automatiza la creación de usuarios y grupos con permisos
# Autor: [esteban muñoz]
# Fecha: $(2025-08-29)
# Uso: ./newuser.sh username groupname "Full Name" homedir shell dir_perm group_perm file_perm
#      ./newgroup.sh groupname gid

# Función para verificar si el script se ejecuta como root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: Este script debe ejecutarse como root (sudo)."
        echo "Uso: sudo $0 [argumentos]"
        exit 1
    fi
}

# Función para validar permisos octales
validate_permissions() {
    local perm=$1
    if [[ ! "$perm" =~ ^[0-7]{3}$ ]]; then
        echo "Error: Los permisos deben ser un número octal de 3 dígitos (ej: 755)"
        return 1
    fi
    return 0
}

# Función para crear grupo
create_group() {
    local groupname="$1"
    local gid="$2"
    
    echo "=== Creando grupo: $groupname ==="
    
    # Verificar si el grupo ya existe
    if getent group "$groupname" >/dev/null 2>&1; then
        echo "El grupo '$groupname' ya existe."
        return 0
    fi
    
    # Verificar si el GID está especificado y es válido
    if [ -n "$gid" ]; then
        if [[ ! "$gid" =~ ^[0-9]+$ ]]; then
            echo "Error: El GID debe ser un número."
            return 1
        fi
        
        # Verificar si el GID ya está en uso
        if getent group "$gid" >/dev/null 2>&1; then
            echo "Error: El GID $gid ya está en uso."
            return 1
        fi
        
        groupadd -g "$gid" "$groupname"
    else
        groupadd "$groupname"
    fi
    
    if [ $? -eq 0 ]; then
        echo "Grupo '$groupname' creado exitosamente."
        echo "GID asignado: $(getent group "$groupname" | cut -d: -f3)"
    else
        echo "Error al crear el grupo '$groupname'."
        return 1
    fi
}

# Función para crear usuario
create_user() {
    local username="$1"
    local groupname="$2"
    local fullname="$3"
    local homedir="$4"
    local shell="$5"
    local dir_perm="$6"
    local group_perm="$7"
    local file_perm="$8"
    
    echo "=== Creando usuario: $username ==="
    
    # Verificar si el usuario ya existe
    if id "$username" >/dev/null 2>&1; then
        echo "El usuario '$username' ya existe."
        return 1
    fi
    
    # Verificar si el grupo existe
    if ! getent group "$groupname" >/dev/null 2>&1; then
        echo "El grupo '$groupname' no existe. ¿Desea crearlo? (s/n)"
        read -r response
        if [[ "$response" =~ ^[sS] ]]; then
            create_group "$groupname"
            if [ $? -ne 0 ]; then
                echo "Error al crear el grupo. Abortando creación de usuario."
                return 1
            fi
        else
            echo "No se puede crear el usuario sin un grupo válido."
            return 1
        fi
    fi
    
    # Verificar que el shell existe
    if [ ! -x "$shell" ]; then
        echo "Advertencia: El shell '$shell' no existe o no es ejecutable."
        echo "¿Desea continuar? (s/n)"
        read -r response
        if [[ ! "$response" =~ ^[sS] ]]; then
            return 1
        fi
    fi
    
    # Crear el usuario
    useradd -m -d "$homedir" -s "$shell" -g "$groupname" -c "$fullname" "$username"
    
    if [ $? -ne 0 ]; then
        echo "Error al crear el usuario '$username'."
        return 1
    fi
    
    echo "Usuario '$username' creado exitosamente."
    
    # Establecer contraseña
    echo "Estableciendo contraseña para $username..."
    passwd "$username"
    
    # Aplicar permisos al directorio home
    echo "Aplicando permisos al directorio home..."
    chmod "$dir_perm" "$homedir"
    
    # Cambiar el grupo del directorio home
    chgrp "$groupname" "$homedir"
    
    # Si se especificaron permisos de grupo, aplicarlos
    if [ -n "$group_perm" ]; then
        echo "Aplicando permisos de grupo ($group_perm) al directorio..."
        chmod g="$(echo "$group_perm" | cut -c2)" "$homedir"
    fi
    
    # Crear algunos archivos de ejemplo y aplicar permisos
    touch "$homedir/.bashrc_backup"
    touch "$homedir/welcome.txt"
    
    if [ -n "$file_perm" ]; then
        echo "Aplicando permisos de archivos ($file_perm)..."
        chmod "$file_perm" "$homedir/welcome.txt"
    fi
    
    # Mostrar información del usuario creado
    echo
    echo "=== Información del usuario creado ==="
    echo "Usuario: $username"
    echo "Grupo principal: $groupname"
    echo "Nombre completo: $fullname"
    echo "Directorio home: $homedir"
    echo "Shell: $shell"
    echo "UID: $(id -u "$username")"
    echo "GID: $(id -g "$username")"
    echo
    echo "Permisos aplicados:"
    ls -la "$homedir" | head -5
}

# Script principal para newuser
newuser_main() {
    local username="$1"
    local groupname="$2"
    local fullname="$3"
    local homedir="$4"
    local shell="$5"
    local dir_perm="$6"
    local group_perm="$7"
    local file_perm="$8"
    
    # Verificar número de argumentos
    if [ $# -lt 5 ]; then
        echo "Uso: $0 username groupname \"Full Name\" homedir shell [dir_perm] [group_perm] [file_perm]"
        echo
        echo "Ejemplo:"
        echo "$0 alice developers \"Alice Developer\" /home/alice /bin/bash 700 770 755"
        echo
        echo "Parámetros:"
        echo "  username    - Nombre del usuario a crear"
        echo "  groupname   - Grupo principal del usuario"
        echo "  \"Full Name\" - Nombre completo del usuario (entre comillas)"
        echo "  homedir     - Directorio home del usuario"
        echo "  shell       - Shell del usuario (ej: /bin/bash)"
        echo "  dir_perm    - Permisos del directorio home (opcional, por defecto 755)"
        echo "  group_perm  - Permisos de grupo (opcional)"
        echo "  file_perm   - Permisos de archivos (opcional, por defecto 644)"
        exit 1
    fi
    
    # Asignar valores por defecto si no se proporcionan
    dir_perm=${dir_perm:-755}
    file_perm=${file_perm:-644}
    
    # Validar permisos
    if ! validate_permissions "$dir_perm"; then
        exit 1
    fi
    
    if [ -n "$file_perm" ] && ! validate_permissions "$file_perm"; then
        exit 1
    fi
    
    if [ -n "$group_perm" ] && ! validate_permissions "$group_perm"; then
        exit 1
    fi
    
    # Verificar privilegios de root
    check_root
    
    # Crear usuario
    create_user "$username" "$groupname" "$fullname" "$homedir" "$shell" "$dir_perm" "$group_perm" "$file_perm"
}

# Script principal para newgroup
newgroup_main() {
    local groupname="$1"
    local gid="$2"
    
    # Verificar argumentos
    if [ -z "$groupname" ]; then
        echo "Uso: $0 groupname [gid]"
        echo
        echo "Ejemplo:"
        echo "$0 developers 1001"
        echo
        echo "Parámetros:"
        echo "  groupname - Nombre del grupo a crear"
        echo "  gid       - GID del grupo (opcional)"
        exit 1
    fi
    
    # Verificar privilegios de root
    check_root
    
    # Crear grupo
    create_group "$groupname" "$gid"
}

# Función para mostrar menú interactivo
interactive_menu() {
    local choice
    
    while true; do
        clear
        echo "========================================"
        echo "    GESTIÓN DE USUARIOS Y GRUPOS"
        echo "========================================"
        echo "1. Crear usuario interactivamente"
        echo "2. Crear grupo interactivamente"
        echo "3. Listar usuarios del sistema"
        echo "4. Listar grupos del sistema"
        echo "5. Mostrar información de usuario"
        echo "0. Salir"
        echo "========================================"
        echo -n "Seleccione una opción: "
        read choice
        
        case "$choice" in
            1) interactive_create_user ;;
            2) interactive_create_group ;;
            3) list_users ;;
            4) list_groups ;;
            5) show_user_info ;;
            0) echo "¡Hasta luego!"; exit 0 ;;
            *) echo "Opción inválida. Presione Enter para continuar..."; read ;;
        esac
    done
}

# Función para crear usuario interactivamente
interactive_create_user() {
    echo
    echo "=== CREACIÓN INTERACTIVA DE USUARIO ==="
    echo -n "Nombre de usuario: "
    read username
    echo -n "Grupo principal: "
    read groupname
    echo -n "Nombre completo: "
    read fullname
    echo -n "Directorio home [/home/$username]: "
    read homedir
    homedir=${homedir:-/home/$username}
    echo -n "Shell [/bin/bash]: "
    read shell
    shell=${shell:-/bin/bash}
    echo -n "Permisos directorio [755]: "
    read dir_perm
    dir_perm=${dir_perm:-755}
    echo -n "Permisos grupo [770]: "
    read group_perm
    echo -n "Permisos archivos [644]: "
    read file_perm
    file_perm=${file_perm:-644}
    
    create_user "$username" "$groupname" "$fullname" "$homedir" "$shell" "$dir_perm" "$group_perm" "$file_perm"
    echo -n "Presione Enter para continuar..."
    read
}

# Función para crear grupo interactivamente
interactive_create_group() {
    echo
    echo "=== CREACIÓN INTERACTIVA DE GRUPO ==="
    echo -n "Nombre del grupo: "
    read groupname
    echo -n "GID (dejar vacío para asignación automática): "
    read gid
    
    create_group "$groupname" "$gid"
    echo -n "Presione Enter para continuar..."
    read
}

# Función para listar usuarios
list_users() {
    echo
    echo "=== USUARIOS DEL SISTEMA ==="
    echo "Usuario:UID:GID:Nombre:Home:Shell"
    echo "=================================="
    cat /etc/passwd | awk -F: '$3 >= 1000 {print $1":"$3":"$4":"$5":"$6":"$7}' | sort
    echo -n "Presione Enter para continuar..."
    read
}

# Función para listar grupos
list_groups() {
    echo
    echo "=== GRUPOS DEL SISTEMA ==="
    echo "Grupo:GID:Miembros"
    echo "=================="
    cat /etc/group | awk -F: '$3 >= 1000 {print $1":"$3":"$4}' | sort
    echo -n "Presione Enter para continuar..."
    read
}

# Función para mostrar información de usuario
show_user_info() {
    echo
    echo -n "Ingrese el nombre de usuario: "
    read username
    
    if id "$username" >/dev/null 2>&1; then
        echo
        echo "=== INFORMACIÓN DEL USUARIO: $username ==="
        id "$username"
        echo
        echo "Entrada en /etc/passwd:"
        grep "^$username:" /etc/passwd
        echo
        echo "Grupos del usuario:"
        groups "$username"
        echo
        echo "Directorio home:"
        ls -la $(eval echo ~$username) 2>/dev/null | head -5
    else
        echo "El usuario '$username' no existe."
    fi
    
    echo -n "Presione Enter para continuar..."
    read
}

# Detectar cómo se está ejecutando el script
script_name=$(basename "$0")

case "$script_name" in
    "newuser.sh")
        newuser_main "$@"
        ;;
    "newgroup.sh")
        newgroup_main "$@"
        ;;
    *)
        if [ $# -eq 0 ]; then
            # Modo interactivo si no hay argumentos
            check_root
            interactive_menu
        else
            # Determinar acción basada en argumentos
            if [ $# -eq 2 ] && [[ "$2" =~ ^[0-9]+$ ]]; then
                newgroup_main "$@"
            elif [ $# -ge 5 ]; then
                newuser_main "$@"
            else
                echo "Uso ambiguo. Use:"
                echo "Para crear usuario: $0 username groupname \"Full Name\" homedir shell [permisos...]"
                echo "Para crear grupo: $0 groupname gid"
                echo "Para modo interactivo: $0 (sin argumentos)"
                exit 1
            fi
        fi
        ;;
esac