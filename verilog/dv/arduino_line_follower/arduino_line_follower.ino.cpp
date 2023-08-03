#include <Arduino.h>
#line 1 "/home/dinesha/workarea/opencore/git/riscduino_bringup/2206Q/tests/btest_line_follower/btest_line_follower.ino"
/*************************************************************
  Connection Setting of RoboMart Line Follower Development Kit
  Reference: https://www.scribd.com/document/238827643/User-Manual-IBOT-Mini-V3#

LEDs  ---@----------------> PB1  - D9       -->  Output
LEDs  ---@----------------> PB2  - D10      -->  Output
LEDs  ---@----------------> PB3  - D11      -->  Output
LEDs  ---@----------------> PB4  - D12      -->  Output
Left Sensor  -------------> PC3 -  A3/D17   -->  Input
Right Sensor -------------> PC0 -  A0/D14   -->  Input
Buzzer       -------------> PD4 -  D4       ---> Output
Right Motor (+) ----------> PB1  - D9       ---> Output
Right Motor (-) ----------> PB2  - D10      ---> Output
Left Motor (-) ---------->  PB3  - D11      ---> Output
Left Motor (+) ---------->  PB4  - D12      ---> Output
Buzzer          ----------> PD4  - D4       ---> Output
RESET --------------------> PC6  - RESET
Crystall Oscialltor (12Mhz) --> PB6 and PB7
VB = Battery Supply
VCC = Regulated 5V+
Gnd = Gnd (0V)
*************************************************************/
#define RIGHT_MOTOR_P  9
#define RIGHT_MOTOR_N  10
#define LEFT_MOTOR_N   11
#define LEFT_MOTOR_P   12
#define LEFT_SENSOR    17
#define RIGHT_SENSOR   14
#define BUZZER         4

int BuzzerValue=0x00;

#line 33 "/home/dinesha/workarea/opencore/git/riscduino_bringup/2206Q/tests/btest_line_follower/btest_line_follower.ino"
void setup();
#line 50 "/home/dinesha/workarea/opencore/git/riscduino_bringup/2206Q/tests/btest_line_follower/btest_line_follower.ino"
void loop();
#line 33 "/home/dinesha/workarea/opencore/git/riscduino_bringup/2206Q/tests/btest_line_follower/btest_line_follower.ino"
  void setup() {
  // put your setup code here, to run once:
  // Motor
    pinMode(RIGHT_MOTOR_P, OUTPUT);
    pinMode(RIGHT_MOTOR_N, OUTPUT);
    pinMode(LEFT_MOTOR_N, OUTPUT);
    pinMode(LEFT_MOTOR_P, OUTPUT);

  // Buzer
    pinMode(BUZZER, OUTPUT);
    // Sensor
    pinMode(LEFT_SENSOR, INPUT);
    pinMode(RIGHT_SENSOR, INPUT);


}

void loop() {
  // put your main code here, to run repeatedly:
  int LeftSensorVal = digitalRead(LEFT_SENSOR);
  int RightSensorVal = digitalRead(RIGHT_SENSOR);

 // When both Sensor Off , Then Stop Motor
 if(LeftSensorVal ==0 && RightSensorVal == 0){
    digitalWrite(RIGHT_MOTOR_P, HIGH);
    digitalWrite(RIGHT_MOTOR_N, HIGH);
    digitalWrite(LEFT_MOTOR_N, HIGH);
    digitalWrite(LEFT_MOTOR_P, HIGH);
    BuzzerValue = LOW;

  }

      // Turn Right
 if(LeftSensorVal ==0 && RightSensorVal == 1){
    digitalWrite(RIGHT_MOTOR_P, LOW);
    digitalWrite(RIGHT_MOTOR_N, LOW);
    digitalWrite(LEFT_MOTOR_N, LOW);
    digitalWrite(LEFT_MOTOR_P, HIGH);
    BuzzerValue = HIGH;
 }

        // Turn Left
 if(LeftSensorVal ==1 && RightSensorVal == 0){
    digitalWrite(RIGHT_MOTOR_P, HIGH);
    digitalWrite(RIGHT_MOTOR_N, LOW);
    digitalWrite(LEFT_MOTOR_N, LOW);
    digitalWrite(LEFT_MOTOR_P, LOW);
    BuzzerValue = HIGH;
  }

  // Turn Move Forward
 if(LeftSensorVal ==1 && RightSensorVal == 1){
    digitalWrite(RIGHT_MOTOR_P, HIGH);
    digitalWrite(RIGHT_MOTOR_N, LOW);
    digitalWrite(LEFT_MOTOR_N, LOW);
    digitalWrite(LEFT_MOTOR_P, HIGH);
    BuzzerValue = ~BuzzerValue;
  }
  digitalWrite(BUZZER, BuzzerValue);

}

