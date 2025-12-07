import re
import time
import serial
import serial.tools.list_ports
import firebase_admin
from firebase_admin import credentials, db

# ---------- CONFIG ----------
FIREBASE_KEYFILE = "firebase-key.json"  # downloaded service account JSON
FIREBASE_DB_URL = "https://smart-trash-bin-984a8-default-rtdb.asia-southeast1.firebasedatabase.app/"
SERIAL_BAUD = 9600
# If you know the port (Windows: "COM3", Linux: "/dev/ttyUSB0"), set SERIAL_PORT.
# Otherwise leave None and the script will try to auto-detect.
SERIAL_PORT = "COM6"

# Upload settings
UPLOAD_THROTTLE = 0.2   # seconds between uploads (to avoid spamming Firebase)
WRITE_MODE = "set"      # "set" to overwrite latest value, "push" to append historical entries
# ----------------------------

def find_serial_port():
  if SERIAL_PORT:
    return SERIAL_PORT
  ports = list(serial.tools.list_ports.comports())
  for p in ports:
    # Heuristic: Arduino Uno often has "Arduino", "USB-SERIAL", "CH340" in the description
    desc = (p.description or "").lower()
    if "arduino" in desc or "ch340" in desc or "usb-serial" in desc:
      return p.device
  # fallback to first available
  return ports[0].device if ports else None

def parse_distance(line):
  """
  Parse lines like:
    "Distance: 45cm"
    "distance: 12 cm"
    "Distance=78.5 cm"
  Returns numeric value as float, or None on failure.
  """
  m = re.search(r"(-?\d+(\.\d+)?)\s*cm", line, re.IGNORECASE)
  if m:
    return float(m.group(1))
  # try generic number if "cm" missing
  m = re.search(r"(-?\d+(\.\d+)?)", line)
  if m:
    return float(m.group(1))
  return None

def init_firebase():
  cred = credentials.Certificate(FIREBASE_KEYFILE)
  firebase_admin.initialize_app(cred, {
    'databaseURL': FIREBASE_DB_URL
  })

def main():
  port = find_serial_port()
  if not port:
    print("No serial ports found. Plug in the Arduino and try again.")
    return

  print(f"Using serial port: {port}")
  init_firebase()
  ref = db.reference("sensors/ultrasonic")  # change path as you like

  ser = None
  last_upload = 0.0

  while True:
    try:
      if ser is None:
        ser = serial.Serial(port, SERIAL_BAUD, timeout=1)
        print("Serial opened.")
        # give Arduino a second to reset after opening serial
        time.sleep(1.0)

      line = ser.readline().decode(errors="ignore").strip()
      if not line:
        continue

      # Example Arduino line: "Distance: 45cm"
      print("RAW:", line)
      value = parse_distance(line)
      if value is None:
        # nothing parsed — ignore or log
        continue

      now = time.time()
      if now - last_upload < UPLOAD_THROTTLE:
        # skip upload (throttle)
        continue

      payload = {
        "distance_cm": value,
        "ts": int(now)            # unix seconds
      }

      if WRITE_MODE == "set":
        # Overwrite latest
        ref.set(payload)
      else:
        # Append historical record under /sensors/ultrasonic/logs/<push_id>
        ref.child("logs").push(payload)

      print("Uploaded:", payload)
      last_upload = now

    except serial.SerialException as e:
      print("Serial error:", e)
      ser = None
      time.sleep(2)
    except KeyboardInterrupt:
      print("Stopped by user.")
      break
    except Exception as e:
      print("Error:", e)
      # keep running
      time.sleep(0.1)

if __name__ == "__main__":
  main()