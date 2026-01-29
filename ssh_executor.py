import pty
import os
import subprocess
import sys

def run_ssh_command(command):
    password = "0000"
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp("ssh", ["ssh", "vps", command])
    else:
        output = b""
        while b"password:" not in output.lower():
            chunk = os.read(fd, 1024)
            if not chunk:
                break
            output += chunk
        os.write(fd, (password + "\n").encode())
        while True:
            try:
                chunk = os.read(fd, 1024)
                if not chunk:
                    break
                sys.stdout.buffer.write(chunk)
                sys.stdout.flush()
            except OSError:
                break
        os.waitpid(pid, 0)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    run_ssh_command(sys.argv[1])
