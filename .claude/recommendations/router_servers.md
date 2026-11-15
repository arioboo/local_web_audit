# Guía rápida: NAS, DLNA y FTP en el router

Qué son y cómo se relacionan con este proyecto. Muchos routers domésticos incluyen estos servicios (a menudo al enchufarles un disco USB), y son una fuente típica de exposición en la LAN.

## NAS (Network Attached Storage)
Un equipo, o una función del router, que **guarda ficheros y los ofrece por la red**: un disco siempre encendido al que acceden varios dispositivos. Puede ser una caja dedicada (Synology, QNAP), un mini-PC con Linux o el disco USB conectado al router.

Un NAS suele hablar varios protocolos a la vez:

| Protocolo | Puerto típico | Para qué |
|---|---|---|
| SMB/CIFS | 445/TCP | carpetas compartidas con Windows y macOS (el más común) |
| AFP | 548/TCP | carpetas para macOS antiguo; en desuso |
| NFS | 2049 | carpetas para Linux y Unix |
| FTP / SFTP | 21 / 22 | transferir ficheros |
| WebDAV | 80, 443, 5005... | acceso por HTTP(S) |
| Interfaz web de gestión | 80, 443, 5000, 8080... | administrar el equipo |

## DLNA (Digital Living Network Alliance)
Estándar para **compartir vídeo, música y fotos** con televisores, consolas y reproductores de la misma red, sin copiar los ficheros. Se apoya en UPnP AV:

- Un **servidor** (el NAS o el router) publica su biblioteca multimedia.
- Un **cliente** (la tele) lo descubre con anuncios **SSDP** (UDP 1900, multicast) y reproduce por **HTTP** en un puerto que elige el servidor.
- No lleva autenticación: cualquiera en la LAN ve la biblioteca. Pensado para redes de confianza.

## FTP (File Transfer Protocol)
Protocolo antiguo para **subir y bajar ficheros**. Control en el puerto **21/TCP** y datos en otro puerto (modo activo u pasivo, con un rango variable).

- Envía **usuario, contraseña y datos sin cifrar**: cualquiera que vea el tráfico los lee.
- El acceso **anónimo** es habitual y peligroso si hay carpetas con escritura.
- Alternativas: **SFTP** (sobre SSH, puerto 22) o **FTPS** (FTP con TLS). Mejor SFTP.

## Riesgos habituales
- **Exposición a Internet**: reenvío de puertos o UPnP en el router que abre 21, 445 o la gestión web hacia fuera. Es lo más grave.
- **Credenciales por defecto** y FTP anónimo.
- **Firmware sin actualizar** en router o NAS (ataques conocidos contra SMB y gestión web).
- **Servicios que no usas** y siguen activos (DLNA, FTP, el disco USB compartido).

## Qué revisar en el router (tu red, tú decides)
1. Panel del router (suele ser `192.168.x.1`): desactivar FTP, DLNA o el servidor de ficheros USB si no se usan.
2. Desactivar **UPnP** y revisar el **reenvío de puertos**: no debe haber nada hacia FTP, SMB ni la gestión.
3. Cambiar la contraseña de administración y actualizar el firmware.
4. Si usas FTP, pasar a SFTP, sin acceso anónimo.

## Cómo encaja en este proyecto
- `local_web_audit` mira **solo loopback** (`127.0.0.1`, `localhost`, `::1`). El router y el NAS son equipos de la LAN: están **fuera de alcance**, y `lan/` está reservada y vacía.
- Aunque sea tu router, **pide confirmación explícita antes** de apuntarle cualquier herramienta, y hazlo solo sobre equipos tuyos. Nada de escaneo de la LAN ni de hosts externos.
- Lo que sí verás en este Mac: si activas «Compartir ficheros» (SMB, `*:445`) o «Compartir medios», aparecerán en `listening.txt` y en `owners.txt` como `EXPUESTO(todas-las-interfaces)`. Es la señal para revisar si quieres ese servicio abierto a la LAN.
- Esos servicios del Mac se apagan en Ajustes del Sistema → General → Compartir.
