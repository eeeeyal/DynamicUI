"""
Caspit Terminal Web Server
Flask backend for communicating with Caspit/Ingenico payment terminal
"""
import socket
import xml.etree.ElementTree as ET
from datetime import datetime
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import json

app = Flask(__name__)
CORS(app)

TERMINAL_CONFIG = {
    "ip": "192.168.0.103",
    "port": 443,
    "terminalId": "6314813",
    "termNo": "008",
    "timeout": 30,
}

TRAN_TYPES = {1: "רגיל", 2: "טלפוני", 3: "זיכוי", 4: "טלפוני+CVV", 5: "אינטרנט", 6: "מיידי", 11: "הקלדה ידנית"}
CREDIT_TERMS = {1: "רגיל", 2: "קרדיט", 3: "תשלומים", 4: "תשלומים+קרדיט", 6: "תשלומים+דחיה", 8: "תשלומים+קרדיט+דחיה"}
COMMANDS = {
    "001": "עסקה", "002": "JENR", "003": "בדיקת תקשורת", "005": "TOTAL",
    "006": "שידור לשב״א", "007": "TRAN", "008": "DATA", "012": "שאילתת עסקה",
    "013": "הגדרות מסוף", "014": "STATIS", "015": "דוח הפקדה", "023": "החלקת כרטיס"
}

transaction_log = []


def generate_request_id():
    return datetime.now().strftime("%Y%m%d%H%M%S%f")[:17]


def send_to_terminal(xml_body):
    """Send XML request to terminal via raw TCP with PTL header"""
    cfg = TERMINAL_CONFIG
    ip, port = cfg["ip"], cfg["port"]

    xml_bytes = xml_body.encode("utf-8")
    length_hex = format(len(xml_bytes), "04X")
    ptl_header = f"^PTL!00#{length_hex}5202"
    full_message = (ptl_header + xml_body).encode("utf-8")

    path = f"/cashregister/request/{cfg['terminalId']}/{cfg['termNo']}"
    http_request = (
        f"POST {path} HTTP/1.1\r\n"
        f"Host: {ip}:{port}\r\n"
        f"Content-Type: text/xml; charset=utf-8\r\n"
        f"Content-Length: {len(full_message)}\r\n"
        f"\r\n"
    ).encode("utf-8") + full_message

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(cfg["timeout"])

    try:
        sock.connect((ip, port))
    except (ConnectionRefusedError, socket.timeout, OSError) as e:
        return {"error": f"Connection failed: {e}", "connected": False}

    sock.sendall(http_request)

    response = b""
    sock.settimeout(120)
    try:
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            response += chunk
    except socket.timeout:
        pass
    except Exception:
        pass
    finally:
        sock.close()

    response_text = response.decode("windows-1255", errors="replace")
    xml_start = response_text.find("<")
    if xml_start < 0:
        return {"error": "No XML in response", "raw": response_text, "rawLength": len(response)}

    xml_part = response_text[xml_start:]
    try:
        root = ET.fromstring(xml_part)
        result = {}
        for elem in root:
            if len(elem) > 0:
                result[elem.tag] = ET.tostring(elem, encoding="unicode")
            else:
                result[elem.tag] = elem.text or ""
        return result
    except ET.ParseError as e:
        return {"error": f"XML parse error: {e}", "raw": xml_part[:1000]}


def build_transaction_xml(params):
    cfg = TERMINAL_CONFIG
    rid = generate_request_id()
    parts = [
        f"<Command>{params.get('command', '001')}</Command>",
        f"<Mti>{params.get('mti', 100)}</Mti>",
        f"<TerminalId>{cfg['terminalId']}</TerminalId>",
        f"<TermNo>{cfg['termNo']}</TermNo>",
        f"<TimeoutInSeconds>{params.get('timeout', 90)}</TimeoutInSeconds>",
        f"<Amount>{params['amount']}</Amount>",
        f"<Currency>{params.get('currency', 376)}</Currency>",
        f"<CreditTerms>{params.get('creditTerms', 1)}</CreditTerms>",
        f"<TranType>{params.get('tranType', 1)}</TranType>",
        f"<PanEntryMode>{params.get('panEntryMode', 'PinPad')}</PanEntryMode>",
    ]
    if params.get("noPayments"):
        parts.append(f"<NoPayments>{params['noPayments']}</NoPayments>")
    if params.get("firstPayment"):
        parts.append(f"<FirstPayment>{params['firstPayment']}</FirstPayment>")
    if params.get("fixedPayment"):
        parts.append(f"<FixedPayment>{params['fixedPayment']}</FixedPayment>")
    if params.get("originalUid"):
        parts.append(f"<OriginalUid>{params['originalUid']}</OriginalUid>")
    if params.get("originalAuthNum"):
        parts.append(f"<OriginalAuthNum>{params['originalAuthNum']}</OriginalAuthNum>")
    if params.get("originalTranDate"):
        parts.append(f"<OriginalTranDate>{params['originalTranDate']}</OriginalTranDate>")
    if params.get("originalTranTime"):
        parts.append(f"<OriginalTranTime>{params['originalTranTime']}</OriginalTranTime>")
    if params.get("parameterJ"):
        parts.append(f"<ParameterJ>{params['parameterJ']}</ParameterJ>")
    parts.append(f"<Xfield>{rid}</Xfield>")
    parts.append(f"<RequestId>{rid}</RequestId>")
    return f"<Request>{''.join(parts)}</Request>"


