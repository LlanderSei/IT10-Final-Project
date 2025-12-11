import re
import time
import serial
import serial.tools.list_ports
import firebase_admin
from firebase_admin import credentials, db

# ---------- CONFIG ----------
FIREBASE_KEYFILE = "firebase-key.json"
FIREBASE_DB_URL = "https://smart-trash-bin-984a8-default-rtdb.asia-southeast1.firebasedatabase.app/"
SERIAL_BAUD = 9600
# Set SERIAL_PORT to "COM6" or "/dev/ttyUSB0" if you know it; otherwise leave None for auto-detect.
SERIAL_PORT = None

# Upload policy
UPLOAD_THROTTLE_S = 0.25   # minimum seconds between uploads per sensor
WRITE_MODE = "set"         # "set" to overwrite latest, "push" to append to logs
DB_PATH = "sensors"        # base path in RTDB
# ----------------------------

LINE_RE = re.compile(r"(Lid|Fullness)\s*Distance\s*:\s*(-?\d+(\.\d+)?)\s*cm", re.IGNORECASE)

def find_serial_port():
  if SERIAL_PORT:
    return SERIAL_PORT
  ports = list(serial.tools.list_ports.comports())
  for p in ports:
    desc = (p.description or "").lower()
    if "arduino" in desc or "ch340" in desc or "usb-serial" in desc:
      return p.device
  return ports[0].device if ports else None

def init_firebase():
  cred = credentials.Certificate(FIREBASE_KEYFILE)
  firebase_admin.initialize_app(cred, {
    'databaseURL': FIREBASE_DB_URL
  })

def parse_line(line):
  """
  Returns tuple (sensor_name, value_float) or (None, None) if no match.
  e.g. "Lid Distance: 6cm" -> ("Lid", 6.0)
  """
  m = LINE_RE.search(line)
  if not m:
    return None, None
  name = m.group(1).strip().lower()   # "lid" or "fullness"
  val = float(m.group(2))
  return name, val

def main():
  port = find_serial_port()
  if not port:
    print("No serial port detected. Plug in Arduino and try again.")
    return

  print(f"Using serial port: {port}")
  init_firebase()
  base_ref = db.reference(DB_PATH)

  ser = None
  last_upload = {"lid": 0.0, "fullness": 0.0}

  while True:
    try:
      if ser is None:
        ser = serial.Serial(port, SERIAL_BAUD, timeout=1)
        print("Serial opened.")
        time.sleep(1.0)  # allow Arduino reset

      raw = ser.readline().decode(errors="ignore").strip()
      if not raw:
        continue

      print("RAW:", raw)
      sensor, value = parse_line(raw)
      if sensor is None:
        # Unrecognized line; ignore
        continue

      now = time.time()
      if now - last_upload.get(sensor, 0) < UPLOAD_THROTTLE_S:
        # throttled
        continue

      payload = {
        "value_cm": value,
        "ts": int(now)
      }

      if WRITE_MODE == "set":
        # overwrite latest
        base_ref.child(sensor).set(payload)
      else:
        # push historical log
        base_ref.child(sensor).child("logs").push(payload)

      print(f"Uploaded {sensor}: {payload}")
      last_upload[sensor] = now

    except serial.SerialException as e:
      print("Serial error:", e)
      ser = None
      time.sleep(2)
    except KeyboardInterrupt:
      print("Stopped by user.")
      break
    except Exception as e:
      print("Error:", e)
      time.sleep(0.1)

if __name__ == "__main__":
  main()
