function find {
    param (
        [string]$nombreElemento,
        [string]$rutaInicial = "C:\"
    )

    try {
        # Buscar en el sistema de archivos en paralelo
        $elementosSistema = Get-ChildItem -Path $rutaInicial -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$nombreElemento*" }
        $elementosSistema | ForEach-Object {
            $ruta = $_.DirectoryName
            Start-Job -ScriptBlock {
                param ($ruta)
                Set-Location -Path $ruta
            } -ArgumentList $ruta | Out-Null
        }

        if ($elementosSistema) {
            $contador = 1
            $elementosSistema | ForEach-Object {
                [PSCustomObject]@{
                    'Índice' = $contador
                    'Nombre del elemento' = $_.Name
                    'Ruta completa' = $_.FullName
                }
                $contador++
            } | Format-Table -AutoSize

            Write-Host "Iniciando navegación a las ubicaciones encontradas en $rutaInicial..."

            # Esperar a que todos los trabajos paralelos finalicen
            Get-Job | Wait-Job | Out-Null

            $indiceElegido = Read-Host "Ingrese el índice del elemento al que desea navegar"

            if ($indiceElegido -ge 1 -and $indiceElegido -le $elementosSistema.Count) {
                $rutaElegida = $elementosSistema[$indiceElegido - 1].DirectoryName
                Write-Host "Navegando a: $rutaElegida"
                Set-Location -Path $rutaElegida -ErrorAction Stop
                Write-Host "Navegación completada con éxito." -ForegroundColor Green
            } else {
                Write-Host "Índice inválido. No se realizó la navegación." -ForegroundColor Red
            }
        } else {
            Write-Host "No se encontró '$nombreElemento' en el sistema de archivos." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error al buscar y navegar. Detalles: $_" -ForegroundColor Red
    } finally {
        # Limpiar trabajos paralelos
        Get-Job | Remove-Job -Force
    }
}
