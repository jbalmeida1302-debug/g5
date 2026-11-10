"""Compacta uma pasta incluindo arquivos ocultos, como .env, preservando caminhos relativos."""
import os
import sys
import zipfile

def main():
    if len(sys.argv) != 3:
        print("Uso: zip_backup.py <pasta_origem> <arquivo_zip>", file=sys.stderr)
        return 2
    source_dir, zip_path = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    if not os.path.isdir(source_dir):
        print("Pasta de origem não encontrada.", file=sys.stderr)
        return 3
    try:
        with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for current, dirs, files in os.walk(source_dir):
                dirs[:] = [d for d in dirs if d not in {"__pycache__", ".venv", "venv", "backups"}]
                for filename in files:
                    full_path = os.path.join(current, filename)
                    relative = os.path.relpath(full_path, source_dir)
                    archive.write(full_path, relative)
        with zipfile.ZipFile(zip_path, "r") as archive:
            bad = archive.testzip()
            if bad:
                raise RuntimeError(f"Arquivo corrompido dentro do ZIP: {bad}")
        print("Arquivo ZIP criado e validado.")
        return 0
    except Exception as exc:
        if os.path.exists(zip_path):
            os.remove(zip_path)
        print(f"Falha ao compactar backup: {exc}", file=sys.stderr)
        return 4

if __name__ == "__main__":
    raise SystemExit(main())
