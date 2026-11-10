"""Cria snapshot consistente de um banco SQLite usando sqlite3.Connection.backup."""
import os
import sqlite3
import sys

def main():
    if len(sys.argv) != 3:
        print("Uso: backup_sqlite.py <banco_origem> <banco_destino>", file=sys.stderr)
        return 2
    source_path, destination_path = sys.argv[1], sys.argv[2]
    if not os.path.isfile(source_path):
        print("Banco de origem não encontrado.", file=sys.stderr)
        return 3
    os.makedirs(os.path.dirname(os.path.abspath(destination_path)), exist_ok=True)
    if os.path.exists(destination_path):
        os.remove(destination_path)
    try:
        with sqlite3.connect(source_path, timeout=30) as source:
            with sqlite3.connect(destination_path, timeout=30) as destination:
                source.backup(destination)
                result = destination.execute("PRAGMA integrity_check").fetchone()
                if not result or result[0] != "ok":
                    raise RuntimeError(f"integrity_check falhou: {result}")
        print("Snapshot SQLite criado; integrity_check: ok.")
        return 0
    except Exception as exc:
        if os.path.exists(destination_path):
            os.remove(destination_path)
        print(f"Falha no backup SQLite: {exc}", file=sys.stderr)
        return 4

if __name__ == "__main__":
    raise SystemExit(main())
