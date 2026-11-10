"""Identificação local e persistente de cada instalação do FITGESTAO."""
import json
import os
import uuid
from datetime import datetime, timezone


def get_installation_info(instance_path: str) -> dict:
    """Lê ou cria um identificador exclusivo dentro da pasta instance/.

    O arquivo não deve ser distribuído no pacote do projeto-base: cada
    instalação deve gerar seu próprio identificador na primeira execução.
    """
    os.makedirs(instance_path, exist_ok=True)
    info_path = os.path.join(instance_path, "installation.json")

    if os.path.exists(info_path):
        try:
            with open(info_path, "r", encoding="utf-8") as file:
                info = json.load(file)
            if info.get("installation_id"):
                return info
        except (OSError, json.JSONDecodeError):
            # Arquivo inválido: recria a identificação local.
            pass

    info = {
        "installation_id": str(uuid.uuid4()),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    temporary_path = info_path + ".tmp"
    with open(temporary_path, "w", encoding="utf-8") as file:
        json.dump(info, file, ensure_ascii=False, indent=2)
    os.replace(temporary_path, info_path)
    return info
