#include <ArduinoBLE.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <DHT_U.h>

#define DHTPIN 2 
#define DHTTYPE DHT22

DHT_Unified dht(DHTPIN, DHTTYPE);

long previousMillis = 0;

sensors_event_t event; // Lettura sensore di temperature DHT

bool advertiseTemp = true;

int readTemp() {
  dht.temperature().getEvent(&event);
  if (isnan(event.temperature)) {
    Serial.println("Errore nella lettura della temperatura!");
    return -1000;
  } else {
    return (int)(event.temperature * 100);
  }
}

int readHum() {
  dht.humidity().getEvent(&event);
  if (isnan(event.relative_humidity)) {
    Serial.println("Errore nella lettura dell'umidità!");
    return -1000;
  } else {
    return (int)(event.relative_humidity * 100);
  }
}

void setup() {
  Serial.begin(9600); 
  while (!Serial);   

  dht.begin();

  if (!BLE.begin()) {
    Serial.println("Errore avvio di Bluetooth® Low Energy!");
    while (1);
  }

  BLE.setLocalName("AlexaAcademy Sensor"); // Nome che appare quando si fa una scansione dei dispositivi BLE

  BLE.advertise(); // Inizia l'adversite del da parte di questa peripheral
  Serial.println("Inizio broadcasting...");
}

void loop() {
    long currentMillis = millis();
    if (currentMillis - previousMillis >= 5000) { // Invia la temperatura ogni secondo
      previousMillis = currentMillis;

      BLE.stopAdvertise();
      BLEAdvertisingData advData;
      advData.setFlags(BLEFlagsBREDRNotSupported | BLEFlagsGeneralDiscoverable);
      
      int t = readTemp();
      int h = readHum();

      Serial.print("Temperatura: ");
      Serial.print((float)t / 100.0);
      Serial.println("°C");

      Serial.print("Umidità: ");
      Serial.print((float)h / 100.0);
      Serial.println("%");

      unsigned char temperature[2] = {
          (unsigned char)(t & 0xFF),
          (unsigned char)(t >> 8),
      };

      unsigned char humidity[2] = {
          (unsigned char)(h & 0xFF),
          (unsigned char)(h >> 8),
      };

      if (advertiseTemp) {
        advertiseTemp = false;
        advData.setAdvertisedServiceData(0x2A6E, temperature, sizeof(temperature));
        Serial.print("Advertise temp");
      } else {
        advertiseTemp = true;
        advData.setAdvertisedServiceData(0x2A6F, humidity, sizeof(humidity));
         Serial.print("Advertise hum");
      }

      BLE.setAdvertisingData(advData);

      BLE.advertise();
    }
}
