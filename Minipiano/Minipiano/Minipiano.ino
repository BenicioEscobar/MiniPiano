//pines y notas musicales PT1
struct  Tecla {
  int pin;
  int frecuencia; 
  bool estadoAnterior;
  unsigned long ultimoCambio;
};
unsigned long inicioSilencio=0;
unsigned long inicioNota=0;
const int pinBuzzer=25;
Tecla piano[8] = {
  {23, 262, false, 0},
  {22, 294, false, 0},
  {21, 330, false, 0},
  {19, 349, false, 0},
  {18, 392, false, 0},
  {5,  440, false, 0},
  {17, 494, false, 0},
  {16, 523, false, 0}
};
// iniciamos tiempos para el debounce PT2

const unsigned long rebounce=50;
void setup() {
  Serial.begin(115200);
  
  for (int i = 0; i < 8; i++) {
    pinMode(piano[i].pin, INPUT_PULLUP); //Iniciamos pulsadores (teclas) PT1
  }
}

void loop() {
  for (int i = 0; i < 8; i++) {
    bool estadoActual = (digitalRead(piano[i].pin) == LOW); //si la tecla está en low, es true(esta siendo presionada) logica pullup
if (estadoActual!=piano[i].estadoAnterior && millis()-piano[i].ultimoCambio>=rebounce) {
  piano[i].ultimoCambio=millis();
 // debounce para los botones, se asegura que el boton fue pulsado o soltado y que el tiempo que haya sido pusado sea mayor a 0,05 seg
    if (estadoActual == true && piano[i].estadoAnterior == false) {
        unsigned long duracionSilencio=millis()-inicioSilencio;
      tone(pinBuzzer, piano[i].frecuencia);
      Serial.print("Silencio,");
      Serial.println(duracionSilencio);
      inicioNota=millis();
    } 
    else if (estadoActual == false && piano[i].estadoAnterior == true) {
      unsigned long duracionNota=millis()-inicioNota;

      noTone(pinBuzzer);

       Serial.println(i);
       Serial.print(",");
       Serial.println(duracionNota);
      inicioSilencio=millis();
    }
        piano[i].estadoAnterior = estadoActual; // Guarda el estado para la próxima vuelta

  }
  }
}