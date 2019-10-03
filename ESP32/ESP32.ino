/*
    Video: https://www.youtube.com/watch?v=oCMOYS71NIU
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleNotify.cpp
    Ported to Arduino ESP32 by Evandro Copercini
    updated by chegewara
   Create a BLE server that, once we receive a connection, will send periodic notifications.
   The service advertises itself as: 4fafc201-1fb5-459e-8fcc-c5c9c331914b
   And has a characteristic of: beb5483e-36e1-4688-b7f5-ea07361b26a8
   The design of creating the BLE server is:
   1. Create a BLE Server
   2. Create a BLE Service
   3. Create a BLE Characteristic on the Service
   4. Create a BLE Descriptor on the characteristic
   5. Start the service.
   6. Start advertising.
   A connect hander associated with the server starts a background task that performs notification
   every couple of seconds.
*/
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <FlowMeter.h>
#include <TM1637Display.h>
const int CLK = 16; //Set the CLK pin connection to the display
const int DIO = 17; //Set the DIO pin connection to the display

FlowMeter Meter = FlowMeter(35);
const unsigned long period = 1000;
float flowVal = 1;
void MeterISR() {
  // let our flow meter count the pulses
  Meter.count();
}


BLEServer* pServer = NULL;
BLECharacteristic *pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
int led_1_blink_time = 1000;
long led_1_last_blink;

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"


class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

TM1637Display display(CLK, DIO);

void setup() {

  Serial.begin(115200);
  attachInterrupt(35, MeterISR, RISING);
  // Create the BLE Device
  BLEDevice::init("Shower Thought");

  display.setBrightness(0x0a);
  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
  // Create a BLE Descriptor
  pCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
  pCharacteristic->setValue(flowVal);
  pCharacteristic->notify();
}
void blink() {
  if ((millis() - led_1_last_blink) >= led_1_blink_time) {
    if (digitalRead(12) == HIGH) {
      digitalWrite(12, LOW);
    } else {
      digitalWrite(12, HIGH);
    }
    Serial.println("blink");
    led_1_last_blink = millis();
  }
}
void loop() {
  Meter.tick(period);
  float _flowVal = Meter.getTotalVolume();
  display.showNumberDecEx(_flowVal * 100, 64);
  Serial.println(flowVal);
  // output some measurement result
   if (!deviceConnected) {
    blink();
  }
  if (deviceConnected ) {


    if (flowVal != _flowVal) {
      flowVal = _flowVal;
      pCharacteristic->setValue(flowVal);
      pCharacteristic->notify();
      Serial.println(flowVal);

    }
  }
  // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("start advertising");

    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) {
    // do stuff here on connecting
    Serial.println("here");


  }
   
  delay(100);
  oldDeviceConnected = deviceConnected;
}
