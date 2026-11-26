//pines y notas musicales PT1
struct  Tecla {
  int pin;
  int frecuencia; 
  bool estadoAnterior;
  unsigned long ultimoCambio;
};
struct Nodo {
  int frecuencia;          
  unsigned long duracion;  
  Nodo* siguiente;         // estructura para la grabación
};
Nodo *inicio= nullptr; // puntero a la primer lista
Nodo *fin= nullptr; // puntero al final de la lista 
unsigned long inicioSilencio=0;
unsigned long inicioNota=0;
const int pinBuzzer=4;
Tecla piano[8] = {
  {23, 262, false, 0},
  {22, 294, false, 0},
  {21, 330, false, 0},
  {19, 349, false, 0},
  {18, 392, false, 0},
  {5,  440, false, 0},
  {17, 494, false, 0},
  {16, 523, false, 0}
}; //estructura declarada del piano para las teclas
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
if (estadoActual!=piano[i].estadoAnterior && millis()-piano[i].ultimoCambio>=rebounce) // la tecla esta siendo pulsada
{
  piano[i].ultimoCambio=millis();
 // debounce para los botones, se asegura que el boton fue pulsado o soltado y que el tiempo que haya sido pusado sea mayor a 0,05 seg
    if (estadoActual == true && piano[i].estadoAnterior == false) {
     if (inicioSilencio>0) {  
      unsigned long duracionSilencio=millis()-inicioSilencio; 
      agregarNodo(0,duracionSilencio);
       Serial.print("Silencio,");
      Serial.println(duracionSilencio);
     }
     tone(pinBuzzer, piano[i].frecuencia);
    
      inicioNota=millis(); // iniciamos la cuenta de duracion de la nota, y contamos el silencio de la nota anterior
    } 
    else if (estadoActual == false && piano[i].estadoAnterior == true) // la tecla dejo de ser pulsada
     {
      unsigned long duracionNota=millis()-inicioNota;

      noTone(pinBuzzer);
      agregarNodo(piano[i].frecuencia,duracionNota);
       Serial.println(i);
       Serial.print(",");
       Serial.println(duracionNota);
      inicioSilencio=millis(); // iniciamos la cuenta de duracion del silencio y contamos la duracion de la nota anterior
    }
        piano[i].estadoAnterior = estadoActual; // Guarda el estado para la próxima vuelta

  }
  }
  if (Serial.available() > 0) {
    char comando = Serial.read();
    if (comando == 'p') {
      reproducirMelodia();
    } else if (comando == 'b') {
      borrarMelodia();
    }
    else if (comando == 'l') {
      loopearMelodia();
    }
} }
void agregarNodo (int frecuencia, unsigned long duracion) {
  Nodo *nuevo=new Nodo {frecuencia, duracion, nullptr};
  if(inicio==nullptr){
    inicio=nuevo;
    fin=nuevo;
  } else {
    fin->siguiente=nuevo;
    fin = nuevo;
  }
}
void reproducirMelodia () {
  Nodo *aux=inicio;
while (aux != nullptr) {
    if (aux->frecuencia > 0) {
      tone(pinBuzzer, aux->frecuencia);
    } else {
      noTone(pinBuzzer);
    }
    delay(aux->duracion);
    aux=aux->siguiente;

}
noTone(pinBuzzer); 
}
void borrarMelodia() {
  while (inicio != nullptr) {
    Nodo* aux = inicio;
    inicio = inicio->siguiente;
    delete aux;
  }
  fin = nullptr;
  inicioSilencio = 0;
  Serial.println("Melodia borrada.");
}
void loopearMelodia() {
  if (inicio == nullptr) return; // Si no grabaste nada, sale directo

  bool loopeando = true;
  Nodo* aux = inicio;

  while (loopeando) {
    if (aux->frecuencia > 0) {
      tone(pinBuzzer, aux->frecuencia);
    } else {
      noTone(pinBuzzer);
    }
    delay(aux->duracion);

    aux = aux->siguiente;
    if (aux == nullptr) {
    aux=inicio;    
    }

    if (Serial.available() > 0 && Serial.read() == 's') {
      loopeando=false;
    }
  }

  noTone(pinBuzzer);
}