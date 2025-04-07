from datetime import datetime

class Post:
    def __init__(self, author, subject, body, created_at=None):
        self.author = author
        self.subject = subject
        self.body = body
        self.created_at = created_at if created_at else datetime.utcnow()

    def to_dict(self):
        return {
            'author': self.author,
            'subject': self.subject,
            'body': self.body,
            'created_at': self.created_at.isoformat()
        }
