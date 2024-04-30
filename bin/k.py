import os
import signal
import argparse
import os
import signal

def kill_process_by_pid(pid):
  try:
    os.kill(pid, signal.SIGTERM)
    print(f"Process with PID {pid} killed successfully.")
  except OSError as e1:
    print(f"Failed to kill process with PID {pid}. error: {e1}")

    # process not exists
    if e1.errno == 3:
       return

    try:
        print(f"Sent SIGKILL to process with PID {pid} again.")
        os.kill(pid, signal.SIGKILL)
    except OSError as e2:
        print(f"Failed to send SIGKILL to process with PID {pid}. error: {e2}")


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Kill a process by PID")
  parser.add_argument("-p", type=int, nargs='+', help="PID(s) of the process(es) to kill")
  args = parser.parse_args()

  for pid in args.p:
    kill_process_by_pid(pid)
