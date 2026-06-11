<#
.SYNOPSIS
    Herramienta de Administracion de Data Center en PowerShell.
.DESCRIPTION
    Este script proporciona un menú interactivo para administrar usuarios,
    discos, archivos grandes, memoria y realizar backups en un entorno de Data Center.
#>

# Configuración de colores
$colorBlue = "Cyan"
$colorGreen = "Green"
$colorRed = "Red"
$colorYellow = "Yellow"

# --- Verificación de Privilegios ---
function Check-Privileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "`n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor $colorRed
        Write-Host "ADVERTENCIA: Este script no se está ejecutando como ADMINISTRADOR." -ForegroundColor $colorYellow
        Write-Host "Algunas funciones podrían fallar debido a la falta de permisos."
        Write-Host "Se recomienda ejecutar PowerShell como Administrador." -ForegroundColor $colorGreen
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!`n" -ForegroundColor $colorRed
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "`n==================================================" -ForegroundColor $colorBlue
    Write-Host "       HERRAMIENTA DE ADMINISTRACION DE DATA CENTER" -ForegroundColor $colorGreen
    Write-Host "==================================================" -ForegroundColor $colorBlue
    Write-Host "1) Desplegar Usuarios y Último Login"
    Write-Host "2) Desplegar Estado de Discos (Bytes)"
    Write-Host "3) Buscar los 10 Archivos más Grandes"
    Write-Host "4) Métricas de Memoria RAM y Swap"
    Write-Host "5) Realizar Backup y Generar Catálogo"
    Write-Host "6) Salir"
    Write-Host "--------------------------------------------------" -ForegroundColor $colorBlue
    Write-Host "`nSeleccione una opción [1-6]: " -NoNewline
}

# --- Módulos de Implementación ---

function Invoke-ModUsuarios {
    Write-Host "`n[Módulo Usuarios] Listando usuarios y último login..." -ForegroundColor $colorBlue
    Write-Host "Usuario | Último Login" -ForegroundColor $colorYellow
    Write-Host "--------------------------------------------------"

    try {
        $profiles = Get-CimInstance Win32_NetworkLoginProfile
        $users = Get-LocalUser

        foreach ($user in $users) {
            $profile = $profiles | Where-Object { $_.Name -like "*$($user.Name)*" }
            $lastLogin = "Nunca"
            if ($profile -and $profile.LastLogon) {
                $lastLogin = $profile.LastLogon.ToString()
            }
            Write-Host ("{0,-15} | {1}" -f $user.Name, $lastLogin)
        }
    } catch {
        Write-Host "Error al obtener usuarios: $($_.Exception.Message)" -ForegroundColor $colorRed
    }
    Read-Host "`nPresione Enter para volver al menú..."
}

function Invoke-ModDiscos {
    Write-Host "`n[Módulo Discos] Estado de filesystems (Bytes)..." -ForegroundColor $colorBlue
    Write-Host "DeviceID | Tamaño | Espacio Libre" -ForegroundColor $colorYellow
    Write-Host "--------------------------------------------------"

    try {
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($disk in $disks) {
            Write-Host ("{0,-10} | {1,15} | {2,15}" -f $disk.DeviceID, $disk.Size, $disk.FreeSpace)
        }
    } catch {
        Write-Host "Error al obtener datos de disco: $($_.Exception.Message)" -ForegroundColor $colorRed
    }
    Read-Host "`nPresione Enter para volver al menú..."
}

function Invoke-ModArchivosGrandes {
    Write-Host "`n[Módulo Archivos Grandes]" -ForegroundColor $colorBlue
    $path = Read-Host "Ingrese la ruta del disco o directorio a analizar"

    if (-not (Test-Path $path -PathType Container)) {
        Write-Host "Error: La ruta especificada no existe o no es un directorio." -ForegroundColor $colorRed
        Read-Host "`nPresione Enter para volver al menú..."
        return
    }

    Write-Host "Buscando los 10 archivos más grandes en $path..." -ForegroundColor $colorYellow
    Write-Host "--------------------------------------------------"
    Write-Host "Tamaño (Bytes) | Ruta Completa" -ForegroundColor $colorYellow

    try {
        $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue |
                 Sort-Object Length -Descending |
                 Select-Object -First 10

        if ($null -eq $files) {
            Write-Host "No se encontraron archivos en la ruta especificada."
        } else {
            foreach ($file in $files) {
                Write-Host ("{0,15} | {1}" -f $file.Length, $file.FullName)
            }
        }
    } catch {
        Write-Host "Error durante la búsqueda de archivos: $($_.Exception.Message)" -ForegroundColor $colorRed
    }
    Read-Host "`nPresione Enter para volver al menú..."
}

