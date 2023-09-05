#include <Wire.h>
#include "MAX30100_PulseOximeter.h"
#include <ArduinoBLE.h>

BLEService bleService("8ee10201-ce06-438a-9e59-549e3a39ba35"); // Service

BLEShortCharacteristic blePulse("5ccbbe29-e92d-4a1e-9596-f1a8028091f8", BLERead | BLENotify);    // Pulsazioni
BLEShortCharacteristic bleOximetry("14e07ff9-3def-4338-9749-a5bc33a7603f", BLERead | BLENotify);      // Saturazione
BLEByteCharacteristic bleCommand("bf789fb6-f22d-43b5-bf9e-d5a166a86afa", BLERead | BLEWrite | BLENotify);   // Comandi

#define BLUE_PIN 1

bool isBlueLedBlinking = true;
bool blueLedState = HIGH; 

long previousMillis = 0;

unsigned long previousBlueLedMillis = 0;
unsigned long currentMillis = 0;
long blueLedBlinkInterval = 600;

#define REPORTING_PERIOD_MS     5000
// PulseOximeter is the higher level interface to the sensor
// it offers:
//  * beat detection reporting
//  * heart rate calculation
//  * SpO2 (oxidation level) calculation
PulseOximeter pox;

uint32_t tsLastReport = 0;

bool performingMesure = false;

bool isConnected = false;

BLEDevice central;

byte isPulse = 0;

void onBeatDetected() {
  if (performingMesure) {
    Serial.println("Beat!");
  
    if (isPulse == 0) {
      isPulse = 1;
    } else {
       isPulse = 0;
    }

    if (isConnected) {
      bleCommand.writeValue(isPulse);
    }
  }
}

void setup() {
  Serial.begin(9600);

  pinMode(BLUE_PIN, OUTPUT);
  
  if (!BLE.begin()) {
    Serial.println("starting Bluetooth® Low Energy failed!");
    while (1);
  }

  BLE.setLocalName("AA Pulse Oximeter");
  BLE.setAdvertisedService(bleService);

  bleService.addCharacteristic(blePulse); 
  bleService.addCharacteristic(bleOximetry);
  bleService.addCharacteristic(bleCommand);

  BLE.addService(bleService);

  blePulse.writeValue(0); 
  bleOximetry.writeValue(0);
  bleCommand.writeValue(0);

  BLE.advertise();
  Serial.println("Dispositivo Bluetooth attivo, in attesa di connessioni...");
  
  if (!pox.begin()) {
    Serial.println("FAILED");
    for (;;);
  } else {
    Serial.println("SUCCESS");
  }

  // The default current for the IR LED is 50mA and it could be changed
  //   by uncommenting the following line. Check MAX30100_Registers.h for all the
  //   available options.
  pox.setIRLedCurrent(MAX30100_LED_CURR_7_6MA);
  // Register a callback for the beat detection
  pox.setOnBeatDetectedCallback(onBeatDetected);
}

void blinkCycle() {
  if (!isBlueLedBlinking) return;

  if (currentMillis - previousBlueLedMillis >= blueLedBlinkInterval) {
    previousBlueLedMillis = currentMillis;

    if (blueLedState == LOW) {
      blueLedState = HIGH;
    } else {
      blueLedState = LOW;
    }

    digitalWrite(BLUE_PIN, blueLedState);
  }
}

void performeMesure() {
  int bpm = 0;
  int spo2 = 0;
  // Asynchronously dump heart rate and oxidation levels to the serial
  // For both, a value of 0 means "invalid"
  if (millis() - tsLastReport > REPORTING_PERIOD_MS) {
    Serial.print("Heart rate:");
    bpm = pox.getHeartRate();
    spo2 = pox.getSpO2();
    Serial.println(bpm);
    blePulse.writeValue(bpm);

    Serial.print("SpO2:");
    Serial.print(spo2);
    Serial.println("%");
    bleOximetry.writeValue(spo2);
    
    tsLastReport = millis();
  }
}

void loop() {
  pox.update();

  currentMillis = millis();
  
  blinkCycle();

  if (performingMesure) {
    performeMesure();
  }

  if (!isConnected) {
    central = BLE.central(); // wait for a Bluetooth® Low Energy central
  }

  if (central.connected()) {  // if a central is connected to the peripheral
    isConnected = true;
    isBlueLedBlinking = false;
    digitalWrite(BLUE_PIN, HIGH);

    if (bleCommand.written()) {
      if (bleCommand.value()) {   // any value other than 0
        digitalWrite(LED_BUILTIN, HIGH);         // will turn the LED on
        performingMesure = true;
      } else {                              // a 0 value
        digitalWrite(LED_BUILTIN, LOW);          // will turn the LED off
        performingMesure = false;
      }
    }
  } else {
    isBlueLedBlinking = true;
    isConnected = false;
    performingMesure = false;
    digitalWrite(LED_BUILTIN, LOW);
  }
}
