# Herramientas de Administración de Data Center

Este proyecto consiste en la implementación de dos herramientas de administración de sistemas diseñadas para facilitar las labores de un administrador de Data Center. Se han desarrollado dos versiones: una para entornos Linux utilizando **BASH** y otra para entornos Windows utilizando **PowerShell**.

## Funcionalidades

Ambas herramientas ofrecen un menú interactivo con las siguientes capacidades:

1.  **Gestión de Usuarios**: Despliega la lista de usuarios creados en el sistema junto con la fecha y hora de su último inicio de sesión (login).
2.  **Estado de Discos**: Muestra los filesystems o discos conectados, detallando su tamaño total y el espacio libre disponible, expresados estrictamente en **bytes**.
3.  **Análisis de Archivos Grandes**: Permite al usuario especificar una ruta y despliega los 10 archivos más grandes almacenados en dicho disco o filesystem, incluyendo su trayectoria completa.
4.  **Métricas de Memoria**: Calcula la cantidad de memoria RAM libre y la cantidad de espacio de Swap en uso, mostrando los resultados tanto en **bytes** como en **porcentaje**.
5.  **Sistema de Backup y Catálogo**: Realiza una copia de seguridad de un directorio especificado hacia una unidad USB. Además, genera un archivo `catalog.txt` en el destino que contiene el nombre de cada archivo copiado y su fecha de última modificación.

---

## Requisitos e Instalación

### Versión BASH (Linux)
- **Sistema Operativo**: Distribuciones Linux (Ubuntu, Debian, Fedora, CachyOS, etc.).
- **Privilegios**: Se recomienda ejecutar como root para acceder a la información de todos los usuarios y rutas protegidas.
- **Ejecución**:
  ```bash
  # Dar permisos de ejecución
  chmod +x datacenter_tool.sh
  
  # Ejecutar con privilegios de root
  sudo ./datacenter_tool.sh
  ```

### Versión PowerShell (Windows)
- **Sistema Operativo**: Windows 10/11 o PowerShell Core en Linux.
- **Privilegios**: Ejecutar la terminal de PowerShell como **Administrador**.
- **Ejecución**:
  ```powershell
  # Ejecutar el script
  .\datacenter_tool.ps1
  ```
  *Nota: Si encuentra problemas de ejecución, puede habilitar la ejecución de scripts con: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`*

---

## Guía de Uso

Al iniciar cualquiera de las herramientas, se presentará un menú numérico. Simplemente digite el número de la opción deseada y presione `Enter`.

| Opción | Descripción | Input Requerido | Resultado Esperado |
| :--- | :--- | :--- | :--- |
| **1** | Usuarios | Ninguno | Lista: `Usuario | Fecha Login` |
| **2** | Discos | Ninguno | Tabla: `Disco | Tamaño(B) | Libre(B)` |
| **3** | Archivos Grandes | Ruta de carpeta | Top 10: `Tamaño(B) | Ruta Absoluta` |
| **4** | Memoria/Swap | Ninguno | RAM y Swap en Bytes y % |
| **5** | Backup | Origen y Destino | Archivos copiados + `catalog.txt` |
| **6** | Salir | Ninguno | Cierre de la aplicación |

---

## Estructura del Proyecto

- `datacenter_tool.sh`: Implementación en BASH.
- `datacenter_tool.ps1`: Implementación en PowerShell.
- `plan.md`: Planificación original del proyecto.
- `implementation_plan.md`: Detalle técnico de la implementación.
- `README.md`: Documentación del proyecto.

---

## Equipo
- Sebastian Jimenez

