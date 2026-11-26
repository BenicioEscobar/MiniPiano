import processing.serial.*;

Serial puerto;
String estadoConexion = "SIN CONEXION (MODO DEMO)";
String modoActual = "LISTO";
String ultimoEvento = "Esperando notas...";

// Datos de las 8 teclas (coinciden con tu arreglo piano[8])
String[] nombresNotas = {"DO", "RE", "MI", "FA", "SOL", "LA", "SI", "DO5"};
int[] frecuencias     = {262, 294, 330, 349, 392, 440, 494, 523};
color[] colores       = {
  #38BDF8, #60A5FA, #818CF8, #A78BFA,
  #C084FC, #E879F9, #F472B6, #FB7185
};

float[] brilloTecla = new float[8];
ArrayList<Evento> historial = new ArrayList<Evento>();

class Evento {
  int tecla;          // -1 si es silencio, 0..7 si es nota
  int duracion;
  Evento(int t, int d) {
    tecla = t;
    duracion = d;
  }
}

void setup() {
  size(920, 560);
  smooth(8);
  textFont(createFont("SansSerif", 14, true));

  // Muestra los puertos disponibles en la consola de Processing
  String[] puertos = Serial.list();
  printArray(puertos);

  if (puertos.length > 0) {
    // Si tu ESP32 no es el [0], reemplazá puertos[0] por ejemplo por "COM3"
    String puertoElegido = puertos[0];
    try {
      puerto = new Serial(this, puertoElegido, 115200);
      puerto.bufferUntil('\n');
      estadoConexion = "CONECTADO (" + puertoElegido + ")";
    } catch (Exception e) {
      estadoConexion = "PUERTO OCUPADO (CERRA ARDUINO)";
    }
  }
}

