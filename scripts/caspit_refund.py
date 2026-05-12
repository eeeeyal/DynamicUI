"""Send refund (credit) to Caspit terminal"""
import socket
import xml.etree.ElementTree as ET
from datetime import datetime

IP, PORT = "192.168.0.103", 443
TID, TNO = "6314813", "008"


def send_refund(amount=100):
    rid = datetime.now().strftime("%Y%m%d%H%M%S%f")[:17]
    xml = (
        f"<Request><Command>001</Command><Mti>100</Mti>"
        f"<TerminalId>{TID}</TerminalId><TermNo>{TNO}</TermNo>"
        f"<TimeoutInSeconds>90</TimeoutInSeconds>"
        f"<Amount>{amount}</Amount><Currency>376</Currency>"
        f"<CreditTerms>1</CreditTerms><TranType>3</TranType>"
        f"<PanEntryMode>PinPad</PanEntryMode>"
        f"<Xfield>{rid}</Xfield><RequestId>{rid}</RequestId></Request>"
    )
    xb = xml.encode("utf-8")
    lh = format(len(xb), "04X")
    ptl = f"^PTL!00#{lh}5202"
    msg = (ptl + xml).encode("utf-8")
    path = f"/cashregister/request/{TID}/{TNO}"
    http = (
        f"POST {path} HTTP/1.1\r\n"
        f"Host: {IP}:{PORT}\r\n"
        f"Content-Type: text/xml; charset=utf-8\r\n"
        f"Content-Length: {len(msg)}\r\n"
        f"\r\n"
    ).encode("utf-8") + msg

    s = socket.socket()
    s.settimeout(30)
    s.connect((IP, PORT))
    s.sendall(http)
    print(f"Sent refund {amount/100:.2f} ILS - waiting for card...")

    resp = b""
    s.settimeout(90)
    try:
        while True:
            c = s.recv(4096)
            if not c:
                break
            resp += c
    except Exception:
        pass
    s.close()

    text = resp.decode("windows-1255", errors="replace")
    xs = text.find("<")
    if xs >= 0:
        root = ET.fromstring(text[xs:])
        rc = root.findtext("ResultCode", "?")
        ash = root.findtext("AshStatus", "?")
        auth = root.findtext("AuthManpikNo", "")
        print(f"ResultCode: {rc}, AshStatus: {ash}")
        if auth:
            print(f"Auth: {auth}")
        if rc == "0":
            print("REFUND APPROVED!")
        else:
            print("DECLINED")
    else:
        print(f"No XML in response ({len(resp)} bytes)")


if __name__ == "__main__":
    for i in range(1, 4):
        print(f"\n=== Refund #{i} ===")
        send_refund(100)
