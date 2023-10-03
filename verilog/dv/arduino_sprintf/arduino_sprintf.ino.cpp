#include <Arduino.h>

uint8_t hh, mm, ss; //containers for current time

uint8_t conv2d(const char* p);
void setup();
void loop();
uint8_t conv2d(const char* p)
{
    uint8_t v = 0;
    if ('0' <= *p && *p <= '9') v = *p - '0';
    return 10 * v + *++p - '0';
}

void setup() {
  // put your setup code here, to run once:

    Serial.begin(1152000);
    Serial.println("Testing Sprintf");
    char buf[20];
    hh = 10; // conv2d(__TIME__);
    mm = 11; // conv2d(__TIME__ + 3);
    ss = 12; // conv2d(__TIME__ + 6);
    sprintf(buf, "%02d:%02d:%02d", hh, mm, ss);
    Serial.println(buf);
}

void loop() {
  // put your main code here, to run repeatedly:

}

