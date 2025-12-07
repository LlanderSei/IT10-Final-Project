#include <Arduino.h>
#include <Servo.h>

// put function declarations here:
int cm = 0;
int trigPin = 9;
int echoPin = 8;
int servoPin = 7;
int servoPos = 0;
int delayMillis = 100;
Servo servo;

long readUltrasonicDistance();
void runServo(int cm);
void printServoPos();

void setup()
{
  // put your setup code here, to run once:
  servo.attach(servoPin);
  Serial.begin(9600);
}

void loop()
{
  // put your main code here, to run repeatedly:
  runServo(readUltrasonicDistance());
  delay(delayMillis);
}

// put function definitions here:
long readUltrasonicDistance()
{
  pinMode(trigPin, OUTPUT); // Clear the trigger
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  // Sets the trigger pin to HIGH state for 10 microseconds
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  pinMode(echoPin, INPUT);
  // Reads the echo pin, and returns the sound wave travel time in microseconds
  cm = 0.01723 * pulseIn(echoPin, HIGH);
  Serial.print("Distance: ");
  Serial.print(cm);
  Serial.print("cm");
  Serial.println();
  return cm;
}

void runServo(int cm)
{
  if (cm <= 10)
  {
    for (servoPos; servoPos <= 60; servoPos += 1)
    {
      servo.write(servoPos);
    }
    return;
  }

  for (servoPos; servoPos >= 0; servoPos -= 1)
  {
    if (servoPos <= 0)
      break;
  }
}

void printServoPos()
{
  Serial.print("Servo Position: ");
  Serial.print(servoPos);
  Serial.println();
}
