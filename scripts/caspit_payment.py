"""
Caspit Payment Terminal - Send payment request via raw TCP
Usage:
  python caspit_payment.py test [ip]           - Communication test
  python caspit_payment.py [amount] [ip]       - Send payment (amount in agorot)
"""

import sys
import socket
import xml.etree.ElementTree as ET
from datetime import datetime


TERMINAL_ID = "6314813"
TERMINAL_NO = "008"
DEFAULT_IP = "192.168.0.103"
DEFAULT_PORT = 443
TIMEOUT = 30


def build_payment_xml(amount, terminal_id=TERMINAL_ID, terminal_no=TERMINAL_NO):
    request_id = datetime.now().strftime("%Y%m%d%H%M%S%f")[:17]
    return f"""<Request><Command>001</Command><Mti>100</Mti><TerminalId>{terminal_id}</TerminalId><TermNo>{terminal_no}</TermNo><TimeoutInSeconds>90</TimeoutInSeconds><Amount>{amount}</Amount><Currency>376</Currency><CreditTerms>1</CreditTerms><TranType>1</TranType><PanEntryMode>PinPad</PanEntryMode><Xfield>{request_id}</Xfield><RequestId>{request_id}</RequestId></Request>"""


def build_test_xml(terminal_id=TERMINAL_ID, terminal_no=TERMINAL_NO):
    request_id = datetime.now().strftime("%Y%m%d%H%M%S%f")[:17]
    return f"""<Request><Command>003</Command><TerminalId>{terminal_id}</TerminalId><TermNo>{terminal_no}</TermNo><RequestId>{request_id}</RequestId></Request>"""


def build_http_post(ip, port, xml_body, terminal_id=TERMINAL_ID, terminal_no=TERMINAL_NO):
    path = f"/cashregister/request/{terminal_id}/{terminal_no}"
    body = xml_body.encode("utf-8")
    request = (
        f"POST {path} HTTP/1.1\r\n"
        f"Host: {ip}:{port}\r\n"
        f"Content-Type: application/xml\r\n"
        f"Content-Length: {len(body)}\r\n"
        f"Connection: close\r\n"
        f"\r\n"
    ).encode("utf-8") + body
    return request


def send_raw_tcp(ip, port, xml_body):
    print(f"\n{'='*50}")
    print(f"Connecting to: {ip}:{port} (raw TCP)")
    print(f"{'='*50}")
    print(f"XML:\n{xml_body}")
    print(f"{'='*50}\n")

    try:
        import ssl
        raw_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        raw_sock.settimeout(TIMEOUT)
        try:
            ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            sock = ctx.wrap_socket(raw_sock, server_hostname=ip)
            sock.connect((ip, port))
            print(f"Connected (TLS)!")
        except (ssl.SSLError, ConnectionResetError, OSError):
            print("TLS failed, trying plain TCP...")
            raw_sock.close()
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(TIMEOUT)
            sock.connect((ip, port))
            print(f"Connected (plain TCP)!")

        xml_bytes = xml_body.encode("utf-8")
        xml_len = len(xml_bytes)

        # PTL Header: ^PTL!00#<LLLL><TT><FF>
        length_hex = format(xml_len, '04X')
        ptl_header = f"^PTL!00#{length_hex}5202"
        full_message = ptl_header + xml_body
        full_bytes = full_message.encode("utf-8")

        use_ptl = "--no-ptl" not in sys.argv

        if use_ptl:
            path = f"/cashregister/request/{TERMINAL_ID}/{TERMINAL_NO}"
            http_request = (
                f"POST {path} HTTP/1.1\r\n"
                f"Host: {ip}:{port}\r\n"
                f"Content-Type: text/xml; charset=utf-8\r\n"
                f"Content-Length: {len(full_bytes)}\r\n"
                f"\r\n"
            ).encode("utf-8") + full_bytes
            print(f"PTL Header: {ptl_header}")
            print(f"Sending HTTP+PTL+XML ({len(http_request)} bytes)...")
        else:
            path = f"/cashregister/request/{TERMINAL_ID}/{TERMINAL_NO}"
            http_request = (
                f"POST {path} HTTP/1.1\r\n"
                f"Host: {ip}:{port}\r\n"
                f"Content-Type: application/xml\r\n"
                f"Content-Length: {len(xml_bytes)}\r\n"
                f"Connection: close\r\n"
                f"\r\n"
            ).encode("utf-8") + xml_bytes
            print(f"Sending HTTP+XML without PTL ({len(http_request)} bytes)...")
        sock.sendall(http_request)

        response = b""
        sock.settimeout(90)
        try:
            while True:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                response += chunk
        except socket.timeout:
            print("(read timeout after 90s)")
        except Exception as e:
            print(f"(read ended: {e})")

        sock.close()

        response_text = response.decode("windows-1255", errors="replace")
        print(f"\nRaw Response ({len(response)} bytes):")
        print(response_text)

        xml_start = response_text.find("<")
        if xml_start >= 0:
            xml_part = response_text[xml_start:]
            try:
                root = ET.fromstring(xml_part)
                return_code = root.findtext("ReturnCode", "N/A")
                message = root.findtext("Message", "")
                auth_no = root.findtext("AuthorizationNo", "")
                print(f"\n--- Result ---")
                print(f"Return Code: {return_code}")
                if message:
                    print(f"Message: {message}")
                if auth_no:
                    print(f"Authorization: {auth_no}")
            except ET.ParseError:
                pass

        return response_text

    except Exception as e:
        print(f"Error: {e}")
        return None


def main():
    ip = DEFAULT_IP
    port = DEFAULT_PORT

    if len(sys.argv) > 1 and sys.argv[1] == "test":
        ip = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_IP
        print("Sending COMMUNICATION TEST...")
        xml = build_test_xml()
        send_raw_tcp(ip, port, xml)
        return

    amount = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    if len(sys.argv) > 2:
        ip = sys.argv[2]

    print(f"Sending payment: {amount/100:.2f} ILS ({amount} agorot)")
    print(f"Terminal: {ip}:{port}")
    print(f"Terminal ID: {TERMINAL_ID}, Terminal No: {TERMINAL_NO}")

    xml = build_payment_xml(amount)
    send_raw_tcp(ip, port, xml)


if __name__ == "__main__":
    main()
