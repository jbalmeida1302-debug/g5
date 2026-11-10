from flask import Blueprint, current_app, render_template
from flask_login import login_required

from app.installation import get_installation_info
from app.version import APP_NAME, APP_VERSION, RELEASE_CHANNEL

bp = Blueprint("system", __name__, url_prefix="/sistema")


@bp.route("/versao")
@login_required
def version():
    installation = get_installation_info(current_app.instance_path)
    return render_template(
        "system/version.html",
        app_name=APP_NAME,
        app_version=APP_VERSION,
        release_channel=RELEASE_CHANNEL,
        installation=installation,
    )
