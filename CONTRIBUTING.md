# Contribuciones

¡Gracias por tu interés en mejorar este proyecto! Para mantener la calidad, portabilidad y orden de la plataforma, te pedimos que sigas estas pautas antes de enviar tus propuestas de cambio.

## Flujo de Trabajo (Workflow)

1. **Haz un Fork** del repositorio.
2. **Crea una rama de desarrollo** con un nombre descriptivo y prefijo claro:
  ```bash
  git checkout -b feature/nueva-box-rust
  # o bien
  git checkout -b fix/corregir-swap-zram
  ```

3. **Realiza tus cambios** y asegúrate de probarlos de manera local antes de subirlos.
4. **Registra tus cambios** utilizando mensajes de commit claros, preferiblemente siguiendo la especificación de [Conventional Commits](https://www.conventionalcommits.org/).
5. **Envía un Pull Request (PR)** apuntando hacia la rama `main` del repositorio original.

---

## Estandares de Calidad y Codigo

Para garantizar que el sistema funcione de manera consistente en cualquier instalación fresca de Fedora, aplicamos las siguientes reglas técnicas:

### 1. Calidad en Scripts de Bash (`devctl` y utilidades)

* **ShellCheck:** Todo script de Bash debe pasar la validación de `shellcheck` sin advertencias críticas o errores de sintaxis.
* **Manejo de Errores:** Utiliza `set -e` en la cabecera de los scripts principales de aprovisionamiento para asegurar que la ejecución se detenga inmediatamente ante cualquier fallo.
* **Uso de Variables:** Encapsula siempre las variables de entorno entre comillas dobles (por ejemplo, `"$TARGET_DIR"`) para evitar roturas de ruta por espacios en el sistema de archivos.

### 2. Estructura de Nuevas Boxes (Contenedores)

Si vas a proponer un nuevo entorno de desarrollo listo para usar (por ejemplo, Rust, Node.js o Go):

* Crea un nuevo directorio bajo la ruta `boxes/<tecnologia>/`.
* Define el `Dockerfile` de forma eficiente: utiliza imágenes base oficiales, agrupa comandos en una sola capa para reducir el tamaño y ejecuta siempre la limpieza de caché del gestor de paquetes (`dnf clean all`) al final del aprovisionamiento.

---

## Reporte de Fallos (Bugs)

Si encuentras un comportamiento inesperado, una falla en `devctl doctor` o algún error durante el despliegue del host:

1. Revisa la sección de **Issues** abiertas para confirmar que nadie esté trabajando ya en una solución.
2. Abre un nuevo reporte detallando:
* Versión de Fedora Host (Workstation, Silverblue, etc.).
* Salida del diagnóstico de tu entorno (`devctl doctor`).
* Pasos reproducibles para experimentar el fallo en otra máquina.
