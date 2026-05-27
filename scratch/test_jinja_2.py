from flask import Flask, render_template_string

app = Flask(__name__)

@app.route('/')
def index():
    days_left = 30
    template = """
        {% if days_left <= 7 %}
        Renew Now
        {% else %}
        Manage Subscription
        {% endif %}
    """
    return render_template_string(template, days_left=days_left)

if __name__ == '__main__':
    with app.app_context():
        print(index())
