from flask import Flask, request, jsonify
from flask_cors import CORS
from google.cloud import firestore
from models.post import Post
from datetime import datetime
import os
import smtplib
from email.message import EmailMessage
import re
from dotenv import load_dotenv

load_dotenv()
app = Flask(__name__)

# ✅ Allow requests from localhost and deployed frontend
CORS(app, resources={r"/*": {"origins": [
    "http://localhost:50633",
    "https://crystalloids-candidates.ew.r.appspot.com"
]}}, supports_credentials=True)

db = firestore.Client()

# Email configuration
SMTP_SERVER = os.getenv("SMTP_SERVER")
SMTP_PORT = int(os.getenv("SMTP_PORT", 587))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SENDER_EMAIL = os.getenv("SENDER_EMAIL")

def is_valid_email(email):
    return email and re.match(r"[^@]+@[^@]+\.[^@]+", email)

def send_email(to, subject, text):
    print(f"[EMAIL DEBUG] Attempting to send email to: {to}")
    if not is_valid_email(to):
        print("[EMAIL DEBUG] Invalid email address. Skipping send.")
        return

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = SENDER_EMAIL
    msg["To"] = to
    msg.set_content(text)

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as smtp:
            smtp.starttls()
            smtp.login(SMTP_USER, SMTP_PASSWORD)
            smtp.send_message(msg)
            print(f"[EMAIL DEBUG] Email successfully sent to: {to}")
    except Exception as e:
        print(f"[EMAIL DEBUG] Failed to send email: {e}")

@app.route('/posts', methods=['POST'])
def create_post():
    data = request.json
    author = data.get('author')
    subject = data.get('subject')
    body = data.get('body')

    if not all([author, subject, body]):
        return jsonify({'error': 'Missing fields'}), 400

    post = Post(author, subject, body)
    post_ref = db.collection('posts').document()
    post_ref.set(post.to_dict())

    send_email(
        to=author,
        subject="New Post Created",
        text=f"Hi {author},\n\nYour post titled '{subject}' was successfully created."
    )

    return jsonify({'message': 'Post created', 'id': post_ref.id}), 201

@app.route('/posts', methods=['GET'])
def get_posts():
    posts_stream = db.collection('posts').stream()
    posts = []

    for post in posts_stream:
        post_data = post.to_dict()
        post_data['id'] = post.id
        comments_ref = db.collection('posts').document(post.id).collection('comments').stream()
        post_data['comments'] = [comment.to_dict() for comment in comments_ref]
        posts.append(post_data)

    return jsonify(posts), 200

@app.route('/posts/<post_id>', methods=['PUT'])
def update_post(post_id):
    data = request.json
    subject = data.get('subject')
    body = data.get('body')
    post_ref = db.collection('posts').document(post_id)
    updates = {'updated_at': datetime.utcnow().isoformat()}

    if subject:
        updates['subject'] = subject
    if body:
        updates['body'] = body

    post_ref.update(updates)
    return jsonify({'message': 'Post updated', 'id': post_id}), 200

@app.route('/posts/<post_id>/comments', methods=['POST'])
def add_comment(post_id):
    data = request.json
    author = data.get('author')
    body = data.get('body')

    if not all([author, body]):
        return jsonify({'error': 'Missing fields'}), 400

    comment = {
        'author': author,
        'body': body,
        'created_at': datetime.utcnow().isoformat()
    }

    db.collection('posts').document(post_id).collection('comments').add(comment)

    post = db.collection('posts').document(post_id).get()
    if post.exists:
        post_data = post.to_dict()
        post_author = post_data.get("author")
        post_subject = post_data.get("subject", "your post")

        if post_author:
            send_email(
                to=post_author,
                subject="New Comment on Your Post",
                text=f"{author} commented on your post '{post_subject}':\n\n{body}"
            )
        else:
            print("[EMAIL DEBUG] No author email found on the original post.")

    return jsonify({'message': 'Comment added'}), 201

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8080, debug=True)