function Invoke-ModMemoria {
    Write-Host "`n[Módulo Memoria] Métricas de RAM y Swap..." -ForegroundColor $colorBlue

    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $totalRam = $os.TotalVisibleMemorySize * 1024
        $freeRam = $os.FreePhysicalMemory * 1024
        $usedRam = $totalRam - $freeRam
        $ramPerc = [Math]::Round(($usedRam / $totalRam) * 100, 2)

        Write-Host "MEMORIA RAM:" -ForegroundColor $colorYellow
        Write-Host "Total: $totalRam bytes"
        Write-Host "Usada: $usedRam bytes ($ramPerc%)"
        Write-Host "Libre: $freeRam bytes"

        $swap = Get-CimInstance Win32_PageFileUsage
        if ($swap) {
            $totalSwap = $swap.AllocatedBaseSize * 1024 * 1024
            $usedSwap = $swap.CurrentUsage * 1024 * 1024
            $swapPerc = [Math]::Round(($usedSwap / $totalSwap) * 100, 2)

            Write-Host "`nSWAP:" -ForegroundColor $colorYellow
            Write-Host "Total: $totalSwap bytes"
            Write-Host "Usada: $usedSwap bytes ($swapPerc%)"
        } else {
            Write-Host "`nSWAP: No detectado o no configurado."
        }
    } catch {
        Write-Host "Error al obtener métricas de memoria: $($_.Exception.Message)" -ForegroundColor $colorRed
    }
    Read-Host "`nPresione Enter para volver al menú..."
}

function Invoke-ModBackup {
    Write-Host "`n[Módulo Backup]" -ForegroundColor $colorBlue
    $origin = Read-Host "Ingrese la ruta de ORIGEN (directorio a respaldar)"
    $destination = Read-Host "Ingrese la ruta de DESTINO (ej. D:\backup)"

    if (-not (Test-Path $origin -PathType Container)) {
        Write-Host "Error: La ruta de origen no existe." -ForegroundColor $colorRed
        Read-Host "`nPresione Enter para volver al menú..."
        return
    }

    if (-not (Test-Path $destination -PathType Container)) {
        Write-Host "Error: La ruta de destino no existe. Verifique que la USB esté conectada." -ForegroundColor $colorRed
        Read-Host "`nPresione Enter para volver al menú..."
        return
    }

    try {
        # Verificación de espacio en destino
        $originSize = (Get-ChildItem $origin -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $destDrive = (Get-Item $destination).PSDrive.Present
        $freeSpace = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($destDrive)'").FreeSpace

        if ($originSize -gt $freeSpace) {
            Write-Host "Error: Espacio insuficiente en la unidad de destino." -ForegroundColor $colorRed
            Write-Host "Necesario: $originSize bytes | Disponible: $freeSpace bytes"
            Read-Host "`nPresione Enter para volver al menú..."
            return
        }

        Write-Host "Copiando archivos... por favor espere." -ForegroundColor $colorYellow
        Copy-Item -Path $origin -Destination $destination -Recurse -Force -ErrorAction Stop

        Write-Host "Backup completado exitosamente." -ForegroundColor $colorGreen
        Write-Host "Generando catálogo en $destination\catalog.txt..." -ForegroundColor $colorYellow

        $catalogPath = Join-Path $destination "catalog.txt"
        Get-ChildItem -Path $destination -Recurse -File |
            Select-Object @{Name="Path"; Expression={$_.FullName}}, @{Name="LastModified"; Expression={$_.LastWriteTime}} |
            Out-File -FilePath $catalogPath

        Write-Host "Catálogo generado correctamente." -ForegroundColor $colorGreen
    } catch {
        Write-Host "Error ocurrió durante el backup: $($_.Exception.Message)" -ForegroundColor $colorRed
    }
    Read-Host "`nPresione Enter para volver al menú..."
}

# --- Ciclo Principal ---

Check-Privileges

$choice = ""
do {
    Show-Menu
    $choice = Read-Host

    switch ($choice) {
        "1" { Invoke-ModUsuarios }
        "2" { Invoke-ModDiscos }
        "3" { Invoke-ModArchivosGrandes }
        "4" { Invoke-ModMemoria }
        "5" { Invoke-ModBackup }
        "6" {
            Write-Host "`nSaliendo del programa. ¡Adiós!" -ForegroundColor $colorGreen
        }
        Default {
            Write-Host "`nError: Opción inválida. Por favor, elija un número del 1 al 6." -ForegroundColor $colorRed
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "6")