void draw() {
  background(#0F172A);
  dibujarHeader();
  dibujarPianoRoll();
  dibujarTeclas();
  dibujarControles();
}

void dibujarHeader() {
  fill(#1E293B);
  noStroke();
  rect(0, 0, width, 70);

  // Título
  fill(#F8FAFC);
  textAlign(LEFT, CENTER);
  textSize(20);
  text("ESP32 MINI PIANO", 32, 28);

  fill(#94A3B8);
  textSize(12);
  text(estadoConexion, 32, 50);

  // Badge de estado (LISTO / REPRODUCIENDO / LOOPEANDO)
  color cBadge = modoActual.equals("LOOPEANDO") ? #8B5CF6 :
                 modoActual.equals("REPRODUCIENDO") ? #10B981 : #334155;
  fill(cBadge);
  rect(width - 200, 19, 168, 32, 16);
  fill(#F8FAFC);
  textAlign(CENTER, CENTER);
  textSize(12);
  text(modoActual, width - 116, 35);
}

void dibujarPianoRoll() {
  // Tarjeta contenedora
  fill(#1E293B);
  stroke(#334155);
  strokeWeight(1);
  rect(32, 90, 856, 155, 14);

  // Encabezado del Piano Roll
  noStroke();
  fill(#94A3B8);
  textAlign(LEFT, CENTER);
  textSize(11);
  text("LINEA DE TIEMPO (NODOS EN RAM)", 48, 110);

  int totalNodos;
  synchronized (historial) {
    totalNodos = historial.size();
  }
  textAlign(RIGHT, CENTER);
  text(totalNodos + " eventos", 872, 110);

  // Líneas guía horizontales
  float tx = 48, ty = 128, tw = 824, th = 102;
  stroke(#283548);
  for (int i = 0; i < 8; i++) {
    float ly = map(i, 0, 7, ty + th - 8, ty + 8);
    line(tx, ly, tx + tw, ly);
  }

  // Dibujar bloques de notas de derecha a izquierda (siempre muestra lo más nuevo)
  noStroke();
  synchronized (historial) {
    if (historial.isEmpty()) {
      fill(#64748B);
      textAlign(CENTER, CENTER);
      textSize(13);
      text("Toca alguna tecla en tu ESP32 para empezar a grabar...", width / 2, ty + th / 2);
      return;
    }

    float cursorX = tx + tw;
    for (int i = historial.size() - 1; i >= 0; i--) {
      Evento ev = historial.get(i);
      float wBlock = constrain(ev.duracion * 0.08, 12, 130);
      cursorX -= (wBlock + 4);
      if (cursorX < tx) break;

      if (ev.tecla == -1) {
        // Silencio
        fill(#334155);
        rect(cursorX, ty + th - 6, wBlock, 4, 2);
      } else {
        // Nota ubicada según su altura musical
        float ny = map(ev.tecla, 0, 7, ty + th - 16, ty + 2);
        fill(colores[ev.tecla]);
        rect(cursorX, ny, wBlock, 12, 6);
      }
    }
  }
}

void dibujarTeclas() {
  float startX = 33;
  float y = 268;
  float w = 98;
  float h = 165;
  float gap = 10;

  for (int i = 0; i < 8; i++) {
    float x = startX + i * (w + gap);

    // Suavizado del destello al tocar una tecla
    brilloTecla[i] = max(0, brilloTecla[i] - 0.035);

    // Fondo de la tecla
    color base = lerpColor(#1E293B, colores[i], brilloTecla[i] * 0.65);
    fill(base);
    stroke(lerpColor(#334155, colores[i], brilloTecla[i]));
    strokeWeight(1.5);
    rect(x, y, w, h, 14);

    // Barra superior de color
    noStroke();
    fill(colores[i], 140 + brilloTecla[i] * 115);
    rect(x + 14, y + 12, w - 28, 6, 3);

    // Nombre de la nota
    fill(#F8FAFC);
    textAlign(CENTER, CENTER);
    textSize(24);
    text(nombresNotas[i], x + w / 2, y + 84);

    // Frecuencia e índice
    fill(#94A3B8);
    textSize(12);
    text(frecuencias[i] + " Hz", x + w / 2, y + 120);
    textSize(10);
    text("TECLA " + i, x + w / 2, y + 142);
  }
}

void dibujarControles() {
  dibujarBoton(32,  468, 118, 52, "PLAY [P]",   #10B981);
  dibujarBoton(162, 468, 118, 52, "LOOP [L]",   #8B5CF6);
  dibujarBoton(292, 468, 118, 52, "STOP [S]",   #F59E0B);
  dibujarBoton(422, 468, 118, 52, "BORRAR [B]", #EF4444);

  // Tarjeta de telemetría
  fill(#1E293B);
  stroke(#334155);
  strokeWeight(1);
  rect(560, 468, 328, 52, 12);

  noStroke();
  fill(#94A3B8);
  textAlign(LEFT, CENTER);
  textSize(10);
  text("ULTIMO EVENTO", 576, 484);

  fill(#F8FAFC);
  textSize(13);
  text(ultimoEvento, 576, 504);
}

void dibujarBoton(float x, float y, float w, float h, String texto, color acento) {
  boolean hover = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  fill(hover ? acento : #1E293B);
  stroke(acento);
  strokeWeight(1.5);
  rect(x, y, w, h, 12);

  fill(#F8FAFC);
  textAlign(CENTER, CENTER);
  textSize(12);
  text(texto, x + w / 2, y + h / 2);
}

void mousePressed() {
  if (mouseY >= 468 && mouseY <= 520) {
    if (mouseX >= 32  && mouseX <= 150) enviarComando('p');
    if (mouseX >= 162 && mouseX <= 280) enviarComando('l');
    if (mouseX >= 292 && mouseX <= 410) enviarComando('s');
    if (mouseX >= 422 && mouseX <= 540) enviarComando('b');
  }
}

void keyPressed() {
  char k = Character.toLowerCase(key);
  if (k == 'p' || k == 'l' || k == 's' || k == 'b') {
    enviarComando(k);
  }
}

void enviarComando(char cmd) {
  if (puerto != null) puerto.write(cmd);

  if (cmd == 'p') modoActual = "REPRODUCIENDO";
  else if (cmd == 'l') modoActual = "LOOPEANDO";
  else if (cmd == 's') modoActual = "LISTO";
  else if (cmd == 'b') {
    modoActual = "LISTO";
    synchronized (historial) { historial.clear(); }
    ultimoEvento = "Memoria borrada";
  }
}

void serialEvent(Serial p) {
  String linea = p.readStringUntil('\n');
  if (linea == null) return;
  linea = trim(linea);
  if (linea.length() == 0) return;

  if (linea.equals("Melodia borrada.")) {
    synchronized (historial) { historial.clear(); }
    ultimoEvento = "Memoria borrada por ESP32";
    return;
  }

  String[] partes = split(linea, ',');
  if (partes.length != 2) return;

  try {
    int duracion = Integer.parseInt(trim(partes[1]));
    if (partes[0].equals("Silencio")) {
      synchronized (historial) { historial.add(new Evento(-1, duracion)); }
      ultimoEvento = "Silencio (" + duracion + " ms)";
    } else {
      int indice = Integer.parseInt(trim(partes[0]));
      if (indice >= 0 && indice < 8) {
        brilloTecla[indice] = 1.0;
        synchronized (historial) { historial.add(new Evento(indice, duracion)); }
        ultimoEvento = nombresNotas[indice] + " (" + frecuencias[indice] + " Hz) - " + duracion + " ms";
      }
    }
  } catch (Exception e) {
    // Ignora mensajes de arranque del ESP32
  }
}
