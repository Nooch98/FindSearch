function donde {
    param (
        [string]$nombre
    )

    try {
        $rutaRegistro = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $programas = Get-ItemProperty -Path $rutaRegistro | Where-Object { $_.DisplayName -like "*$nombre*" }

        if ($programas) {
            $contador = 1
            $programas | ForEach-Object {
                $rutaInstalacion = $_.InstallLocation
                if (-not [string]::IsNullOrWhiteSpace($rutaInstalacion)) {
                    [PSCustomObject]@{
                        'Índice' = $contador
                        'Nombre del programa' = $_.DisplayName
                        'Editor' = $_.Publisher
                        'Ruta de instalación' = $rutaInstalacion
                        'Versión' = $_.DisplayVersion
                        'Tamaño' = $_.Size
                    }
                } else {
                    [PSCustomObject]@{
                        'Índice' = $contador
                        'Nombre del programa' = $_.DisplayName
                        'Editor' = $_.Publisher
                        'Ruta de instalación' = "No se pudo encontrar la ruta de instalación"
                        'Versión' = $_.DisplayVersion
                        'Tamaño' = $_.Size
                    }
                }
                $contador++
            } | Format-Table -AutoSize

            Write-Host "Se encontraron $($programas.Count) programa(s)."

            $indiceElegido = Read-Host "Ingrese el índice del programa para más detalles (o presione Enter para salir)"

            if ($indiceElegido -ge 1 -and $indiceElegido -le $programas.Count) {
                Clear-Host
                $programaSeleccionado = $programas[$indiceElegido - 1]

                $fechaInstalacionSeleccionada = Try {
                    $year = $programaSeleccionado.InstallDate.Substring(0, 4)
                    $month = $programaSeleccionado.InstallDate.Substring(4, 2)
                    $day = $programaSeleccionado.InstallDate.Substring(6, 2)
                    [datetime]::ParseExact("$year$month$day", "yyyyMMdd", $null).ToString("yyyy-MM-dd")
                } Catch {
                    $programaSeleccionado.InstallDate
                }

                [PSCustomObject]@{
                    'Nombre del programa' = $programaSeleccionado.DisplayName
                    'Editor' = $programaSeleccionado.Publisher
                    'Ruta de instalación' = $programaSeleccionado.InstallLocation
                    'Versión' = $programaSeleccionado.DisplayVersion
                    'Tamaño' = $programaSeleccionado.Size
                    'Fecha de instalación' = $fechaInstalacionSeleccionada
                    # Agrega más detalles según sea necesario
                } | Format-List
            } elseif ($indiceElegido -eq "") {
                Write-Host "Saliendo de la búsqueda de programas."
            } else {
                Write-Host "Índice inválido. No se mostraron detalles adicionales." -ForegroundColor Yellow
            }
        } else {
            Write-Host "No se encontró el programa '$nombre' en la lista de instalados." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error al acceder al registro. Detalles: $_" -ForegroundColor Red
    }
}