def build_simple_xml(command, extra_fields=None):
    cfg = TERMINAL_CONFIG
    rid = generate_request_id()
    parts = [
        f"<Command>{command}</Command>",
        f"<TerminalId>{cfg['terminalId']}</TerminalId>",
        f"<TermNo>{cfg['termNo']}</TermNo>",
    ]
    if extra_fields:
        for k, v in extra_fields.items():
            parts.append(f"<{k}>{v}</{k}>")
    parts.append(f"<RequestId>{rid}</RequestId>")
    return f"<Request>{''.join(parts)}</Request>"


@app.route("/")
def index():
    return send_file(os.path.join(os.path.dirname(__file__), "caspit_ui.html"))


@app.route("/api/config", methods=["GET"])
def get_config():
    return jsonify(TERMINAL_CONFIG)


@app.route("/api/config", methods=["POST"])
def update_config():
    data = request.json
    for key in ("ip", "port", "terminalId", "termNo", "timeout"):
        if key in data:
            TERMINAL_CONFIG[key] = data[key]
    return jsonify(TERMINAL_CONFIG)


@app.route("/api/test", methods=["POST"])
def communication_test():
    xml = build_simple_xml("003")
    result = send_to_terminal(xml)
    return jsonify({"request": xml, "response": result})


@app.route("/api/transaction", methods=["POST"])
def do_transaction():
    params = request.json
    xml = build_transaction_xml(params)
    result = send_to_terminal(xml)
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "type": _get_tran_desc(params),
        "amount": params.get("amount", 0),
        "request": params,
        "response": result,
    }
    transaction_log.append(log_entry)
    return jsonify({"request": xml, "response": result, "log": log_entry})


@app.route("/api/void", methods=["POST"])
def do_void():
    params = request.json
    params["mti"] = 400
    params["tranType"] = params.get("tranType", 1)
    xml = build_transaction_xml(params)
    result = send_to_terminal(xml)
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "type": "ביטול",
        "amount": params.get("amount", 0),
        "request": params,
        "response": result,
    }
    transaction_log.append(log_entry)
    return jsonify({"request": xml, "response": result, "log": log_entry})


@app.route("/api/report/<report_type>", methods=["POST"])
def get_report(report_type):
    command_map = {"jenr": "002", "total": "005", "tran": "007", "data": "008", "statis": "014", "deposit": "015"}
    cmd = command_map.get(report_type)
    if not cmd:
        return jsonify({"error": f"Unknown report: {report_type}"}), 400
    extra = {}
    if report_type == "statis":
        extra["CurrentRecord"] = request.json.get("currentRecord", 0)
    xml = build_simple_xml(cmd, extra)
    result = send_to_terminal(xml)
    return jsonify({"request": xml, "response": result})


@app.route("/api/transmit", methods=["POST"])
def transmit_to_shva():
    xml = build_simple_xml("006")
    result = send_to_terminal(xml)
    return jsonify({"request": xml, "response": result})


@app.route("/api/query", methods=["POST"])
def query_transaction():
    uid = request.json.get("uid", "")
    xml = build_simple_xml("012", {"Uid": uid})
    result = send_to_terminal(xml)
    return jsonify({"request": xml, "response": result})


@app.route("/api/swipe", methods=["POST"])
def swipe_card():
    xml = build_simple_xml("023")
    result = send_to_terminal(xml)
    return jsonify({"request": xml, "response": result})


@app.route("/api/log", methods=["GET"])
def get_log():
    return jsonify(transaction_log)


@app.route("/api/log", methods=["DELETE"])
def clear_log():
    transaction_log.clear()
    return jsonify({"status": "cleared"})


def _get_tran_desc(params):
    tt = params.get("tranType", 1)
    ct = params.get("creditTerms", 1)
    desc = TRAN_TYPES.get(tt, "עסקה")
    if ct != 1:
        desc += f" ({CREDIT_TERMS.get(ct, ct)})"
    return desc


if __name__ == "__main__":
    print(f"\n{'='*50}")
    print(f"  Caspit Terminal Control Panel")
    print(f"  Terminal: {TERMINAL_CONFIG['ip']}:{TERMINAL_CONFIG['port']}")
    print(f"  ID: {TERMINAL_CONFIG['terminalId']}-{TERMINAL_CONFIG['termNo']}")
    print(f"{'='*50}")
    print(f"  Open: http://localhost:5555")
    print(f"{'='*50}\n")
    app.run(host="0.0.0.0", port=5555, debug=True)
