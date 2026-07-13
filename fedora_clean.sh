#!/bin/bash

# Verificar privilegios de root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Este script debe ejecutarse con privilegios de superusuario (sudo)."
  exit 1
fi

echo "========================================"
echo " Iniciando limpieza del sistema Fedora  "
echo "========================================"

echo ""
echo "[1/3] Limpiando la caché de DNF..."
dnf clean all

echo ""
echo "[2/3] Buscando y eliminando paquetes huérfanos (DNF)..."
# No se usa '-y' para forzar al usuario a revisar la lista de dependencias
dnf autoremove

echo ""
echo "[3/3] Buscando runtimes y aplicaciones huérfanas en Flatpak..."
if command -v flatpak &> /dev/null; then
  # Flatpak es seguro para automatizar con -y, ya que aísla sus dependencias
  flatpak uninstall --system --unused -y
  sudo -u "$SUDO_USER" flatpak uninstall --user --unused -y 2>/dev/null || true
else
  echo "Flatpak no está instalado. Omitiendo."
fi

echo ""
echo "========================================"
echo " Limpieza finalizada.                   "
echo "========================================"
