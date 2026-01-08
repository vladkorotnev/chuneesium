#include <Arduino.h>

// Status LED pin: HIGH when waiting for reply, LOW otherwise
const int LED_PIN   = 17;
// DIR pin of RS485 interface
const int DIR_PIN    = 5;//0:IN 1:OUT
// SENSE pin of JVS interface
const int SENSE_PIN = 4;

void blinkErr(int code) {
  for(int i = 0; i < code; i++) {
    digitalWrite(LED_PIN, LOW);
    delay(250);
    digitalWrite(LED_PIN, HIGH);
    delay(250);
  }
}


void setup() {
  Serial.begin(115200);   //PC(USB)
  Serial1.begin(115200);   //JVS(GP0/GP1)
  pinMode(DIR_PIN, OUTPUT); //0:IN 1:OUT
  pinMode(LED_PIN, OUTPUT);
  pinMode(SENSE_PIN, INPUT);
  digitalWrite(DIR_PIN, LOW);
  blinkErr(2);
}


byte outbuf[256] = {0};
byte inbuf[256] = {0};

byte unescapingRead(Stream &s) {
  while(!s.available()) yield();
  byte rslt = s.read();
  if (rslt == 0xD0) {
    while(!s.available()) yield();
    rslt = s.read() + 1;
  }
  return rslt;
}

void escapingWrite(Stream &s, byte w) {
  if (w == 0xE0 || w == 0xD0) {
    s.write(0xD0);
    s.write(w - 1);
  } else {
    s.write(w);
  }
}

void escapingWriteAll(Stream &s, const byte * buffer, size_t length) {
  for(int i = 0; i < length; i++) escapingWrite(s, buffer[i]);
}

byte checksum(const byte * buffer, size_t length) {
  int rslt = 0;
  for(size_t i = 0; i < length; i++) rslt += buffer[i];
  return (rslt % 0x100);
}

void loop() {
pc_recv:
  outbuf[0] = 0;
  // PC RECV
  while (outbuf[0] != 0xE0) 
  {
    while(!Serial.available()) yield();
    outbuf[0] = Serial.read();
  }
  // node
  outbuf[1] = unescapingRead(Serial);
  // size
  outbuf[2] = unescapingRead(Serial);
  size_t unescaped_len_incl_sum = outbuf[2];
  for(int i = 3; i < unescaped_len_incl_sum + 3; i++) {
    outbuf[i] = unescapingRead(Serial);
  }
  // check checksum
  byte check = checksum(&outbuf[1], unescaped_len_incl_sum + 1);
  byte recvCheck = outbuf[2 + unescaped_len_incl_sum];
  if(check != recvCheck) {
    blinkErr(3);
    goto pc_recv;
  }

  if (outbuf[1] == 0xFF && outbuf[3] == 0xF0, outbuf[4] == 0xD9) {
    // reset, no response
    blinkErr(2);
    goto pc_recv;
  }

  // SEND to jvs
  digitalWrite(DIR_PIN, HIGH);
  Serial1.write(outbuf[0]);
  escapingWriteAll(Serial1, &outbuf[1], unescaped_len_incl_sum + 2);
  Serial1.flush();
  digitalWrite(DIR_PIN, LOW);
  digitalWrite(LED_PIN, HIGH);

  inbuf[0] = 0;
  while(inbuf[0] != 0xE0) {
    while(!Serial1.available()) yield();
    inbuf[0] = Serial1.read();
  }
  // node
  inbuf[1] = unescapingRead(Serial1);
  // size
  inbuf[2] = unescapingRead(Serial1);
  size_t unescaped_input_len_incl_sum = inbuf[2];
  for(int i = 3; i < unescaped_input_len_incl_sum + 3; i++) {
    inbuf[i] = unescapingRead(Serial1);
  }
  check = checksum(&inbuf[1], unescaped_input_len_incl_sum + 1);
  recvCheck = inbuf[2 + unescaped_input_len_incl_sum];
  if(check != recvCheck) {
    blinkErr(5);
  }
  Serial.write(inbuf[0]);
  escapingWriteAll(Serial, &inbuf[1], unescaped_input_len_incl_sum + 2);
  Serial.flush();
  digitalWrite(LED_PIN, LOW);
  yield();
}
