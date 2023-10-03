
uint8_t hh, mm, ss; //containers for current time

uint8_t conv2d(const char* p)
{
    uint8_t v = 0;
    if ('0' <= *p && *p <= '9') v = *p - '0';
    return 10 * v + *++p - '0';
}

void setup() {
  // put your setup code here, to run once:

    Serial.begin(9600);
    Serial.println("Testing Sprintf");
    char buf[20];
    hh = conv2d(__TIME__);
    mm = conv2d(__TIME__ + 3);
    ss = conv2d(__TIME__ + 6);
    sprintf(buf, "%02d:%02d:%02d", hh, mm, ss);
    Serial.println(buf);
}

void loop() {
  // put your main code here, to run repeatedly:

}
