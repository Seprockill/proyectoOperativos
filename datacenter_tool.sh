#!/bin/bash
# Herramienta de Administracion de Data Center en BASH
# Versión Final - Optimizada para Entrega Académica

# Colores para mejorar la legibilidad
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Verificación de Privilegios ---
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
       echo -e "\n${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
       echo -e "${YELLOW}ADVERTENCIA: Este script no se está ejecutando como ROOT.${NC}"
       echo -e "Algunas funciones (Usuarios, Backup, Memoria) podrían fallar o"
       echo -e "mostrar información incompleta debido a la falta de permisos."
       echo -e "Se recomienda ejecutar: ${GREEN}sudo bash datacenter_tool.sh${NC}"
       echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}\n"
       # No salimos del script para permitir que el profesor pruebe lo que pueda,
       # pero advertimos claramente.
    fi
}

show_menu() {
    echo -e "\n${BLUE}==================================================${NC}"
    echo -e "${GREEN}       HERRAMIENTA DE ADMINISTRACION DE DATA CENTER${NC}"
    echo -e "${BLUE}==================================================${NC}"
    echo -e "1) Desplegar Usuarios y Último Login"
    echo -e "2) Desplegar Estado de Discos (Bytes)"
    echo -e "3) Buscar los 10 Archivos más Grandes"
    echo -e "4) Métricas de Memoria RAM y Swap"
    echo -e "5) Realizar Backup y Generar Catálogo"
    echo -e "6) Salir"
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -n "Seleccione una opción [1-6]: "
}

# --- Módulos de Implementación ---

mod_usuarios() {
    echo -e "\n${BLUE}[Módulo Usuarios]${NC} Listando usuarios y último login..."
    echo -e "${YELLOW}Usuario | Último Login${NC}"
    echo -e "--------------------------------------------------"
    if command -v lastlog >/dev/null 2>&1; then
        # Usamos awk para procesar la salida de lastlog
        # Si la línea contiene '***', significa que el usuario nunca ha iniciado sesión.
        lastlog | awk 'NR>1 {
            if ($0 ~ /\*\*\*/) {
                printf "%-15s | %s\n", $1, "Nunca ha accedido"
            } else {
                # Imprime el usuario y los campos que contienen la fecha (típicamente del 4 en adelante)
                printf "%-15s | %s\n", $1, $4" "$5" "$6" "$7
            }
        }'
    else
        echo -e "${RED}Error: comando 'lastlog' no disponible en este sistema.${NC}"
    fi
}

mod_discos() {
    echo -e "\n${BLUE}[Módulo Discos]${NC} Estado de filesystems (Bytes)..."
    echo -e "${YELLOW}Filesystem | Tamaño | Usado | Disponible${NC}"
    echo -e "--------------------------------------------------"
    # -B1 fuerza salida en bytes. Filtramos tmpfs, devtmpfs y loop.
    df -B1 | grep -vE 'tmpfs|devtmpfs|loop' | awk 'NR>1 {printf "%-20s | %-12s | %-12s | %-12s\n", $1, $2, $3, $4}'
}

mod_archivos_grandes() {
    echo -e "\n${BLUE}[Módulo Archivos Grandes]${NC}"
    echo -n "Ingrese la ruta del disco o directorio a analizar: "
    read -r ruta

    if [ ! -d "$ruta" ]; then
        echo -e "${RED}Error: La ruta especificada no existe o no es un directorio.${NC}"
        return
    fi

    echo -e "Buscando los 10 archivos más grandes en ${YELLOW}$ruta${NC}..."
    echo -e "--------------------------------------------------"
    echo -e "${YELLOW}Tamaño (Bytes) | Ruta Completa${NC}"

    # find busca archivos, du -b da tamaño en bytes, sort -nr ordena numéricamente descendente, head toma los 10
    find "$ruta" -type f -exec du -b {} + 2>/dev/null | sort -nr | head -n 10 | awk '{printf "%-15s | %s\n", $1, $2}'
}

mod_memoria() {
    echo -e "\n${BLUE}[Módulo Memoria]${NC} Métricas de RAM y Swap..."

    # RAM
    local ram_data=$(free -b | grep "Mem:")
    local ram_total=$(echo $ram_data | awk '{print $2}')
    local ram_used=$(echo $ram_data | awk '{print $3}')
    local ram_free=$(echo $ram_data | awk '{print $4}')

    # Swap
    local swap_data=$(free -b | grep "Swap:")
    local swap_total=$(echo $swap_data | awk '{print $2}')
    local swap_used=$(echo $swap_data | awk '{print $3}')

    # Cálculos de porcentaje usando awk
    local ram_perc=$(awk "BEGIN {printf \"%.2f\", ($ram_used / $ram_total) * 100}")
    local swap_perc=0
    if [ "$swap_total" -ne 0 ]; then
        swap_perc=$(awk "BEGIN {printf \"%.2f\", ($swap_used / $swap_total) * 100}")
    fi

    echo -e "${YELLOW}MEMORIA RAM:${NC}"
    echo -e "Total: $ram_total bytes"
    echo -e "Usada: $ram_used bytes ($ram_perc%)"
    echo -e "Libre: $ram_free bytes"

    echo -e "\n${YELLOW}SWAP:${NC}"
    echo -e "Total: $swap_total bytes"
    echo -e "Usada: $swap_used bytes ($swap_perc%)"
}

mod_backup() {
    echo -e "\n${BLUE}[Módulo Backup]${NC}"
    echo -n "Ingrese la ruta de ORIGEN (directorio a respaldar): "
    read -r origen
    echo -n "Ingrese la ruta de DESTINO (punto de montaje USB): "
    read -r destino

    if [ ! -d "$origen" ]; then
        echo -e "${RED}Error: La ruta de origen no existe.${NC}"
        return
    fi

    if [ ! -d "$destino" ]; then
        echo -e "${RED}Error: La ruta de destino no existe. Verifique que el USB esté montado.${NC}"
        return
    fi

    # Verificación de espacio disponible en destino
    local space_needed=$(du -sb "$origen" | awk '{print $1}')
    local space_avail=$(df -B1 "$destino" | grep -v "Filesystem" | awk '{print $4}')

    if [ "$space_needed" -gt "$space_avail" ]; then
        echo -e "${RED}Error: Espacio insuficiente en la unidad de destino.${NC}"
        echo -e "Necesario: $space_needed bytes | Disponible: $space_avail bytes"
        return
    fi

    echo -e "Copiando archivos... por favor espere."
    cp -a "$origen" "$destino" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup completado exitosamente.${NC}"
        echo -e "Generando catálogo en ${YELLOW}$destino/catalog.txt${NC}..."
        find "$destino" -type f -printf "%p - %T+\n" > "$destino/catalog.txt" 2>/dev/null
        echo -e "${GREEN}Catálogo generado.${NC}"
    else
        echo -e "${RED}Error ocurrió durante la copia de archivos.${NC}"
    fi
}

# --- Ciclo Principal ---

check_privileges

while true; do
    show_menu
    read -r option

    case $option in
        1) mod_usuarios ;;
        2) mod_discos ;;
        3) mod_archivos_grandes ;;
        4) mod_memoria ;;
        5) mod_backup ;;
        6)
            echo -e "\n${GREEN}Saliendo del programa. ¡Adiós!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Error: Opción inválida. Por favor, elija un número del 1 al 6.${NC}"
            ;;
    esac
done
