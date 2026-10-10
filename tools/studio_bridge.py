#!/usr/bin/env python3
"""
PONT STUDIO - Tide Rush
Parle a StudioMCP en JSON-RPC over stdio.

Usage:
  python3 tools/studio_bridge.py list                 -> liste les outils Studio
  python3 tools/studio_bridge.py call <tool> '<json>' -> appelle un outil
  python3 tools/studio_bridge.py exec '<code lua>'    -> raccourci run_code
"""
import json
import subprocess
import sys
import threading
import queue

STUDIO_MCP = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 0

    cmd = sys.argv[1]

    proc = subprocess.Popen(
        [STUDIO_MCP],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
    )

    responses = queue.Queue()
    next_id = [1]

    def reader():
        for line in proc.stdout:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except json.JSONDecodeError:
                continue
            if "id" in msg:
                responses.put(msg)

    def stderr_reader():
        for line in proc.stderr:
            sys.stderr.write("[studiomcp] " + line)

    threading.Thread(target=reader, daemon=True).start()
    threading.Thread(target=stderr_reader, daemon=True).start()

    def request(method, params):
        rid = next_id[0]
        next_id[0] += 1
        proc.stdin.write(json.dumps({"jsonrpc": "2.0", "id": rid, "method": method, "params": params}) + "\n")
        proc.stdin.flush()
        try:
            msg = responses.get(timeout=40)
        except queue.Empty:
            raise RuntimeError("timeout 40s sur " + method)
        if "error" in msg:
            raise RuntimeError(json.dumps(msg["error"]))
        return msg.get("result")

    try:
        request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "tide-rush-bridge", "version": "1.0.0"},
        })
        proc.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")
        proc.stdin.flush()

        if cmd == "list":
            result = request("tools/list", {})
            print(json.dumps(result, indent=2, ensure_ascii=False))

        elif cmd == "call":
            if len(sys.argv) < 3:
                print("usage: call <tool> [json_args]")
                return 1
            tool = sys.argv[2]
            args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
            result = request("tools/call", {"name": tool, "arguments": args})
            print(json.dumps(result, indent=2, ensure_ascii=False))

        elif cmd == "exec":
            if len(sys.argv) < 3:
                print("usage: exec '<code lua>'")
                return 1
            code = sys.argv[2]
            result = request("tools/call", {"name": "run_code", "arguments": {"code": code}})
            print(json.dumps(result, indent=2, ensure_ascii=False))

        else:
            print("commande inconnue:", cmd)
            return 1

    except Exception as e:
        sys.stderr.write("ERREUR: %s\n" % e)
        return 1
    finally:
        try:
            proc.kill()
        except Exception:
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
