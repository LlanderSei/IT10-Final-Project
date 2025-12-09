#include <Arduino.h>
#include <Servo.h>

// put function declarations here:
int lid_cm = 0;
int fullness_cm = 0;
int fullness_trigPin = 11;
int fullness_echoPin = 10;
int lid_trigPin = 9;
int lid_echoPin = 8;
int servoPin = 7;
int servoPos = 0;
int delayMillis = 100;
bool lidOpen = false;
Servo servo;

long readUltrasonicDistance(int trigPin, int echoPin, String dataName);
void runServo(int lid_distance);
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
  lid_cm = readUltrasonicDistance(lid_trigPin, lid_echoPin, "Lid");
  runServo(lid_cm);
  if (!(lid_cm <= 20 && !(lid_cm <= 0 && !lidOpen)))
  {
    fullness_cm = readUltrasonicDistance(fullness_trigPin, fullness_echoPin, "Fullness");
  }
  delay(delayMillis);
}

// put function definitions here:
long readUltrasonicDistance(int trigPin, int echoPin, String dataName)
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
  long distance = 0.01723 * pulseIn(echoPin, HIGH);
  Serial.print(dataName);
  Serial.print(" Distance: ");
  Serial.print(distance);
  Serial.print("cm");
  Serial.println();
  return distance;
}

void runServo(int cm)
{
  if (cm <= 10)
  {
    for (servoPos; servoPos <= 60; servoPos += 1)
    {
      servo.write(servoPos);
      lidOpen = true;
    }
    return;
  }

  for (servoPos; servoPos >= 0; servoPos -= 1)
  {
    if (servoPos <= 0)
    {
      lidOpen = false;
      break;
    }
  }
}

void printServoPos()
{
  Serial.print("Servo Position: ");
  Serial.print(servoPos);
  Serial.println();
}
