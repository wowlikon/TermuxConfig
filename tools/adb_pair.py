import os

os.system("adb disconnect")
port = input("port: ")
os.system(f"adb pair localhost:{port}")
port = input("port: ")
os.system("adb connect:{port}")

os.system("adb tcpip 5555")
os.system(f"adb disconnect localhost:{port}")
os.system("adb connect localhost")
