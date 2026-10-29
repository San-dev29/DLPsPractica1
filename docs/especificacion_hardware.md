# Especificación de Hardware (Esquemático)

Esta especificación detalla las características eléctricas, lógica de control y componentes del circuito para su interpretación por agentes de generación de código o desarrollo.

---

## 1. Entradas Lógicas (Switches y Pulsadores)

| Línea / Etiqueta | Polaridad Lógica | Componente Físico | Configuración / Descripción Eléctrica |
| :--- | :--- | :--- | :--- |
| $E[7..0]$ | **Active HIGH** | DIP Switch de 8 posiciones ($S1$) | Pull-down externo con resistencias de $47\text{ k}\Omega$ a GND. Alimentación a $V_{CC} = 3.3\text{V}$.<br>• Estado OFF = `'0'` ($0\text{V}$)<br>• Estado ON = `'1'` ($3.3\text{V}$) |
| $E[19..16]$ | **Active HIGH** | 4 Push Buttons (Pulsadores) | Pull-down externo de $47\text{ k}\Omega$ a GND.<br>• En reposo = `'0'`<br>• Presionado = `'1'`<br>*Nota: Requiere desacoplo/debounce por software o lógica interna.* |

---

## 2. Indicadores Visuales y Audio

| Línea / Etiqueta | Polaridad Lógica | Componente Físico | Configuración / Descripción Eléctrica |
| :--- | :--- | :--- | :--- |
| $S[7..0]$ | **Active HIGH** | Barra de 8 LEDs ($LED1$) | Resistencia limitadora en serie de $470\Omega$ a GND por cada segmento.<br>• `'1'` = LED Encendido<br>• `'0'` = LED Apagado |
| $S[19..16]$ | **Active HIGH** | 4 LEDs individuales ($LED3 - LED6$) | Resistencia limitadora en serie de $470\Omega$ conectada a GND.<br>• `'1'` = LED Encendido<br>• `'0'` = LED Apagado |
| $S20$, $S21$ | **Active HIGH** | Buzzers ($BUZ1$, $BUZ2$) | Conexión directa a elementos sonoros.<br>• Generación de tono mediante conmutación lógica de la señal. |

---

## 3. Displays de 7 Segmentos Multiplexados

| Línea / Etiqueta | Polaridad Lógica | Función / Componente | Configuración / Descripción Eléctrica |
| :--- | :--- | :--- | :--- |
| $S[35..28]$ | **Active HIGH** | Bus de Segmentos ($A-G, DP$) | Conexión a segmentos con resistencia limitadora de $470\Omega$ en serie.<br>• Orden: $S28 = A, S29 = B, \dots, S34 = G, S35 = DP$. |
| $S[25..22]$ | **Active HIGH** | Selección/Habilitación de Dígito | Control mediante transistores NPN ($BC547$) en configuración de conmutación con resistencia de base de $4.7\text{ k}\Omega$.<br>• Un nivel `'1'` activa la base del transistor, conectando el cátodo común del dígito correspondiente a GND. |