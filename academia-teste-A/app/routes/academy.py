from flask import Blueprint, flash, redirect, render_template, url_for
from flask_login import login_required

from app import db
from app.forms import AcademyProfileForm
from app.models import AcademyProfile

bp = Blueprint("academy", __name__, url_prefix="/perfil-academia")


def _get_profile():
    # Nesta versão o sistema ainda trabalha com uma única academia por instalação.
    profile = db.session.get(AcademyProfile, 1)
    if profile is None:
        profile = AcademyProfile(id=1, name="Minha academia")
        db.session.add(profile)
        db.session.commit()
    return profile


@bp.route("/", methods=["GET", "POST"])
@login_required
def profile():
    academy = _get_profile()
    form = AcademyProfileForm(obj=academy)
    if form.validate_on_submit():
        for field_name in (
            "name", "legal_name", "cnpj", "phone", "email", "website",
            "instagram", "zip_code", "street", "number", "complement",
            "neighborhood", "city",
        ):
            value = getattr(form, field_name).data
            setattr(academy, field_name, value.strip() if value else None)
        academy.state = form.state.data.strip().upper() if form.state.data else None
        db.session.commit()
        flash("Perfil da academia atualizado com sucesso.", "success")
        return redirect(url_for("academy.profile"))
    return render_template("academy/profile.html", form=form, academy=academy)
