const int teclas[8] = {23, 22, 21, 19, 18, 5, 17, 16};
const int frecuencias[8] = {262, 294, 330, 349, 392, 440, 494, 523};
const int pinBuzzer = 25;

bool estadoAnterior[8] = {false};

void setup() {
  Serial.begin(115200);
  for (int i = 0; i < 8; i++) {
    pinMode(teclas[i], INPUT_PULLUP);
  }
}

void loop() {
  for (int i = 0; i < 8; i++) {
    bool estadoActual = (digitalRead(teclas[i]) == LOW);

    if (estadoActual == true && estadoAnterior[i] == false) {
      Serial.println(i);
      tone(pinBuzzer, frecuencias[i]);
    } 
    else if (estadoActual == false && estadoAnterior[i] == true) {
      noTone(pinBuzzer);
    }

    estadoAnterior[i] = estadoActual; // Guarda el estado para la próxima vuelta
  }
}