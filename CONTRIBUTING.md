# 🤝 Contributing

Gracias por contribuir a infra-dev-env 🚀

---

## 🧠 Principios

- Todo debe ser **reproducible**
- Nada debe depender del host
- Todo debe pasar por `devctl`
- Scripts deben ser **idempotentes**

---

## 🧱 Estructura

- `devctl/` → CLI
- `boxes/` → definiciones de entornos
- `provision/` → instalación dentro de boxes
- `templates/` → proyectos base
- `shell/` → configuración de shell

---

## 🧪 Testing

Antes de PR:

```bash
devctl doctor
devctl box rebuild python
````

---

## 📦 Nuevos boxes

1. Crear Dockerfile en `boxes/`
2. Agregar comando en `devctl`
3. Documentar en README

---

## 📁 Nuevos templates

1. Crear en `templates/`
2. Agregar comando en `devctl project init`
3. Incluir `.envrc`

---

## 🔥 Pull Requests

* Explicar el problema
* Explicar la solución
* Mantener simple

---

## 🚫 No hacer

* Instalar cosas en host
* Hardcodear paths
* Agregar dependencias innecesarias

````

---

# 📄 2. `.envrc` base (clave para tu modelo)

```bash
use flake || true

layout python3

export PROJECT_NAME=$(basename $(pwd))
export VENV=.venv

if [ ! -d "$VENV" ]; then
  python -m venv $VENV
fi

source $VENV/bin/activate
````
