from flask_wtf import FlaskForm
from wtforms import (
    BooleanField,
    DateField,
    DecimalField,
    IntegerField,
    PasswordField,
    SelectField,
    StringField,
    TextAreaField,
)
from wtforms.validators import DataRequired, Email, Length, NumberRange, Optional, Regexp


class LoginForm(FlaskForm):
    username = StringField("Usuário", validators=[DataRequired(), Length(max=80)])
    password = PasswordField("Senha", validators=[DataRequired()])


class StudentForm(FlaskForm):
    name = StringField("Nome", validators=[DataRequired(), Length(max=120)])
    document = StringField("CPF", validators=[DataRequired(), Length(max=20)])
    phone = StringField("Telefone", validators=[Optional(), Length(max=30)])
    email = StringField("E-mail", validators=[Optional(), Email(), Length(max=120)])
    birth_date = DateField("Data de nascimento", validators=[Optional()])
    status = SelectField(
        "Status",
        choices=[("ativo", "Ativo"), ("inativo", "Inativo")],
        default="ativo",
    )

    is_instructor = BooleanField("É instrutor/professor da academia")


class PlanForm(FlaskForm):
    name = StringField("Nome do plano", validators=[DataRequired(), Length(max=80)])
    duration_days = IntegerField(
        "Duração (dias)", validators=[DataRequired(), NumberRange(min=1, max=3650)]
    )
    price = DecimalField("Valor (R$)", validators=[DataRequired(), NumberRange(min=0)])
    active = SelectField(
        "Disponível",
        choices=[("1", "Sim"), ("0", "Não")],
        default="1",
    )
    billing_cycle = SelectField(
        "Ciclo de cobrança",
        choices=[
            ("mensal", "Mensal"),
            ("trimestral", "Trimestral"),
            ("semestral", "Semestral"),
            ("anual", "Anual"),
            ("unico", "Pagamento único"),
        ],
        default="mensal",
    )
    grace_days = IntegerField(
        "Dias de tolerância após o vencimento",
        validators=[DataRequired(), NumberRange(min=0, max=30)],
        default=3,
    )


class EnrollmentForm(FlaskForm):
    student_id = SelectField("Aluno", coerce=int, validators=[DataRequired()])
    plan_id = SelectField("Plano", coerce=int, validators=[DataRequired()])
    start_date = DateField("Início", validators=[DataRequired()])


class PaymentForm(FlaskForm):
    enrollment_id = SelectField("Matrícula", coerce=int, validators=[DataRequired()])
    amount = DecimalField("Valor (R$)", validators=[DataRequired(), NumberRange(min=0)])
    paid_at = DateField("Data do pagamento", validators=[Optional()])
    due_date = DateField("Vencimento", validators=[Optional()])
    method = SelectField(
        "Forma",
        choices=[("pix", "Pix"), ("dinheiro", "Dinheiro"), ("cartao", "Cartão")],
        default="pix",
    )
    status = SelectField(
        "Status",
        choices=[("pago", "Pago"), ("pendente", "Pendente")],
        default="pago",
    )
    notes = TextAreaField("Observação", validators=[Optional(), Length(max=255)])


class AcademyProfileForm(FlaskForm):
    name = StringField("Nome fantasia", validators=[DataRequired(), Length(max=120)])
    legal_name = StringField("Razão social", validators=[Optional(), Length(max=160)])
    cnpj = StringField(
        "CNPJ",
        validators=[Optional(), Regexp(r"^\d{14}$", message="Informe o CNPJ com 14 números, sem letras ou símbolos.")],
    )
    phone = StringField(
        "Telefone",
        validators=[Optional(), Regexp(r"^\d{10,11}$", message="Informe o telefone com DDD e 10 ou 11 números, sem letras ou símbolos.")],
    )
    email = StringField("E-mail", validators=[Optional(), Email(), Length(max=120)])
    website = StringField("Site", validators=[Optional(), Length(max=180)])
    instagram = StringField("Instagram", validators=[Optional(), Length(max=100)])
    zip_code = StringField(
        "CEP",
        validators=[Optional(), Regexp(r"^\d{8}$", message="Informe o CEP com 8 números, sem letras ou símbolos.")],
    )
    street = StringField("Rua / Avenida", validators=[Optional(), Length(max=160)])
    number = StringField("Número", validators=[Optional(), Length(max=20)])
    complement = StringField("Complemento", validators=[Optional(), Length(max=100)])
    neighborhood = StringField("Bairro", validators=[Optional(), Length(max=100)])
    city = StringField("Cidade", validators=[Optional(), Length(max=100)])
    state = StringField("UF", validators=[Optional(), Length(min=2, max=2)])
