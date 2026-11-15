# Checklist de la primera auditoría (solo loopback)

1. `bash -n` a los scripts de `.claude/scripts/` y repasar `AGENTS.md` (alcance y herramientas).
2. Arrancar la app local a auditar (si la hay) y anotar su puerto. Los 5000/7000 son AirPlay de macOS.
3. `.claude/scripts/audit.sh 127.0.0.1 PUERTOS --diff` (añadir `--containers` si la app corre en Docker/Colima; hoy Colima está parado y no se arranca desde aquí).
4. Leer `.claude/reports/latest/report.md`: dueño de cada puerto (¿`EXPUESTO(todas-las-interfaces)`?), cabeceras, métodos (`Allow`), rutas distintas de 404, cookies/CORS, NSE y certificado.
5. Descartar falsos positivos conocidos (403 uniforme de AirPlay) y comparar con el run anterior.
6. Guardar notas y pruebas manuales en `localhost/`; hallazgos en `.claude/notes/`.
